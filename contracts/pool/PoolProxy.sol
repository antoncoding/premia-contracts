// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import '@solidstate/contracts/contracts/access/OwnableStorage.sol';

import '../pair/PoolManager.sol';

/**
 * @title Upgradeable proxy with centrally controlled Pool implementation
 * @dev uses Ownable storage location
 */
contract PoolProxy {
  constructor () {
    OwnableStorage.layout().owner = msg.sender;
  }

  fallback () virtual external payable {
    address implementation = PoolManager(
      OwnableStorage.layout().owner
    ).getPoolImplementation();

    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())

      switch result
        case 0 { revert(0, returndatasize()) }
        default { return(0, returndatasize()) }
    }
  }
}
