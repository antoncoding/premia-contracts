// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {EnumerableSet} from "@solidstate/contracts/utils/EnumerableSet.sol";

library VolatilitySurfaceOracleStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.storage.VolatilitySurfaceOracle");

    struct Update {
        uint256 updatedAt;
        bytes32 coefficients;
    }

    struct Layout {
        // Base token -> Underlying token -> Update
        mapping(address => mapping(address => Update)) volatilitySurfaces;
        // Relayer addresses which can be trusted to provide accurate option trades
        EnumerableSet.AddressSet whitelistedRelayers;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function parseVolatilitySurfaceCoefficients(bytes32 input)
        internal
        pure
        returns (int256[] memory coefficients)
    {
        coefficients = new int256[](6);

        // Value to add to negative numbers to cast them to int256
        int256 toAdd = (int256(-1) >> 42) << 42;

        assembly {
            let i := 0
            // Value equal to -1
            let mid := shl(41, 1)

            for {

            } lt(i, 6) {

            } {
                let offset := sub(210, mul(42, i))
                let coeff := shr(
                    offset,
                    sub(
                        input,
                        shl(add(offset, 42), shr(add(offset, 42), input))
                    )
                )

                // Check if value is a negative number and needs casting
                if or(eq(coeff, mid), gt(coeff, mid)) {
                    coeff := add(coeff, toAdd)
                }

                // Store result in the coefficients array
                mstore(add(coefficients, add(0x20, mul(0x20, i))), coeff)

                i := add(i, 1)
            }
        }
    }

    function formatVolatilitySurfaceCoefficients(int256[6] memory coefficients)
        internal
        pure
        returns (bytes32 result)
    {
        for (uint256 i = 0; i < 6; i++) {
            int256 max = 1 << 41;
            require(
                coefficients[i] < max && coefficients[i] > -max,
                "Out of bounds"
            );
        }

        assembly {
            let i := 0

            for {

            } lt(i, 6) {

            } {
                let offset := sub(210, mul(42, i))
                let coeff := mload(add(coefficients, mul(0x20, i)))

                result := add(
                    result,
                    shl(offset, sub(coeff, shl(42, shr(42, coeff))))
                )

                i := add(i, 1)
            }
        }
    }
}
