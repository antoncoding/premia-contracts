// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ABDKMath64x64} from "../libraries/ABDKMath64x64.sol";

library OptionMath {
    using ABDKMath64x64 for int128;

    /**
     * @notice calculates the log return for a given day
     * @param _today todays close
     * @param _yesterday yesterdays close
     * @return log of returns
     * ln( today / yesterday)
     */
    function logreturns(int256 _today, int256 _yesterday)
        internal
        pure
        returns (int256)
    {
        int128 today64x64 = ABDKMath64x64.fromInt(_today);
        int128 yesterday64x64 = ABDKMath64x64.fromInt(_yesterday);
        return ABDKMath64x64.toInt(today64x64.div(yesterday64x64).ln());
    }

    /**
     * @notice calculates the log return for a given day
     * @param _old the price from yesterday
     * @param _current today's price
     * @param _window the period for the EMA average
     * @return the new EMA value for today
     * alpha * (current - old ) + old
     */
    function rollingEma(
        int256 _old,
        int256 _current,
        int256 _window
    ) internal pure returns (int256) {
        int128 alpha64x64 =
            ABDKMath64x64.divi(ABDKMath64x64.fromInt(2), 1 + _window);
        int128 current64x64 = ABDKMath64x64.fromInt(_current);
        int128 old64x64 = ABDKMath64x64.fromInt(_old);
        return
            ABDKMath64x64.toInt(
                alpha64x64.mul(current64x64.sub(old64x64)).add(old64x64)
            );
    }

    /**
     * @notice calculates the log return for a given day
     * @param _today the price from today
     * @param _yesterdayema the average from yesterday
     * @param _yesterdayemavariance the variation from yesterday
     * @param _window the period for the average
     * @return the new variance value for today
     * (1 - a)(EMAVar t-1  +  a( x t - EMA t-1)^2)
     */
    function rollingEmaVar(
        int256 _today,
        int256 _yesterdayema,
        int256 _yesterdayemavariance,
        int256 _window
    ) internal pure returns (int256) {
        int128 alpha64x64 =
            ABDKMath64x64.divi(ABDKMath64x64.fromInt(2), 1 + _window);
        int128 yesterdayemavariance64x64 =
            ABDKMath64x64.fromInt(_yesterdayemavariance);
        int128 yesterdayema = ABDKMath64x64.fromInt(_yesterdayema);
        int128 today64x64 = ABDKMath64x64.fromInt(_today);
        return
            ABDKMath64x64.ONE_64x64.sub(alpha64x64).mul(
                yesterdayemavariance64x64.add(
                    alpha64x64.mul(today64x64.sub(yesterdayema)).pow(2)
                )
            );
    }

    /**
     * @notice calculates an internal probability for bscholes model
     * @param _variance the price from yesterday
     * @param _strike the price from today
     * @param _price the average from yesterday
     * @param _maturity the average from today
     * @return the probability
     */
    function p(
        uint256 _variance,
        uint256 _strike,
        uint256 _price,
        int128 _maturity
    ) internal pure returns (uint256) {
        return
            uint256(
                ABDKMath64x64.toUInt(
                    ABDKMath64x64.divu(_strike, _price).ln().add(
                        _maturity
                            .mul(
                            // TODO: more efficient? => ABDKMath64x64.fromUInt(_variance / 2)
                            ABDKMath64x64.divu(_variance, 2)
                        )
                            .div(
                            ABDKMath64x64
                                .fromUInt(_maturity.mulu(_variance))
                                .sqrt()
                        )
                    )
                )
            );
    }

    /**
     * @notice calculates the black scholes price
     * @param _variance the price from yesterday
     * @param _strike the price from today
     * @param _price the average from yesterday
     * @param _duration temporal length of option contract
     * @param _isCall is this a call option
     * @return the price of the option
     */
    function bsPrice(
        uint256 _variance,
        uint256 _strike,
        uint256 _price,
        uint256 _duration,
        bool _isCall
    ) internal pure returns (uint256) {
        int128 maturity = ABDKMath64x64.divu(_duration, (365 days));
        uint256 prob = p(_variance, _strike, _price, maturity);
        return (_price - _strike * maturity.exp().toUInt()) * prob;
    }

    /**
     * @notice slippage function
     * @param oldC previous C-Level
     * @param oldLiquidity liquidity in pool before udpate
     * @param newLiquidity liquidity in pool after update
     * @param alpha steepness coefficient
     * @return new C-Level
     */
    function calculateCLevel(
        int128 oldC,
        uint256 oldLiquidity,
        uint256 newLiquidity,
        int128 alpha
    ) internal pure returns (int128) {
        int128 oldLiquidity64x64 = ABDKMath64x64.fromUInt(oldLiquidity);
        int128 newLiquidity64x64 = ABDKMath64x64.fromUInt(newLiquidity);
        return
            oldLiquidity64x64.sub(newLiquidity64x64).div(
                oldLiquidity64x64 > newLiquidity64x64
                    ? oldLiquidity64x64
                    : newLiquidity64x64
            )
            .mul(alpha).exp().mul(oldC);
    }

    /**
     * @notice calculates the black scholes price
     * @param _variance the price from yesterday
     * @param _strike the price from today
     * @param _price the average from yesterday
     * @param _duration temporal length of option contract
     * @param _Ct previous C-Level
     * @param _St current state of the pool
     * @param _St1 state of the pool after trade
     * @return the price of the option
     */
    function pT(
        uint256 _variance,
        uint256 _strike,
        uint256 _price,
        uint256 _duration,
        int128 _Ct,
        uint256 _St,
        uint256 _St1
    ) internal pure returns (uint256) {
        return
            calculateCLevel(_Ct, _St, _St1, ABDKMath64x64.ONE_64x64).mulu(
                bsPrice(_variance, _strike, _price, _duration, true)
            );
    }

    /**
     * @notice calculates the approximated blackscholes model
     * @param _price the price today
     * @param _variance the variance from today
     * @param _duration temporal length of option contract
     * @param _Ct previous C-Level
     * @param _St current state of the pool
     * @param _St1 state of the pool after trade
     * @return an approximation for the price of a BS option
     * approximated bsch price * C-Level
     */
    function approx_pT(
        int256 _price,
        int256 _variance,
        uint256 _duration,
        int128 _Ct,
        uint256 _St,
        uint256 _St1
    ) internal pure returns (uint256) {
        int128 maturity = ABDKMath64x64.divu(_duration, (365 days));
        int128 bsch = approx_Bsch(_price, _variance, _duration);
        int128 cLevel = calculateCLevel(_Ct, _St, _St1, ABDKMath64x64.ONE_64x64);
        return ABDKMath64x64.toUInt(bsch.mul(cLevel));
    }

    /**
     * @notice calculates the approximated blackscholes model
     * @param _price the price today
     * @param _variance the variance from today
     * @param _duration temporal length of option contract
     * @return an approximation for the price of a BS option
     * sqrt(maturity) * 0.4 * price * variance (in our case EMA variance)
     */
    function approx_Bsch(
        int256 _price,
        int256 _variance,
        uint256 _duration
    ) internal pure returns (int128) {
        int128 duration64x64 = ABDKMath64x64.fromUInt(_duration);
        int128 maturity64x64 = duration64x64.divi(365 days);
        int128 factor = ABDKMath64x64.fromInt(4).divi(10);
        int128 variance = ABDKMath64x64.fromInt(_variance);
        int128 price = ABDKMath64x64.fromInt(_price);
        return maturity64x64.sqrt().mul(factor).mul(price).mul(variance);
    }
}
