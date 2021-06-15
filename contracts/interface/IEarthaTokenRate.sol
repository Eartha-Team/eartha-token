// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.4;

import './ITokenRate.sol';
import '@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol';

interface IEarthaTokenRate is ITokenRate {
    event UpdatedSource(string currencyCode, AggregatorV3Interface source);

    function getXToWithHedgeRate(
        uint256 amount,
        string calldata currencyCode,
        uint16 hedgeRate
    ) external view returns (uint256);

    function setSource(string calldata currencyCode, AggregatorV3Interface source) external returns (bool);

    function setUSDSource(AggregatorV3Interface source) external returns (bool);
}
