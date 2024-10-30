;; Licensing Contract

;; --- Constants ---
(define-constant ERR-UNAUTHORIZED u1)
(define-constant ERR-INVALID-AMOUNT u2)
(define-constant ERR-NOT-FOUND u3)
(define-constant ERR-NOT-AUTHORIZED u4)

;; --- Data Variables ---
(define-data-var owner principal tx-sender)
(define-data-var licensing-fee uint u1000)
(define-data-var authorized-users (map principal bool) (map))
(define-data-var voting-contract (optional principal) none)
(define-data-var revenue-contract (optional principal) none)

;; --- Authorization Functions ---

(define-public (set-contracts (voting principal) (revenue principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err ERR-UNAUTHORIZED))
    (var-set voting-contract (some voting))
    (var-set revenue-contract (some revenue))
    (ok true)))

(define-read-only (is-authorized (user principal))
  (ok (default-to false (map-get? authorized-users user))))

;; --- Proposal Implementation ---

(define-public (implement-proposal (proposal-id uint) (target (optional principal)) (amount uint))
  (begin
    ;; Verify caller is voting contract
    (asserts! (is-eq (some tx-sender) (var-get voting-contract)) (err ERR-UNAUTHORIZED))
    
    (match target
      recipient (add-authorized-user recipient)  ;; If target specified, add user
      (set-licensing-fee amount))))  ;; Otherwise update fee

;; --- Licensing Management ---

(define-public (set-licensing-fee (new-fee uint))
  (begin
    (asserts! (or 
      (is-eq tx-sender (var-get owner))
      (is-eq (some tx-sender) (var-get voting-contract))) 
      (err ERR-UNAUTHORIZED))
    (ok (var-set licensing-fee new-fee))))

(define-public (add-authorized-user (user principal))
  (begin
    (asserts! (or 
      (is-eq tx-sender (var-get owner))
      (is-eq (some tx-sender) (var-get voting-contract))) 
      (err ERR-UNAUTHORIZED))
    (ok (map-set authorized-users user true))))

(define-public (remove-authorized-user (user principal))
  (begin
    (asserts! (or 
      (is-eq tx-sender (var-get owner))
      (is-eq (some tx-sender) (var-get voting-contract))) 
      (err ERR-UNAUTHORIZED))
    (ok (map-delete authorized-users user))))

;; --- Payment Processing ---

(define-public (pay-license-fee)
  (begin
    (asserts! (>= (stx-get-balance tx-sender) (var-get licensing-fee)) 
      (err ERR-INVALID-AMOUNT))
    
    ;; Transfer fee to revenue contract for distribution
    (match (var-get revenue-contract)
      revenue-principal
      (begin
        (try! (stx-transfer? (var-get licensing-fee) tx-sender revenue-principal))
        (map-set authorized-users tx-sender true)
        (ok true))
      (err ERR-NOT-FOUND))))

;; --- Read Only Functions ---

(define-read-only (get-licensing-fee)
  (ok (var-get licensing-fee)))

(define-read-only (get-owner)
  (ok (var-get owner)))