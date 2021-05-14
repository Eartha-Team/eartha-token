// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../interface/IERC20Ratable.sol';
import '../interface/ITokenRate.sol';

abstract contract ERC20Ratable is ERC20, IERC20Ratable {
    address public tokenRate;
    bool public initializedTokenRate = false;

    function initializeTokenRate(address rate) external virtual {
        require(!initializedTokenRate, 'already initialized');
        tokenRate = rate;
        initializedTokenRate = true;
    }

    function totalSupply(string calldata currencyCode) external view virtual override returns (uint256) {
        uint256 totalSupplyValue = totalSupply();
        return _getToX(totalSupplyValue, currencyCode);
    }

    function balanceOf(address owner, string calldata currencyCode) external view virtual override returns (uint256) {
        uint256 balance = balanceOf(owner);
        return _getToX(balance, currencyCode);
    }

    function transfer(
        address recipient,
        uint256 amount,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedAmount = _getXTo(amount, currencyCode);
        return transfer(recipient, ratedAmount);
    }

    function allowance(
        address owner,
        address spender,
        string calldata currencyCode
    ) external view virtual override returns (uint256) {
        uint256 allowanceValue = allowance(owner, spender);
        return _getToX(allowanceValue, currencyCode);
    }

    function approve(
        address spender,
        uint256 amount,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedAmount = _getXTo(amount, currencyCode);
        return approve(spender, ratedAmount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedAmount = _getXTo(amount, currencyCode);
        return transferFrom(sender, recipient, ratedAmount);
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedAddedValue = _getXTo(addedValue, currencyCode);
        return increaseAllowance(spender, ratedAddedValue);
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedSubtractedValue = _getXTo(subtractedValue, currencyCode);
        return decreaseAllowance(spender, ratedSubtractedValue);
    }

    function _getXTo(uint256 amount, string calldata currencyCode) internal view virtual returns (uint256) {
        ITokenRate rate = ITokenRate(tokenRate);
        return rate.getXTo(amount, currencyCode);
    }

    function _getToX(uint256 amount, string calldata currencyCode) internal view virtual returns (uint256) {
        ITokenRate rate = ITokenRate(tokenRate);
        return rate.getToX(amount, currencyCode);
    }
}
