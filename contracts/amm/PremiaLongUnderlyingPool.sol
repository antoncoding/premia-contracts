// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './PremiaLiquidityPool.sol';
import '../interface/IPremiaOption.sol';
import '../uniswapV2/interfaces/IUniswapV2Router02.sol';

contract PremiaLongUnderlyingPool is PremiaLiquidityPool {
  constructor(address _controller) PremiaLiquidityPool(_controller) {}

  function writeOptionFor(address _receiver, address _optionContract, uint256 _optionId, uint256 _amount, address _premiumToken, uint256 _amountPremium, address _referrer) public override {
    super.writeOptionFor(_receiver, _optionContract, _optionId, _amount, _premiumToken, _amountPremium, _referrer);
    
    IPremiaOption optionContract = IPremiaOption(_optionContract);
    IPremiaOption.OptionData memory data = optionContract.optionData(_optionId);
    PremiaLiquidityPool loanPool = _getLoanPool(data, optionContract, _amount);

    address tokenToBorrow = optionContract.denominator();
    uint256 amountToBorrow = _getAmountToBorrow(_amount, data.token, tokenToBorrow);

    Loan memory loan = loanPool.borrow(tokenToBorrow, amountToBorrow, data.token, _amount, data.expiration);
    _swapTokensIn(tokenToBorrow, data.token, amountToBorrow);

    // TODO: We need to store the loan, so we can re-use the details later for unwinding
  }

  function unwindOptionFor(address _sender, address _optionContract, uint256 _optionId, uint256 _amount) public override {
    super.unwindOptionFor(_sender, _optionContract, _optionId, _amount);
  }

  function unlockCollateralFromOption(address _optionContract, uint256 _optionId, uint256 _amount) public override {
    super.unlockCollateralFromOption(_optionContract, _optionId, _amount);
  }

  function _postLiquidate(Loan memory loan, uint256 _collateralAmount) internal override {}

  function _postWithdrawal(address _optionContract, uint256 _optionId, uint256 _amount, uint256 _tokenWithdrawn, uint256 _denominatorWithdrawn)
    internal override {
    Loan memory loan; // TODO <--- We need to figure out how to get the same loan used to write this option

    IPremiaOption optionContract = IPremiaOption(_optionContract);
    IPremiaOption.OptionData memory data = optionContract.optionData(_optionId);
    PremiaLiquidityPool loanPool = PremiaLiquidityPool(loan.lender);

    address tokenBorrowed = optionContract.denominator();
    uint256 amountOut = _swapTokensIn(data.token, tokenBorrowed, _tokenWithdrawn);

    loanPool.repayLoan(loan, amountOut + _denominatorWithdrawn);
  }
}