// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

interface IEscrowToken {
    enum EscrowStatus {Pending, Completed, Terminated, Refunded}

    struct EscrowDetail {
        address creater;
        address recipient;
        uint256 createrTokenId;
        uint256 recipientTokenId;
        uint256 currencyValue;
        uint256 value;
        string currencyCode;
        uint16 hedgeRate;
        EscrowStatus status;
        bool canRefund;
        uint256 terminatedTime;
    }

    function createEscrow(
        address to,
        uint256 currencyValue,
        bool canRefund,
        uint256 terminatedTime,
        string calldata currencyCode,
        uint16 hedgeRate
    ) external;

    function buyerSettlement(uint256 escrowId) external;

    function sellerSettlement(uint256 escrowId) external;

    function buyerRefund(uint256 escrowId) external;

    function estimateEscrowSettlement(uint256 escrowId)
        external
        view
        returns (
            uint256 recipientAmount,
            uint256 recipientSubAmount,
            uint256 recipientCreativeReward,
            uint256 recipientIncentive,
            uint256 createrAmount,
            uint256 createrSubAmount,
            uint256 createrCreativeReward,
            uint256 createrIncentive
        );

    function createBuyerEscrowNFT(uint256 escrowId) external;

    function createSellerEscrowNFT(uint256 escrowId) external;

    function getEscrowDetail(uint256 escrowId) external view returns (EscrowDetail memory);
}
