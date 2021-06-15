// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.4;

interface IERC20Ratable {
    function ratableTotalSupply(string calldata currencyCode) external view returns (uint256);

    function ratableBalanceOf(address owner, string calldata currencyCode) external view returns (uint256);

    function ratableTransfer(
        address recipient,
        uint256 amount,
        string calldata currencyCode
    ) external returns (bool);

    function ratableAllowance(
        address owner,
        address spender,
        string calldata currencyCode
    ) external view returns (uint256);

    function ratableApprove(
        address spender,
        uint256 amount,
        string calldata currencyCode
    ) external returns (bool);

    function ratableTransferFrom(
        address sender,
        address recipient,
        uint256 amount,
        string calldata currencyCode
    ) external returns (bool);

    function ratableIncreaseAllowance(
        address spender,
        uint256 addedValue,
        string calldata currencyCode
    ) external returns (bool);

    function ratableDecreaseAllowance(
        address spender,
        uint256 subtractedValue,
        string calldata currencyCode
    ) external returns (bool);
}
