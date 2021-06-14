// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../interface/IERC20Ratable.sol';
import '../interface/IEarthaTokenRate.sol';

abstract contract ERC20Ratable is ERC20, IERC20Ratable, AccessControl {
    bytes32 public constant RATE_SETTER_ROLE = keccak256('RATE_SETTER_ROLE');

    IEarthaTokenRate public tokenRate;

    constructor() AccessControl() {
        _setupRole(RATE_SETTER_ROLE, _msgSender());
    }

    modifier rateSetterOnly() {
        require(hasRole(RATE_SETTER_ROLE, _msgSender()), 'EarthaTokenRate: must have rate setter role to set role');
        _;
    }

    function setRate(IEarthaTokenRate rate) external virtual rateSetterOnly() {
        tokenRate = rate;
    }

    function ratableTotalSupply(string calldata currencyCode) external view virtual override returns (uint256) {
        uint256 totalSupplyValue = totalSupply();
        return _getToX(totalSupplyValue, currencyCode);
    }

    function ratableBalanceOf(address owner, string calldata currencyCode)
        external
        view
        virtual
        override
        returns (uint256)
    {
        uint256 balance = balanceOf(owner);
        return _getToX(balance, currencyCode);
    }

    function ratableTransfer(
        address recipient,
        uint256 amount,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedAmount = _getXTo(amount, currencyCode);
        return transfer(recipient, ratedAmount);
    }

    function ratableAllowance(
        address owner,
        address spender,
        string calldata currencyCode
    ) external view virtual override returns (uint256) {
        uint256 allowanceValue = allowance(owner, spender);
        return _getToX(allowanceValue, currencyCode);
    }

    function ratableApprove(
        address spender,
        uint256 amount,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedAmount = _getXTo(amount, currencyCode);
        return approve(spender, ratedAmount);
    }

    function ratableTransferFrom(
        address sender,
        address recipient,
        uint256 amount,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedAmount = _getXTo(amount, currencyCode);
        return transferFrom(sender, recipient, ratedAmount);
    }

    function ratableIncreaseAllowance(
        address spender,
        uint256 addedValue,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedAddedValue = _getXTo(addedValue, currencyCode);
        return increaseAllowance(spender, ratedAddedValue);
    }

    function ratableDecreaseAllowance(
        address spender,
        uint256 subtractedValue,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedSubtractedValue = _getXTo(subtractedValue, currencyCode);
        return decreaseAllowance(spender, ratedSubtractedValue);
    }

    function _getXTo(uint256 amount, string calldata currencyCode) internal view virtual returns (uint256) {
        return tokenRate.getXTo(amount, currencyCode);
    }

    function _getToX(uint256 amount, string calldata currencyCode) internal view virtual returns (uint256) {
        return tokenRate.getToX(amount, currencyCode);
    }
}
