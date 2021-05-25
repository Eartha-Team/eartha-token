// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './extensions/ERC20Ratable.sol';
import './interface/IEarthaTokenRate.sol';
import './interface/IEscrowToken.sol';
import './interface/IEarthaToken.sol';
import './interface/IEscrowNFT.sol';

contract EarthaToken is ERC20, AccessControl, ERC20Ratable, IEarthaToken {
    using Counters for Counters.Counter;

    bytes32 public constant CREATIVE_REWARDS_WITHDRAWER_ROLE = keccak256('CREATIVE_REWARDS_WITHDRAWER_ROLE');

    uint256 public constant ESCROW_MAX_INCENTIVE = 300000000000 ether;
    uint256 public constant ESCROW_AMOUNT_INCENTIVE_USD = 10 ether;
    uint256 public constant ESCROW_CREATIVE_REWARD_USD = 1 ether;
    uint256 public constant ESCROW_MIN_AMOUNT = 400 ether;

    IEscrowNFT public immutable escrowNFT;
    uint256 private immutable _cap;

    mapping(uint256 => EscrowDetail) private _escrowDetail;
    Counters.Counter private _escrowIdTracker = Counters.Counter(1);

    uint256 public suppliedIncentives;
    uint256 public unpaidCreativeRewards;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 cap_,
        IEscrowNFT escrowNFT_
    ) AccessControl() ERC20(name_, symbol_) {
        require(cap_ > 0, 'EarthaToken: cap is 0');
        _cap = cap_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATIVE_REWARDS_WITHDRAWER_ROLE, _msgSender());

        ERC20._mint(_msgSender(), cap_ - ESCROW_MAX_INCENTIVE);
        ERC20._mint(address(this), ESCROW_MAX_INCENTIVE);
        escrowNFT = escrowNFT_;
    }

    modifier withdrawerOnly() {
        require(
            hasRole(CREATIVE_REWARDS_WITHDRAWER_ROLE, _msgSender()),
            'EarthaToken: must have withdrawer role to withdrawCreativeRewards'
        );
        _;
    }

    function createEscrow(
        address to,
        uint256 currencyValue,
        bool canRefund,
        uint256 terminatedTime,
        uint256 canRefundTime,
        string calldata currencyCode,
        uint16 hedgeRate
    ) external virtual override {
        uint256 amount = tokenRate.getXToWithHedgeRate(currencyValue, currencyCode, hedgeRate);
        require(amount > ESCROW_MIN_AMOUNT, 'Minimum is 400 EAR');
        _transfer(_msgSender(), address(this), amount);
        EscrowDetail memory ed =
            EscrowDetail({
                creater: _msgSender(),
                recipient: to,
                createrTokenId: 0,
                recipientTokenId: 0,
                value: amount,
                currencyValue: currencyValue,
                status: EscrowStatus.Pending,
                currencyCode: currencyCode,
                hedgeRate: hedgeRate,
                canRefund: canRefund,
                terminatedTime: terminatedTime,
                canRefundTime: canRefundTime
            });
        uint256 escrowId = _escrowIdTracker.current();
        _escrowDetail[escrowId] = ed;
        _escrowIdTracker.increment();

        emit CreateNewEscrow(escrowId, ed.creater, ed.recipient);
    }

    function buyerSettlement(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        address createrAddress = ed.createrTokenId != 0 ? escrowNFT.ownerOf(ed.createrTokenId) : ed.creater;
        address recipientAddress = ed.recipientTokenId != 0 ? escrowNFT.ownerOf(ed.recipientTokenId) : ed.recipient;
        require(createrAddress == _msgSender(), 'EarthaToken: not creater');
        require(ed.status == EscrowStatus.Pending, 'EarthaToken: EscrowStatus is not Pending');

        ed.status = EscrowStatus.Completed;
        EscrowSettlementAmounts memory esa = _payOffEscrow(recipientAddress, createrAddress, ed);

        emit BuyerSettlement(escrowId, ed.creater, ed.recipient, esa);
    }

    function sellerSettlement(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        address createrAddress = ed.createrTokenId != 0 ? escrowNFT.ownerOf(ed.createrTokenId) : ed.creater;
        address recipientAddress = ed.recipientTokenId != 0 ? escrowNFT.ownerOf(ed.recipientTokenId) : ed.recipient;
        require(recipientAddress == _msgSender(), 'EarthaToken: not recepient');
        require(ed.status == EscrowStatus.Pending, 'EarthaToken: EscrowStatus is not Pending');
        require(ed.terminatedTime < block.timestamp, 'EarthaToken: terminatedTime error');

        ed.status = EscrowStatus.Terminated;
        EscrowSettlementAmounts memory esa = _payOffEscrow(recipientAddress, createrAddress, ed);

        emit SellerSettlement(escrowId, ed.creater, ed.recipient, esa);
    }

    function buyerRefund(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        address createrAddress = ed.createrTokenId != 0 ? escrowNFT.ownerOf(ed.createrTokenId) : ed.creater;
        address recipientAddress = ed.recipientTokenId != 0 ? escrowNFT.ownerOf(ed.recipientTokenId) : ed.recipient;
        require(createrAddress == _msgSender() || recipientAddress == _msgSender(), 'EarthaToken: not user');
        require(ed.status == EscrowStatus.Pending, 'EarthaToken: EscrowStatus is not Pending');
        require(ed.canRefund, 'EarthaToken: can not refund');
        require(ed.canRefundTime >= block.timestamp, 'EarthaToken: canRefundTime error');

        ed.status = EscrowStatus.Terminated;
        _transfer(address(this), ed.creater, ed.value);

        emit BuyerRefund(escrowId, ed.creater, ed.recipient);
    }

    function estimateEscrowSettlement(uint256 escrowId)
        external
        view
        virtual
        override
        returns (EscrowSettlementAmounts memory)
    {
        EscrowDetail memory ed = _escrowDetail[escrowId];
        EscrowSettlementAmounts memory esa;

        uint256 ratedAmount = tokenRate.getXTo(ed.currencyValue, ed.currencyCode);
        esa.recipientSubAmount = ratedAmount > ed.value ? ed.value : ratedAmount;
        esa.createrSubAmount = ed.value - esa.recipientSubAmount;
        if (esa.recipientSubAmount > 0) {
            (esa.recipientAmount, esa.recipientCreativeReward, esa.recipientIncentive) = _estimate(
                esa.recipientSubAmount
            );
        }
        if (esa.createrSubAmount > 0) {
            (esa.createrAmount, esa.createrCreativeReward, esa.createrIncentive) = _estimate(esa.createrSubAmount);
        }

        return (esa);
    }

    function createBuyerEscrowNFT(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        require(ed.creater == _msgSender(), 'EarthaToken: not creater');
        require(ed.status == EscrowStatus.Pending, 'EarthaToken: EscrowStatus is not Pending');
        require(ed.createrTokenId == 0, 'EarthaToken: Already exists');
        uint256 tokenId = escrowNFT.mint(ed.creater, escrowId);
        ed.createrTokenId = tokenId;
        emit CreateBuyerEscrowNFT(escrowId, tokenId, ed.creater);
    }

    function createSellerEscrowNFT(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        require(ed.recipient == _msgSender(), 'EarthaToken: not recipient');
        require(ed.status == EscrowStatus.Pending, 'EarthaToken: EscrowStatus is not Pending');
        require(ed.recipientTokenId == 0, 'EarthaToken: Already exists');
        if (ed.canRefund) {
            require(ed.canRefundTime < block.timestamp, 'EarthaToken: canRefundTime error');
        }
        uint256 tokenId = escrowNFT.mint(ed.recipient, escrowId);
        ed.recipientTokenId = tokenId;
        emit CreateSellerEscrowNFT(escrowId, tokenId, ed.recipient);
    }

    function getEscrowDetail(uint256 escrowId) external view virtual override returns (EscrowDetail memory) {
        return _escrowDetail[escrowId];
    }

    function withdrawCreativeRewards(address recipient) external virtual override withdrawerOnly() {
        require(unpaidCreativeRewards > 0, 'EarthaToken: unpaidCreativeRewards is 0');
        _transfer(address(this), recipient, unpaidCreativeRewards);
    }

    function cap() public view virtual override returns (uint256) {
        return _cap;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Ratable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _estimate(uint256 amount)
        internal
        view
        virtual
        returns (
            uint256 actualAmount,
            uint256 creativeReward,
            uint256 incentive
        )
    {
        uint256 incentiveRated = tokenRate.getXTo(ESCROW_AMOUNT_INCENTIVE_USD, 'USD');
        if (ESCROW_MAX_INCENTIVE >= (suppliedIncentives + incentiveRated)) {
            incentive = incentiveRated;
            amount += incentive;
        }
        uint256 creativeRewardRated = tokenRate.getXTo(ESCROW_CREATIVE_REWARD_USD, 'USD');
        creativeReward = amount > creativeRewardRated ? creativeRewardRated : amount;
        amount -= creativeReward;
        return (amount, creativeReward, incentive);
    }

    function _payOffEscrow(
        address recipientAddress,
        address createrAddress,
        EscrowDetail memory ed
    ) internal virtual returns (EscrowSettlementAmounts memory) {
        EscrowSettlementAmounts memory esa;

        uint256 ratedAmount = tokenRate.getXTo(ed.currencyValue, ed.currencyCode);
        esa.recipientSubAmount = ratedAmount > ed.value ? ed.value : ratedAmount;
        esa.createrSubAmount = ed.value - esa.recipientSubAmount;

        if (esa.recipientSubAmount > 0) {
            (esa.recipientAmount, esa.recipientCreativeReward, esa.recipientIncentive) = _estimate(
                esa.recipientSubAmount
            );
            suppliedIncentives += esa.recipientIncentive;
            unpaidCreativeRewards += esa.recipientCreativeReward;
            if (esa.recipientAmount > 0) {
                _transfer(address(this), recipientAddress, esa.recipientAmount);
            }
        }
        if (esa.createrSubAmount > 0) {
            (esa.createrAmount, esa.createrCreativeReward, esa.createrIncentive) = _estimate(esa.createrSubAmount);
            suppliedIncentives += esa.createrIncentive;
            unpaidCreativeRewards += esa.createrCreativeReward;
            if (esa.createrAmount > 0) {
                _transfer(address(this), createrAddress, esa.createrAmount);
            }
        }
        return esa;
    }
}
