// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


/****************************************************************************************************************************************
 * @title WAHT based Voting Power System:                                                                                                 *
 *                                                                                                                                      *
 * @dev This contract is designed to calculate the voting power of token holders based on both the amount of tokens they hold           *
 *      and the duration for which they have held those tokens. This is achieved through the concept of a "Weighted Average Holding     *
 *      Time" (WAHT), which allows a dynamic calculation of voting power that increases not only with a user’s token balance,           *
 *      but also with how long they’ve held those tokens.                                                                               *
 *                                                                                                                                      *
 *      The core functionality of this contract is to track a user's token balance over time and accumulate a "weighted holding time,"  *
 *      which reflects how long the tokens have been held. The longer tokens are held, the greater the accumulated holding time,        *
 *      which increases the user's voting power. The key feature of the contract is the packing of balance and timestamp data into      *
 *      a single storage slot to optimize gas consumption, making this suitable for gas-conscious applications like decentralized       *
 *      governance systems.                                                                                                             *
 *                                                                                                                                      *
 ***************************************************************************************************************************************/

contract VotingPower {
    // Struct to store packed data and holding time
    struct HoldingData {
        uint256 packedData;  // Packed balance (128 bits) and last update time (64 bits)
        uint256 totalHoldingTime;  // Accumulated weighted holding time
    }

    // Mapping from addresses to their respective holding data
    mapping(address => HoldingData) public holdings; 
    

    /**
     * @dev Updates the weighted average holding time (WAHT) for a given account.
     * This function should be called after every balance update (transfer, mint, burn).
     * @param account Address of the user whose balance is updated.
     * @param newBalance New balance of the account.
     */
    function updateWAHT(address account, uint256 newBalance) external {
        // Load the holding data once and unpack the balance + lastUpdate from packedData
        HoldingData storage holding = holdings[account];
        uint256 packedData = holding.packedData;

        // Extract balance and timestamp
        uint128 balance = uint128(packedData >> 64);  // Upper 128 bits store balance
        uint64 lastUpdate = uint64(packedData);       // Last 64 bits store timestamp
        uint64 currentTimestamp = uint64(block.timestamp);

        // If balance is non-zero and time has passed, update totalHoldingTime
        if (balance > 0 && lastUpdate < currentTimestamp) {
            unchecked {
                uint256 timeElapsed = currentTimestamp - lastUpdate;
                holding.totalHoldingTime += timeElapsed * balance;  // Update weighted holding time
            }
        }

        // Only update if the new balance is different from the current one
        if (newBalance != balance) {
            if (newBalance == 0) {
                holding.packedData = 0;  // If the new balance is zero, reset packed data
            } else {
                // If the old balance is non-zero, scale totalHoldingTime accordingly
                if (balance > 0) {
                    unchecked {
                        holding.totalHoldingTime = (holding.totalHoldingTime * newBalance) / balance;
                    }
                }
                // Update packed data with new balance and current timestamp
                holding.packedData = (uint256(uint128(newBalance)) << 64) | currentTimestamp;
            }
        }
    }




    /**
     * @dev View function to calculate the current voting power of an account.
     * Voting power is based on the current balance and the weighted average holding time (WAHT).
     * This is a view function, meaning it does not change the contract state.
     * @param account The address of the user.
     * @return The voting power of the account.
     */
    function getVotingPower(address account) external view returns (uint256) {
        HoldingData storage holding = holdings[account];
        uint256 packedData = holding.packedData;

        // Unpack balance and last update timestamp
        uint64 lastUpdate = uint64(packedData);
        uint128 balance = uint128(packedData >> 64);

        if (balance == 0) {
            return 0;
        }

        // Calculate the time elapsed since the last update
        uint64 currentTimestamp = uint64(block.timestamp);
        uint256 timeElapsed = (currentTimestamp > lastUpdate) ? (currentTimestamp - lastUpdate) : 0;

        // Accumulate any new holding time since the last update
        uint256 totalHoldingTime = holding.totalHoldingTime + (timeElapsed * balance);

        // Normalize voting power to prevent excessively large numbers
        uint256 votingPower = totalHoldingTime / 1e18;  // Adjust this constant based on token decimals or desired scaling
        return votingPower;
    }

}