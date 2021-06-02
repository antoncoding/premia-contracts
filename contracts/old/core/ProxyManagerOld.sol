// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@solidstate/contracts/access/OwnableInternal.sol';

import './IProxyManagerOld.sol';
import './ProxyManagerOldStorage.sol';

import '../market/MarketProxy.sol';
import '../option/OptionProxy.sol';

/**
 * @title Options pair management contract
 * @dev deployed standalone and connected to Median as diamond facet
 */
contract ProxyManagerOld is IProxyManagerOld, OwnableInternal {
  using ProxyManagerOldStorage for ProxyManagerOldStorage.Layout;

  function getOptionImplementation() override external view returns (address) {
    return ProxyManagerOldStorage.layout().optionImplementation;
  }

  function getMarketImplementation() override external view returns (address) {
    return ProxyManagerOldStorage.layout().marketImplementation;
  }

  function deployMarket(address _feeCalculator, address _feeRecipient) external onlyOwner returns(address) {
    address market = address(new MarketProxy(msg.sender, _feeCalculator, _feeRecipient));
    ProxyManagerOldStorage.layout().market = market;
    return market;
  }

  function deployOption(string memory _uri, address _denominator, address _feeCalculator, address _feeRecipient) external onlyOwner returns(address) {
    address option = address(new OptionProxy(msg.sender, _uri, _denominator, _feeCalculator, _feeRecipient));
    ProxyManagerOldStorage.layout().options[_denominator] = option;
    return option;
  }

  function getMarket() external view returns(address) {
    return ProxyManagerOldStorage.layout().market;
  }

  function getOption(address _denominator) external view returns(address) {
    return ProxyManagerOldStorage.layout().options[_denominator];
  }
}
