// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import '@solidstate/contracts/contracts/access/OwnableInternal.sol';
import '@solidstate/contracts/contracts/token/ERC20/ERC20.sol';
import '@solidstate/contracts/contracts/token/ERC20/ERC20MetadataStorage.sol';
import '@solidstate/contracts/contracts/token/ERC20/IERC20.sol';
import '@solidstate/contracts/contracts/token/ERC1155/ERC1155Base.sol';

import './PoolStorage.sol';

/**
 * @title Openhedge option pool
 * @dev deployed standalone and referenced by PoolProxy
 */
contract Pool is OwnableInternal, ERC20, ERC1155Base {
  /**
   * @notice get price of option contract
   * @param amount size of option contract
   * @param strikePrice option strike price
   * @param maturity timestamp of option maturity
   * @return price of option contract
   */
  function quote (
    uint amount,
    uint strikePrice,
    uint maturity
  ) public view returns (uint) {
    // TODO: calculate
  }

  /**
   * @notice initialize proxy storage
   * @param base asset used as unit of account
   * @param underlying asset optioned
   */
  function initialize (
    address base,
    address underlying
  ) external onlyOwner {
    {
      PoolStorage.Layout storage l = PoolStorage.layout();
      l.base = base;
      l.underlying = underlying;
    }

    {
      ERC20MetadataStorage.Layout storage l = ERC20MetadataStorage.layout();

      string memory symbolUnderlying = ERC20(underlying).symbol();
      string memory symbolBase = ERC20(base).symbol();

      l.name = string(abi.encodePacked(
        'Median Liquidity: ',
        symbolUnderlying,
        '/',
        symbolBase
      ));

      l.symbol = string(abi.encodePacked(
        'MED-',
        symbolUnderlying,
        symbolBase
      ));

      l.decimals = 18;
    }
  }

  /**
   * @notice deposit underlying currency, underwriting calls of that currency with respect to base currency
   * @param amount quantity of underlying currency to deposit
   */
  function deposit (
    uint amount
  ) external {
    // TODO: convert ETH to WETH if applicable
    // TODO: set lockup period
    // TODO: calculate C value

    IERC20(
      PoolStorage.layout().underlying
    ).transferFrom(msg.sender, address(this), amount);

    // TODO: calculate amount minted
    uint minted;

    _mint(msg.sender, minted);
  }

  /**
   * @notice redeem pool share tokens for underlying asset
   * @param amount quantity of share tokens to redeem
   */
  function withdraw (
    uint amount
  ) external {
    // TODO: check lockup period
    // TODO: ensure available liquidity, queue if necessary

    _burn(msg.sender, amount);

    // TODO: calculate share of pool
    uint share;

    IERC20(
      PoolStorage.layout().underlying
    ).transfer(msg.sender, share);
  }

  /**
   * @notice purchase call option
   * @param amount size of option contract
   * @param strikePrice option strike price
   * @param maturity timestamp of option maturity
   */
  function purchase (
    uint amount,
    uint strikePrice,
    uint maturity
  ) external {
    // TODO: convert ETH to WETH if applicable

    IERC20(
      PoolStorage.layout().underlying
    ).transferFrom(
      msg.sender,
      address(this),
      quote(amount, strikePrice, maturity)
    );

    _mint(msg.sender, _tokenIdFor(strikePrice, maturity), amount, '');
  }

  /**
   * @notice exercise call option
   * @param amount quantity of option contract tokens to exercise
   * @param strikePrice option strike price
   * @param maturity timestamp of option maturity
   */
  function exercise (
    uint amount,
    uint strikePrice,
    uint maturity
  ) external {
    exercise(_tokenIdFor(strikePrice, maturity), amount);
  }

  /**
   * @notice exercise call option
   * @param id ERC1155 token id
   * @param amount quantity of option contract tokens to exercise
   */
  function exercise (
    uint id,
    uint amount
  ) public {
    _burn(msg.sender, id, amount);

    // TODO: send payment
  }

  /**
   * @notice calculate ERC1155 token id for given option parameters
   * @param strikePrice option strike price
   * @param maturity timestamp of option maturity
   * @return token id
   */
  function _tokenIdFor (
    uint strikePrice,
    uint maturity
  ) private pure returns (uint) {
    // TODO: calculate token id
  }
}
