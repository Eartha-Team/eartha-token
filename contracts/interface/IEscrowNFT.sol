// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IEscrowNFT is IERC721 {
    function mint(address to, uint256 escrowId) external returns (uint256);
}
