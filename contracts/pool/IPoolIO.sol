// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IPoolIO {
    function setDivestmentTimestamp(uint64 timestamp) external;

    function deposit(uint256 amount, bool isCallPool) external payable;

    function withdraw(uint256 amount, bool isCallPool) external;

    function reassign(uint256 tokenId, uint256 contractSize)
        external
        returns (
            uint256 baseCost,
            uint256 feeCost,
            uint256 amountOut
        );

    function reassignBatch(
        uint256[] calldata tokenIds,
        uint256[] calldata contractSizes
    )
        external
        returns (
            uint256[] memory baseCosts,
            uint256[] memory feeCosts,
            uint256 amountOutCall,
            uint256 amountOutPut
        );

    function withdrawAllAndReassignBatch(
        bool isCallPool,
        uint256[] calldata tokenIds,
        uint256[] calldata contractSizes
    )
        external
        returns (
            uint256[] memory baseCosts,
            uint256[] memory feeCosts,
            uint256 amountOutCall,
            uint256 amountOutPut
        );

    function withdrawFees()
        external
        returns (uint256 amountOutCall, uint256 amountOutPut);

    function annihilate(uint256 tokenId, uint256 contractSize) external;
}