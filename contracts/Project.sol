// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Expense Splitting / Bill-Splitting Contract
 * @dev This contract allows a group (possibly size 1) of participants to record shared expenses and settle balances.
 */
contract ExpenseSplitter {
    // Mapping of participant address to net balance.
    // Positive balance: others owe this address.
    // Negative balance: this address owes others.
    mapping(address => int256) private netBalance;
    
    // List of participants defined at deployment.
    address[] public participants;
    mapping(address => bool) public isParticipant;

    // Events
    event ExpenseRecorded(address indexed payer, uint256 totalAmount, address indexed token, address[] involved, uint256[] shares);
    event ExpenseSettled(address indexed from, address indexed to, address indexed token, uint256 amount);
    
    /**
     * @dev Constructor sets the initial participants. All addresses in the array should be unique.
     *      Now allows a single participant (length >= 1).
     * @param _participants Array of addresses participating in expense splitting.
     */
    constructor(address[] memory _participants) {
        require(_participants.length > 0, "At least one participant required");
        for (uint i = 0; i < _participants.length; i++) {
            address p = _participants[i];
            require(p != address(0), "Invalid address");
            require(!isParticipant[p], "Duplicate participant");
            isParticipant[p] = true;
            participants.push(p);
            netBalance[p] = 0;
        }
    }

    /**
     * @dev Record a shared expense paid by msg.sender.
     * @param totalAmount Total amount paid (in wei for Ether, or token amount for ERC20).
     * @param token Address of ERC20 token contract, or address(0) if Ether.
     * @param involved Array of participant addresses sharing this expense (must include payer if payer shares).
     * @param shares Array of shares corresponding to involved participants. Sum of shares must equal totalShares.
     *               The actual amount for each = totalAmount * shares[i] / totalShares.
     * @param totalShares Sum of share weights. E.g., equal split among N: totalShares = N, each share = 1.
     * Note: For Ether expenses, msg.value must equal totalAmount.
     * For ERC20, payer must approve this contract to spend totalAmount before calling.
     */
    function recordExpense(
        uint256 totalAmount,
        address token,
        address[] memory involved,
        uint256[] memory shares,
        uint256 totalShares
    ) external payable {
        require(involved.length == shares.length, "Mismatched arrays");
        require(involved.length > 0, "No participants specified");
        require(totalShares > 0, "Total shares must be > 0");

        // Validate involved participants and shares
        uint256 sumShares = 0;
        bool payerInvolved = false;
        for (uint i = 0; i < involved.length; i++) {
            address u = involved[i];
            require(isParticipant[u], "Address not a participant");
            sumShares += shares[i];
            if (u == msg.sender) {
                payerInvolved = true;
            }
        }
        require(sumShares == totalShares, "Shares must sum to totalShares");
        require(payerInvolved, "Payer must be in involved list");

        // Handle payment
        if (token == address(0)) {
            // Ether
            require(msg.value == totalAmount, "Incorrect Ether amount");
        } else {
            // ERC20: transfer tokens from payer to this contract
            require(msg.value == 0, "Do not send Ether for token expense");
            IERC20(token).transferFrom(msg.sender, address(this), totalAmount);
        }

        // Update net balances
        for (uint i = 0; i < involved.length; i++) {
            address u = involved[i];
            uint256 shareAmount = (totalAmount * shares[i]) / totalShares;
            if (u == msg.sender) {
                // Payer: netBalance increases by (totalAmount - own share)
                int256 diff = int256(totalAmount) - int256(shareAmount);
                netBalance[msg.sender] += diff;
            } else {
                // Other: netBalance decreases by shareAmount
                netBalance[u] -= int256(shareAmount);
            }
        }

        emit ExpenseRecorded(msg.sender, totalAmount, token, involved, shares);
    }

    /**
     * @dev Settle a debt from msg.sender to another participant.
     * @param to Address of participant to settle with.
     * @param amount Amount to settle (in wei or token units).
     * @param token Address of ERC20 token contract, or address(0) if Ether.
     * Requirements:
     *  - msg.sender must owe at least 'amount' (netBalance[msg.sender] <= -int256(amount)).
     *  - 'to' must be participant and netBalance[to] >= int256(amount).
     *  - For Ether, msg.value == amount; for ERC20, approve before calling.
     */
    function settleExpense(address to, uint256 amount, address token) external payable {
        require(isParticipant[to], "Recipient not a participant");
        int256 senderBal = netBalance[msg.sender];
        int256 recipientBal = netBalance[to];
        require(senderBal <= -int256(amount), "Not enough owed to settle");
        require(recipientBal >= int256(amount), "Recipient not owed that much");

        // Handle transfer
        if (token == address(0)) {
            require(msg.value == amount, "Incorrect Ether amount");
            payable(to).transfer(amount);
        } else {
            require(msg.value == 0, "Do not send Ether for token settlement");
            IERC20(token).transferFrom(msg.sender, to, amount);
        }

        // Update balances
        netBalance[msg.sender] += int256(amount);
        netBalance[to] -= int256(amount);

        emit ExpenseSettled(msg.sender, to, token, amount);
    }

    /**
     * @dev Get net balance of a participant.
     * @param user Address of participant.
     * @return Signed integer: positive means others owe user; negative means user owes others.
     */
    function getNetBalance(address user) external view returns (int256) {
        require(isParticipant[user], "Not a participant");
        return netBalance[user];
    }
}

// Minimal ERC20 interface
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
