;; Clarity Carbon Credit Market Smart Contract
;;
;; This smart contract facilitates the buying, selling, and trading of carbon credits in a decentralized marketplace.
;; The contract allows users to list their carbon credits for sale, purchase credits from other users, and set 
;; parameters such as the price of credits, transaction fees, refund rates, and credit reserve limits. It also
;; enforces business logic related to credit limits, balances, and validation for ownership. The contract ensures
;; that carbon credit transactions are transparent, auditable, and secure.
;;
;; Key Features:
;; - Allows contract owner to set price, fee percentage, refund rate, and reserve limits.
;; - Facilitates credit transactions between users with transaction fees.
;; - Provides functionality for refunds and credit management.
;; - Ensures that users can add/remove credits for sale based on their balance.
;; - Implements a global credit reserve limit to prevent excessive supply.

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-enough-balance (err u101))
(define-constant err-transfer-failed (err u102))
(define-constant err-invalid-price (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-invalid-fee (err u105))
(define-constant err-refund-failed (err u106))
(define-constant err-same-user (err u107))
(define-constant err-reserve-limit-exceeded (err u108))
(define-constant err-invalid-reserve-limit (err u109))

;; Define data variables
(define-data-var carbon-credit-price uint u100) ;; Price per carbon credit in microstacks
(define-data-var max-credits-per-user uint u10000) ;; Maximum carbon credits a user can add
(define-data-var fee-percentage uint u5) ;; Transaction fee in percentage (e.g., 5 means 5%)
(define-data-var refund-rate uint u90) ;; Refund rate in percentage (e.g., 90 means 90% of current price)
(define-data-var credits-reserve-limit uint u1000000) ;; Global carbon credits reserve limit
(define-data-var current-credits-reserve uint u0) ;; Current total credits in the system

;; Define data maps
(define-map user-credits-balance principal uint) ;; User's carbon credits balance
(define-map user-stx-balance principal uint) ;; User's STX balance
(define-map credits-for-sale {user: principal} {amount: uint, price: uint})

;; Private functions

;; Calculate transaction fee
(define-private (calculate-fee (value uint))
  (let (
    (current-fee-rate (var-get fee-percentage))
  )
    (/ (* value current-fee-rate) u100))
)

;; Calculate refund amount
(define-private (calculate-refund (amount uint))
  (/ (* amount (var-get carbon-credit-price) (var-get refund-rate)) u100))

;; Update credits reserve
(define-private (update-credits-reserve (amount int))
  (let (
    (current-reserve (var-get current-credits-reserve))
    (new-reserve (if (< amount 0)
                     (if (>= current-reserve (to-uint (- 0 amount)))
                         (- current-reserve (to-uint (- 0 amount)))
                         u0)
                     (+ current-reserve (to-uint amount))))
  )
    (asserts! (<= new-reserve (var-get credits-reserve-limit)) err-reserve-limit-exceeded)
    (var-set current-credits-reserve new-reserve)
    (ok true)))

;; Optimize fee calculation by storing fee as a constant
(define-private (optimized-calculate-fee (value uint))
  (let ((current-fee-rate (var-get fee-percentage)))
    (if (< current-fee-rate u10)
        (* value current-fee-rate)
        (* value (/ current-fee-rate u100)))))

;; Public functions

;; Set carbon credit price (only contract owner)
(define-public (set-carbon-credit-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-price u0) err-invalid-price) ;; Ensure price is greater than 0
    (var-set carbon-credit-price new-price)
    (ok true)))

;; Set transaction fee (only contract owner)
(define-public (set-transaction-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u100) err-invalid-fee) ;; Ensure fee is not more than 100%
    (var-set fee-percentage new-fee)
    (ok true)))

;; Set refund rate (only contract owner)
(define-public (set-refund-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-rate u100) err-invalid-fee) ;; Ensure rate is not more than 100%
    (var-set refund-rate new-rate)
    (ok true)))

;; Set credits reserve limit (only contract owner)
(define-public (set-credits-reserve-limit (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (>= new-limit (var-get current-credits-reserve)) err-invalid-reserve-limit)
    (var-set credits-reserve-limit new-limit)
    (ok true)))

;; Add credits for sale
(define-public (add-credits-for-sale (amount uint) (price uint))
  (let (
    (current-balance (default-to u0 (map-get? user-credits-balance tx-sender)))
    (current-for-sale (get amount (default-to {amount: u0, price: u0} (map-get? credits-for-sale {user: tx-sender}))))
    (new-for-sale (+ amount current-for-sale))
  )
    (asserts! (> amount u0) err-invalid-amount) ;; Ensure amount is greater than 0
    (asserts! (> price u0) err-invalid-price) ;; Ensure price is greater than 0
    (asserts! (>= current-balance new-for-sale) err-not-enough-balance)
    (try! (update-credits-reserve (to-int amount)))
    (map-set credits-for-sale {user: tx-sender} {amount: new-for-sale, price: price})
    (ok true)))

;; Remove credits from sale
(define-public (remove-credits-from-sale (amount uint))
  (let (
    (current-for-sale (get amount (default-to {amount: u0, price: u0} (map-get? credits-for-sale {user: tx-sender}))))
  )
    (asserts! (>= current-for-sale amount) err-not-enough-balance)
    (try! (update-credits-reserve (to-int (- amount))))
    (map-set credits-for-sale {user: tx-sender} 
             {amount: (- current-for-sale amount), 
              price: (get price (default-to {amount: u0, price: u0} (map-get? credits-for-sale {user: tx-sender})))})
    (ok true)))

;; Buy credits from user
(define-public (buy-credits-from-user (seller principal) (amount uint))
  (let (
    (sale-data (default-to {amount: u0, price: u0} (map-get? credits-for-sale {user: seller})))
    (credits-cost (* amount (get price sale-data)))
    (transaction-fee (calculate-fee credits-cost))
    (total-cost (+ credits-cost transaction-fee))
    (seller-credits (default-to u0 (map-get? user-credits-balance seller)))
    (buyer-balance (default-to u0 (map-get? user-stx-balance tx-sender)))
    (seller-balance (default-to u0 (map-get? user-stx-balance seller)))
    (owner-balance (default-to u0 (map-get? user-stx-balance contract-owner)))
  )
    (asserts! (not (is-eq tx-sender seller)) err-same-user)
    (asserts! (> amount u0) err-invalid-amount) ;; Ensure amount is greater than 0
    (asserts! (>= (get amount sale-data) amount) err-not-enough-balance)
    (asserts! (>= seller-credits amount) err-not-enough-balance)
    (asserts! (>= buyer-balance total-cost) err-not-enough-balance)

    ;; Update seller's credits balance and for-sale amount
    (map-set user-credits-balance seller (- seller-credits amount))
    (map-set credits-for-sale {user: seller} 
             {amount: (- (get amount sale-data) amount), price: (get price sale-data)})

    ;; Update buyer's STX and credits balance
    (map-set user-stx-balance tx-sender (- buyer-balance total-cost))
    (map-set user-credits-balance tx-sender (+ (default-to u0 (map-get? user-credits-balance tx-sender)) amount))

    ;; Update seller's and contract owner's STX balance
    (map-set user-stx-balance seller (+ seller-balance credits-cost))
    (map-set user-stx-balance contract-owner (+ owner-balance transaction-fee))

    (ok true)))
