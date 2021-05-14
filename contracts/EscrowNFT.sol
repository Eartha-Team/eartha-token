// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './interface/IEscrowNFT.sol';

contract EscrowNFT is AccessControl, ERC721Burnable, IEscrowNFT {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

    mapping(uint256 => uint256) public toEscrowId;
    Counters.Counter private _tokenIdTracker = Counters.Counter(1);

    constructor(string memory name_, string memory symbol_) AccessControl() ERC721(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    modifier minterOnly() {
        require(hasRole(MINTER_ROLE, _msgSender()), 'EscrowNFT: must have minter role to mint');
        _;
    }

    function mint(address to, uint256 escrowId) external virtual override minterOnly() minterOnly() returns (uint256) {
        uint256 tokenId = _tokenIdTracker.current();
        _mint(to, tokenId);
        _tokenIdTracker.increment();
        toEscrowId[tokenId] = escrowId;
        return tokenId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 /*_tokenId*/
    ) public view virtual override(ERC721) returns (string memory) {
        return 'ipfs://QmPGm6XXPbEg7B5aV3dvA279jpM6cr6yk3hfaEr4C9dQPB';
    }
}
