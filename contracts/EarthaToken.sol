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
    uint256 public constant ESCROW_AMOUNT_INCENTIVE = 1000 ether;
    uint256 public constant ESCROW_CREATIVE_REWARD = 100 ether;
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
        string calldata currencyCode,
        uint16 hedgeRate
    ) external virtual override {
        IEarthaTokenRate rate = IEarthaTokenRate(tokenRate);
        uint256 amount = rate.getXToWithHedgeRate(currencyValue, currencyCode, hedgeRate);
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
                terminatedTime: terminatedTime
            });
        uint256 escrowId = _escrowIdTracker.current();
        _escrowDetail[escrowId] = ed;
        _escrowIdTracker.increment();

        emit CreateNewEscrow(escrowId, ed.creater, ed.recipient);
    }

    function completeEscrow(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        address createrAddress = ed.createrTokenId != 0 ? escrowNFT.ownerOf(ed.createrTokenId) : ed.creater;
        address recipientAddress = ed.recipientTokenId != 0 ? escrowNFT.ownerOf(ed.recipientTokenId) : ed.recipient;
        require(createrAddress == _msgSender(), 'EarthaToken: not creater');
        require(ed.status == EscrowStatus.Pending, 'EarthaToken: EscrowStatus is not Pending');

        ed.status = EscrowStatus.Completed;
        _payOffEscrow(recipientAddress, createrAddress, ed);

        emit CompleteEscrow(escrowId, ed.creater, ed.recipient);
    }

    function terminateEscrow(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        address createrAddress = ed.createrTokenId != 0 ? escrowNFT.ownerOf(ed.createrTokenId) : ed.creater;
        address recipientAddress = ed.recipientTokenId != 0 ? escrowNFT.ownerOf(ed.recipientTokenId) : ed.recipient;
        require(recipientAddress == _msgSender(), 'EarthaToken: not recepient');
        require(ed.status == EscrowStatus.Pending, 'EarthaToken: EscrowStatus is not Pending');
        require(ed.terminatedTime < block.timestamp, 'EarthaToken: terminatedTime error');

        ed.status = EscrowStatus.Terminated;
        _payOffEscrow(recipientAddress, createrAddress, ed);

        emit TerminateEscrow(escrowId, ed.creater, ed.recipient);
    }

    function refundEscrow(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        address createrAddress = ed.createrTokenId != 0 ? escrowNFT.ownerOf(ed.createrTokenId) : ed.creater;
        address recipientAddress = ed.recipientTokenId != 0 ? escrowNFT.ownerOf(ed.recipientTokenId) : ed.recipient;
        require(createrAddress == _msgSender() || recipientAddress == _msgSender(), 'EarthaToken: not user');
        require(ed.status == EscrowStatus.Pending, 'EarthaToken: EscrowStatus is not Pending');
        require(ed.canRefund, 'EarthaToken: can not refund');

        ed.status = EscrowStatus.Terminated;
        _transfer(address(this), ed.creater, ed.value);

        emit RefundEscrow(escrowId, ed.creater, ed.recipient);
    }

    function estimateEscrowSettlement(uint256 escrowId)
        external
        view
        virtual
        override
        returns (
            uint256 recipientAmount,
            uint256 recipientSubAmount,
            uint256 recipientCreativeReward,
            uint256 recipientIncentive,
            uint256 createrAmount,
            uint256 createrSubAmount,
            uint256 createrCreativeReward,
            uint256 createrIncentive
        )
    {
        EscrowDetail memory ed = _escrowDetail[escrowId];
        IEarthaTokenRate rate = IEarthaTokenRate(tokenRate);

        uint256 ratedAmount = rate.getXTo(ed.currencyValue, ed.currencyCode);
        recipientSubAmount = ratedAmount > ed.value ? ed.value : ratedAmount;
        createrSubAmount = ed.value - recipientSubAmount;
        (recipientAmount, recipientCreativeReward, recipientIncentive) = _estimate(recipientSubAmount);
        (createrAmount, createrCreativeReward, createrIncentive) = _estimate(createrSubAmount);

        return (
            recipientAmount,
            recipientSubAmount,
            recipientCreativeReward,
            recipientIncentive,
            createrAmount,
            createrSubAmount,
            createrCreativeReward,
            createrIncentive
        );
    }

    function createEscrowCreaterNFT(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        require(ed.creater == _msgSender());
        require(ed.status == EscrowStatus.Pending);
        require(ed.createrTokenId == 0);
        uint256 tokenId = escrowNFT.mint(ed.creater, escrowId);
        ed.createrTokenId = tokenId;
        emit CreateNewEscrowCreaterNFT(escrowId, tokenId, ed.creater);
    }

    function createEscrowRecipientNFT(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        require(ed.recipient == _msgSender());
        require(ed.status == EscrowStatus.Pending);
        require(ed.recipientTokenId == 0);
        uint256 tokenId = escrowNFT.mint(ed.recipient, escrowId);
        ed.recipientTokenId = tokenId;
        emit CreateNewEscrowRecipientNFT(escrowId, tokenId, ed.recipient);
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
        if (ESCROW_MAX_INCENTIVE >= (suppliedIncentives + ESCROW_AMOUNT_INCENTIVE)) {
            incentive = ESCROW_AMOUNT_INCENTIVE;
            amount += incentive;
        }
        creativeReward = amount > ESCROW_CREATIVE_REWARD ? ESCROW_CREATIVE_REWARD : amount;
        amount -= creativeReward;
        return (amount, creativeReward, incentive);
    }

    function _payOffEscrow(
        address recipientAddress,
        address createrAddress,
        EscrowDetail memory ed
    ) internal virtual {
        IEarthaTokenRate rate = IEarthaTokenRate(tokenRate);

        uint256 ratedAmount = rate.getXTo(ed.currencyValue, ed.currencyCode);
        uint256 recipientAmount = ratedAmount > ed.value ? ed.value : ratedAmount;
        uint256 createrAmount = ed.value - recipientAmount;

        if (recipientAmount > 0) {
            (uint256 amount, uint256 creativeReward, uint256 incentive) = _estimate(recipientAmount);
            suppliedIncentives += incentive;
            unpaidCreativeRewards += creativeReward;
            if (amount > 0) {
                _transfer(address(this), recipientAddress, amount);
            }
        }
        if (createrAmount > 0) {
            (uint256 amount, uint256 creativeReward, uint256 incentive) = _estimate(createrAmount);
            suppliedIncentives += incentive;
            unpaidCreativeRewards += creativeReward;
            if (amount > 0) {
                _transfer(address(this), createrAddress, amount);
            }
        }
    }
}
