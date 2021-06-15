// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IERC20Ratable.sol';
import './IEscrowToken.sol';

interface IEarthaToken is IERC20, IERC20Ratable, IEscrowToken {
    function withdrawCreativeRewards(address recipient) external;

    function cap() external view returns (uint256);
}
