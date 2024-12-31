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

;; Public functions

;; Set carbon credit price (only contract owner)
(define-public (set-carbon-credit-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-price u0) err-invalid-price) ;; Ensure price is greater than 0
    (var-set carbon-credit-price new-price)
    (ok true)))
