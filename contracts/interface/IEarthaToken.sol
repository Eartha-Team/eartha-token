// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IERC20Ratable.sol';
import './IEscrowToken.sol';

interface IEarthaToken is IERC20, IERC20Ratable, IEscrowToken {
    event CreateNewEscrow(uint256 escrowId, address indexed creater, address indexed recipient);
    event CompleteEscrow(uint256 indexed escrowId, address indexed creater, address indexed recipient);
    event TerminateEscrow(uint256 indexed escrowId, address indexed creater, address indexed recipient);
    event RefundEscrow(uint256 indexed escrowId, address indexed creater, address indexed recipient);
    event CreateNewEscrowCreaterNFT(uint256 indexed escrowId, uint256 tokenId, address tokenCreater);
    event CreateNewEscrowRecipientNFT(uint256 indexed escrowId, uint256 tokenId, address tokenCreater);

    function withdrawCreativeRewards(address recipient) external;

    function cap() external view returns (uint256);
}
