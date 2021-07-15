// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IPool {
    function withdrawFees()
        external
        returns (uint256 amountOutCall, uint256 amountOutPut);
}