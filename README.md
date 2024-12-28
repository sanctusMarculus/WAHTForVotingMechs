# WAHT-Based Voting Power System

## Description

This smart contract implements a **Voting Power System** based on the concept of **Weighted Average Holding Time (WAHT)**. The system dynamically calculates a user’s voting power using:
- **Token Balance (B):** The number of tokens held by the user.
- **Holding Duration (T):** The length of time for which those tokens have been held.

By combining these factors, the system achieves a more equitable voting power distribution. The design is highly gas-optimized through the use of packed storage for balance and timestamp data, reducing operational complexity and costs. Unlike traditional snapshot-based mechanisms, WAHT eliminates the need for redundant state storage by dynamically calculating voting power in real time, ensuring instantaneous updates with minimal computational overhead.

---

## Usage

### Features
- **Dynamic Voting Power Calculation:** Merges balance and holding duration to dynamically compute voting power in real time.
- **Gas Optimization:** Implements advanced bit-level operations to compress storage usage and minimize on-chain operations.
- **View-Only Voting Power Query:** Provides state-independent computations for user queries.
- **Snapshot-Free Mechanism:** Foregoes reliance on snapshot data, mitigating historical storage bloat.
- **Seamless Integration:** Designed for easy incorporation into governance and DAO systems.

### Core Concept

The WAHT system increments a user’s holding time based on the formula:

\[
T_{total} = T_{previous} + (B \times \Delta t)
\]

Where:
- \(T_{total}\) = Total accumulated holding time.
- \(B\) = Token balance at the last update.
- \(\Delta t\) = Time elapsed since the last update.

This mechanism ensures that voting power grows proportionally to both balance and time, rewarding long-term token holders.

### Gas Optimization Techniques

#### 1. **Packed Storage for Data Compression**
The system leverages a single 256-bit storage slot to store two key variables:
- **128 bits:** Token balance.
- **64 bits:** Last update timestamp.

This reduces the cost of storage reads/writes by consolidating data into a single storage access operation, avoiding additional SLOAD or SSTORE calls.

#### 2. **Unchecked Arithmetic Operations**
By employing Solidity’s `unchecked` keyword, the contract minimizes redundant gas-consuming overflow checks in scenarios where bounds are inherently controlled.

#### 3. **Batch Logical Operations**
Bit-shifting and masking techniques are utilized to pack/unpack data efficiently:
```solidity
uint128 balance = uint128(packedData >> 64);
uint64 lastUpdate = uint64(packedData);
```
These operations avoid the need for explicit storage segmentation, enabling efficient in-memory manipulations.

#### 4. **Selective State Updates**
State is updated only when necessary—e.g., during balance changes. This ensures that no unnecessary writes occur, thereby conserving gas:
```solidity
if (newBalance != balance) {
    holding.packedData = (uint256(uint128(newBalance)) << 64) | currentTimestamp;
}
```

---

## Functions

### `updateWAHT`
```solidity
function updateWAHT(address account, uint256 newBalance) external
```
**Purpose:** Updates the Weighted Average Holding Time (WAHT) for a user whenever their balance changes.
- **Parameters:**
  - `account`: Address of the user whose WAHT is being updated.
  - `newBalance`: The updated token balance for the user.
- **Logic:**
  - Calculates \(\Delta t\) (time elapsed since the last update).
  - Updates the user’s \(T_{total}\) based on their balance and \(\Delta t\).
  - Packs the updated balance and timestamp back into the storage slot.

### `getVotingPower`
```solidity
function getVotingPower(address account) external view returns (uint256)
```
**Purpose:** Computes the real-time voting power for a user.
- **Parameters:**
  - `account`: Address of the user whose voting power is being queried.
- **Returns:**
  - Voting power derived from \(T_{total}\).
- **Logic:**
  - Extracts balance and timestamp from packed data.
  - Calculates accrued holding time since the last update.
  - Normalizes \(T_{total}\) to compute voting power.

---

## Example Integration with ERC-20

The WAHT mechanism is designed for direct integration into ERC-20 tokens. Below is an implementation that demonstrates its integration within the `_transfer` function.

### Example ERC-20 Token: `exampleERC20Token`
```solidity
contract exampleERC20Token is IERC20 {
    VotingPower public votingPowerContract;

    constructor(address votingPowerAddress) {
        votingPowerContract = VotingPower(votingPowerAddress);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        // Update WAHT balances in VotingPower contract
        votingPowerContract.updateWAHT(sender, _balances[sender]);
        votingPowerContract.updateWAHT(recipient, _balances[recipient]);

        emit Transfer(sender, recipient, amount);
    }
}
```

### Key Integration Details
- **Real-Time WAHT Updates:** Automatically updates both sender and recipient balances within the VotingPower contract during each transfer.
- **Efficient Data Handling:** Leverages the gas-optimized packed storage format of VotingPower.
- **Dynamic Voting Power Calculation:** Ensures accurate, real-time voting power adjustments without historical dependencies.
- **Snapshot-Free Mechanism:** Bypasses the inefficiencies of snapshot-based governance models, relying instead on real-time recalculations.

---

## Deployment and Usage

### Prerequisites
- **Solidity Compiler:** Version `0.8.20` or higher.
- **Ethereum Network:** Compatible with any EVM-based blockchain.

### Steps to Deploy
1. Clone the repository.
2. Compile the contracts using Hardhat, Truffle, or Remix.
3. Deploy the `VotingPower` contract.
4. Deploy your ERC-20 contract with the `VotingPower` contract address.

### Example Interaction
#### Update WAHT
```solidity
votingPower.updateWAHT(userAddress, newBalance);
```
- **Example:**
  ```solidity
  votingPower.updateWAHT(0x123...abc, 500);
  ```

#### Get Voting Power
```solidity
uint256 power = votingPower.getVotingPower(userAddress);
```
- **Example:**
  ```solidity
  uint256 power = votingPower.getVotingPower(0x123...abc);
  ```

---

## Advanced Gas Optimization Notes

- **Single Slot Design:** By consolidating balance and timestamp into a single storage slot, the contract reduces SLOAD and SSTORE operations, saving approximately 5,000 gas per state interaction compared to dual-slot designs.
- **Lazy Updates:** Voting power is computed lazily during view operations, minimizing on-chain computations during state-modifying calls.
- **Arithmetic Compression:** Operations on balances and timestamps utilize bitwise operations to reduce computational overhead, achieving theoretical gas efficiency bounds.

---

## Use Cases
- **DAOs:** Implements fair voting power allocation based on token holding behavior.
- **Incentive Systems:** Encourages long-term holding through time-weighted rewards.
- **Governance Systems:** Provides equitable and dynamic voting systems, removing the dependency on static snapshots.

---

## License
This project is licensed under the [MIT License](./LICENSE).

---

## Acknowledgments
- Developed with a focus on reducing gas costs and enabling fair governance mechanisms.
- Inspired by advanced tokenomics and governance models in DeFi.

---

