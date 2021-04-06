// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@solidstate/contracts/access/OwnableStorage.sol';
import '@solidstate/contracts/introspection/ERC165Storage.sol';
import '@solidstate/contracts/token/ERC20/ERC20.sol';
import '@solidstate/contracts/token/ERC20/ERC20MetadataStorage.sol';

import '../pool/Pool.sol';

contract PoolMock is Pool {
  using ERC165Storage for ERC165Storage.Layout;

  function tokenIdFor (
    uint64 maturity,
    int128 strikePrice
  ) external pure returns (uint) {
    return _tokenIdFor(maturity, strikePrice);
  }

  function parametersFor (
    uint256 tokenId
  ) external pure returns (uint64, int128) {
    return _parametersFor(tokenId);
  }
}
