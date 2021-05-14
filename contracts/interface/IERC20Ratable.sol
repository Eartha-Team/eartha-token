// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

interface IERC20Ratable {
    function totalSupply(string calldata currencyCode) external view returns (uint256);

    function balanceOf(address owner, string calldata currencyCode) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount,
        string calldata currencyCode
    ) external returns (bool);

    function allowance(
        address owner,
        address spender,
        string calldata currencyCode
    ) external view returns (uint256);

    function approve(
        address spender,
        uint256 amount,
        string calldata currencyCode
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount,
        string calldata currencyCode
    ) external returns (bool);

    function increaseAllowance(
        address spender,
        uint256 addedValue,
        string calldata currencyCode
    ) external returns (bool);

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue,
        string calldata currencyCode
    ) external returns (bool);
}
