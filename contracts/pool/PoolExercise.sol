// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {PoolInternal} from "./PoolInternal.sol";
import {IPoolExercise} from "./IPoolExercise.sol";

/**
 * @title Premia option pool
 * @dev deployed standalone and referenced by PoolProxy
 */
contract PoolExercise is IPoolExercise, PoolInternal {
    constructor(
        address weth,
        address feeReceiver,
        address feeDiscountAddress,
        int128 fee64x64,
        uint256 batchingPeriod
    )
        PoolInternal(
            weth,
            feeReceiver,
            feeDiscountAddress,
            fee64x64,
            batchingPeriod
        )
    {}

    /**
     * @notice exercise call option on behalf of holder
     * @param holder owner of long option tokens to exercise
     * @param longTokenId long option token id
     * @param contractSize quantity of tokens to exercise
     */
    function exerciseFrom(
        address holder,
        uint256 longTokenId,
        uint256 contractSize
    ) external {
        if (msg.sender != holder) {
            require(isApprovedForAll(holder, msg.sender), "not approved");
        }

        _exercise(holder, longTokenId, contractSize);
    }

    /**
     * @notice process expired option, freeing liquidity and distributing profits
     * @param longTokenId long option token id
     * @param contractSize quantity of tokens to process
     */
    function processExpired(uint256 longTokenId, uint256 contractSize)
        external
        override
    {
        _exercise(address(0), longTokenId, contractSize);
    }
}
