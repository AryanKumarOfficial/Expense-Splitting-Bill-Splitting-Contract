# Expense Splitting / Bill-Splitting Contract

## Project Title
Expense Splitting / Bill-Splitting Contract

## Project Description
This Solidity project implements a smart contract (`ExpenseSplitter`) that allows a predefined group of participants to record shared expenses and settle debts among themselves. Users can record an expense by specifying the total amount, participants involved, and share weights; the contract updates net balances accordingly. Participants can then settle outstanding debts by transferring Ether or ERC20 tokens through the contract.

Additionally, the constructor has been relaxed to allow deployment with a single participant address (mainly for testing or trivial scenarios). With only one participant, recording an expense among yourself is permitted but results in no net debt; however, the core logic remains fully functional when more participants are deployed.

## Project Vision
The vision is to provide a transparent, on-chain mechanism for small groups (friends, roommates, colleagues) to manage and settle shared expenses without relying on centralized apps or spreadsheets. By recording expenses and settlements on a blockchain, the system ensures immutability, transparency, and trust. Future integrations might include UI dashboards, automated reminders, and multi-currency support. Allowing single-participant deployment makes initial testing easier and sets a foundation for later dynamic participant additions.

## Key Features
- **Record Expenses**: Payers can log shared expenses, specifying involved participants and share weights. Net balances auto-update.
- **Supports Ether and ERC20**: Expenses and settlements can be in Ether or any ERC20 token.
- **Settle Debts**: Participants can settle owed amounts by transferring funds via the contract, which updates balances.
- **Net Balance Tracking**: View each participant's net position (positive = owed; negative = owes).
- **Single-Participant Deployment**: Constructor accepts an array of length ≥1, so you can deploy with just one address for testing or trivial use. (With one participant, expense recording yields zero net change.)
- **Events Emitted**: `ExpenseRecorded` and `ExpenseSettled` events for off-chain UI or analytics.
- **Simple Participant Management**: Participants defined at deployment; addresses must be unique and non-zero.

## How to Deploy
1. **Compile** the `ExpenseSplitter` contract in your environment (e.g., Remix, Hardhat).
2. **Constructor Argument**: In the deployment UI, pass a JSON array of at least one address, e.g.:
   - Single participant (for testing): `["0xYourAddressHere"]`
   - Multiple participants: `["0xAddress1", "0xAddress2", ...]`
3. **Deploy**: Confirm the transaction in your wallet. If only one address is provided, the contract will deploy successfully and allow calls; with multiple addresses, full expense-splitting flows apply.
4. **Interact**:
   - Call `getNetBalance(address)` → initial balance is 0.
   - Use `recordExpense(...)` and `settleExpense(...)` with multiple participants to test real splitting. With a single address, you can still call `recordExpense(["yourAddress"], [1], 1)` but net balance remains zero.

## Future Scope
- **Dynamic Participant Management**: Add functions to allow the owner or via consensus to add/remove participants post-deployment (e.g., require existing participant balances be zero before removal).
- **UI Integration**: Develop a frontend (React, Vue, etc.) to interact with the contract, display balances, and simplify expense inputs. Support “equal split” or custom shares in the UI.
- **Automated Reminders**: Integrate with off-chain services (bots, backend) to notify participants of pending debts or upcoming settlements.
- **Advanced Splitting Logic**: Support percentage-based splits, custom rounding rules (e.g., handle remainders), or integrate with price oracles for multi-currency expenses.
- **Group Expense Reports**: Off-chain analytics can generate summaries, charts, monthly reports, and export data (CSV).
- **Security Enhancements**:
  - Refactor to follow checks-effects-interactions (update balances before transfers) or add a reentrancy guard.
  - Formal verification or extended audits for ERC20 edge cases and transfer behaviors.
- **Gas Optimization**: For larger groups, consider off-chain aggregation or batching of expense details with only net changes on-chain.
- **Multi-Group Support**: Extend the contract to manage multiple independent groups within a single deployment, each with its own participant list and balances.
- **Integration with Stablecoins or DEX**: Automatically convert between tokens when settling, ensuring stable-value transfers.
- **Testing & Auditing**: Write thorough unit tests (Hardhat/Foundry) covering both single- and multi-participant flows. Use property-based tests to verify balance invariants (sum of net balances remains zero after operations).
- **Frontend & UX**: Ensure the UI clearly indicates trivial behavior when only one participant is deployed, and guides users through multi-participant operations (e.g., prompting for allowances for ERC20).
