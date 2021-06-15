// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.4;

interface ITokenRate {
    function getToX(uint256 amount, string calldata currencyCode) external view returns (uint256);

    function getXTo(uint256 amount, string calldata currencyCode) external view returns (uint256);
}
