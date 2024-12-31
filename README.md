# Clarity Carbon Credit Market Smart Contract

This smart contract enables a decentralized carbon credit marketplace where users can buy, sell, and trade carbon credits. By leveraging the Clarity smart contract language, the contract facilitates secure, transparent, and auditable transactions. It includes mechanisms for managing credit supply, setting prices, and enforcing business logic such as transaction fees, refund rates, and ownership validation.

## Key Features:
- **Admin Control**: Only the contract owner can set key parameters such as carbon credit price, transaction fee, refund rate, and global credit reserve limit.
- **Credit Transactions**: Users can list carbon credits for sale, purchase from other users, and remove credits from sale.
- **Fee and Refund System**: Transaction fees are applied on credit purchases, and users are eligible for refunds based on the specified refund rate.
- **Credit Reserve Limit**: A global reserve limit ensures that the total credits in the marketplace do not exceed a specified threshold.
- **Secure Transactions**: Only authorized users can execute specific functions, ensuring transparency and security in all transactions.

## Contract Logic

The smart contract manages various aspects of the carbon credit market. It defines constants, data variables, and private functions to maintain the system's integrity, including calculating fees, handling refunds, and updating the credit reserve.

### Constants:
- `contract-owner`: Defines the owner of the contract (only the owner can set key parameters).
- Error codes for handling various failures (e.g., insufficient balance, invalid amount).

### Key Variables:
- `carbon-credit-price`: The price per carbon credit (in microstacks).
- `max-credits-per-user`: The maximum credits a user can list for sale.
- `fee-percentage`: The transaction fee percentage.
- `refund-rate`: The refund rate for credits.
- `credits-reserve-limit`: The maximum allowable credits in the system.
- `current-credits-reserve`: The current number of credits in circulation.

### Functions:
1. **Admin Functions**:
   - Set carbon credit price, transaction fee, refund rate, and credits reserve limit.

2. **User Functions**:
   - Add or remove credits for sale.
   - Buy credits from another user.
   - Request refunds for credits.
   - Get total credits of a user.
   - Withdraw STX balance.

### Transaction Workflow:
1. A user can **add credits for sale** by specifying the amount and price.
2. **Buying credits** requires the buyer to pay the seller’s listed price, plus a transaction fee.
3. If a user wishes to **remove credits from sale**, they can do so, ensuring the amount is available in their balance.
4. The **refund process** allows users to receive a percentage of their carbon credit purchase back.

## Smart Contract Structure

### Constants and Error Handling:
```lisp
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-enough-balance (err u101))
```

### Data Variables:
```lisp
(define-data-var carbon-credit-price uint u100)
(define-data-var max-credits-per-user uint u10000)
(define-data-var fee-percentage uint u5)
(define-data-var refund-rate uint u90)
(define-data-var credits-reserve-limit uint u1000000)
(define-data-var current-credits-reserve uint u0)
```

### Key Functions:
- **set-carbon-credit-price**: Set the price for a carbon credit.
- **set-transaction-fee**: Set the transaction fee percentage.
- **set-refund-rate**: Set the refund rate.
- **add-credits-for-sale**: Add carbon credits to the sale pool.
- **remove-credits-from-sale**: Remove credits from sale.
- **buy-credits-from-user**: Buy credits from another user and handle the transfer of STX.
- **refund-credits**: Process a refund for carbon credits based on the specified refund rate.

### Example Transaction Flow:
```lisp
;; Add credits for sale
(add-credits-for-sale 100 10)

;; Buy credits from user
(buy-credits-from-user seller-user 50)
```

### Error Handling:
- Ensure valid amounts and prices for transactions.
- Only the contract owner can set key parameters like fees and prices.
- Prevent overflow or underflow in credit balances and reserves.

## Deployment Instructions

1. Deploy the contract on the Clarity blockchain.
2. Ensure that the contract owner’s address is correctly set.
3. Use the contract functions to manage carbon credits, including setting prices, adding credits for sale, and conducting transactions.

## Contributing

We welcome contributions to this project! Feel free to open an issue or submit a pull request for any improvements or bug fixes.

### License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
