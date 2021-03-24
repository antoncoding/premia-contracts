// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './PremiaLiquidityPool.sol';
import '../interface/IPremiaPoolController.sol';
import '../interface/IPremiaOption.sol';

contract PremiaLongUnderlyingPool is PremiaLiquidityPool {
  // token address => queue index => loan hash
  mapping(address => mapping(uint256 => Loan)) loansTaken;
  // token address => index
  mapping(address => uint256) loanQueuesFirst;
  // token address => index
  mapping(address => uint256) loanQueuesLast;

  constructor(IPremiaPoolController _controller, IPriceOracleGetter _priceOracle, ILendingRateOracleGetter _lendingRateOracle)
    PremiaLiquidityPool(_controller, _priceOracle, _lendingRateOracle) {}

  function _enqueueLoan(Loan memory _loan) internal {
      loanQueuesLast[_loan.token] += 1;
      loansTaken[_loan.token][loanQueuesLast[_loan.token]] = _loan;
  }

  function _dequeueLoan(address _token) internal returns (Loan memory) {
      uint256 first = loanQueuesFirst[_token];
      uint256 last = loanQueuesLast[_token];

      require(last >= first);  // non-empty queue

      Loan memory loan = loansTaken[_token][first];

      delete loansTaken[_token][first];

      loanQueuesFirst[_token] += 1;
      
      return loan;
  }

  function writeOptionFor(address _receiver, address _optionContract, uint256 _optionId, uint256 _amount, address _premiumToken, uint256 _amountPremium, address _referrer) public override {
    super.writeOptionFor(_receiver, _optionContract, _optionId, _amount, _premiumToken, _amountPremium, _referrer);
    
    IPremiaOption optionContract = IPremiaOption(_optionContract);
    IPremiaOption.OptionData memory data = optionContract.optionData(_optionId);
    PremiaLiquidityPool loanPool = _getLoanPool(data, optionContract, _amount);

    address tokenToBorrow = optionContract.denominator();
    uint256 amountToBorrow = _getAmountToBorrow(_amount, data.token, tokenToBorrow);

    Loan memory loan = loanPool.borrow(tokenToBorrow, amountToBorrow, data.token, _amount, data.expiration);
    _swapTokensIn(tokenToBorrow, data.token, amountToBorrow);
    _enqueueLoan(loan);
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
    IPremiaOption optionContract = IPremiaOption(_optionContract);
    IPremiaOption.OptionData memory data = optionContract.optionData(_optionId);

    address tokenBorrowed = optionContract.denominator();
    uint256 amountOut = _swapTokensIn(data.token, tokenBorrowed, _tokenWithdrawn);

    uint256 amountLeft = amountOut + _denominatorWithdrawn;
    while (amountLeft > 0) {
      Loan memory loan = _dequeueLoan(tokenBorrowed);
      PremiaLiquidityPool loanPool = PremiaLiquidityPool(loan.lender);

      uint256 amountRepaid = loanPool.repayLoan(loan, amountLeft);

      amountLeft -= amountRepaid;
    }
  }
}