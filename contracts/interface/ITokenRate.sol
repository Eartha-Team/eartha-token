// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

interface ITokenRate {
    function getToX(uint256 amount, string calldata currencyCode) external view returns (uint256);

    function getXTo(uint256 amount, string calldata currencyCode) external view returns (uint256);
}
