;; Revenue Sharing Contract

;; --- Constants ---
(define-constant ERR-UNAUTHORIZED u1)
(define-constant ERR-INVALID-SHARE u2)
(define-constant ERR-TOTAL-EXCEEDED u3)
(define-constant ERR-NOT-FOUND u4)

;; --- Data Variables ---
(define-data-var owner principal tx-sender)
(define-data-var shares (map principal uint) (map))
(define-data-var total-share uint u0)
(define-data-var revenue-pool uint u0)
(define-data-var voting-contract (optional principal) none)
(define-data-var licensing-contract (optional principal) none)

;; --- Authorization Functions ---

(define-public (set-contracts (voting principal) (licensing principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err ERR-UNAUTHORIZED))
    (var-set voting-contract (some voting))
    (var-set licensing-contract (some licensing))
    (ok true)))

;; --- Proposal Implementation ---

(define-public (implement-proposal (proposal-id uint) (target (optional principal)) (amount uint))
  (begin
    ;; Verify caller is voting contract
    (asserts! (is-eq (some tx-sender) (var-get voting-contract)) (err ERR-UNAUTHORIZED))
    
    (match target
      recipient (set-share recipient amount)  ;; Update specific share
      (distribute-revenue))))  ;; Distribute accumulated revenue

;; --- Share Management ---

(define-public (set-share (contributor principal) (share uint))
  (begin
    (asserts! (or 
      (is-eq tx-sender (var-get owner))
      (is-eq (some tx-sender) (var-get voting-contract))) 
      (err ERR-UNAUTHORIZED))
    (asserts! (<= share u100) (err ERR-INVALID-SHARE))
    
    (let ((current-share (default-to u0 (map-get? shares contributor)))
          (new-total (- (+ (var-get total-share) share) current-share)))
      
      (asserts! (<= new-total u100) (err ERR-TOTAL-EXCEEDED))
      (var-set total-share new-total)
      (ok (map-set shares contributor share)))))

;; --- Revenue Distribution ---

(define-public (receive-payment)
  (begin
    ;; Only accept payments from licensing contract
    (asserts! (is-eq (some tx-sender) (var-get licensing-contract)) 
      (err ERR-UNAUTHORIZED))
    (var-set revenue-pool (+ (var-get revenue-pool) (stx-get-balance tx-sender)))
    (ok true)))

(define-public (distribute-revenue)
  (begin
    (asserts! (or 
      (is-eq tx-sender (var-get owner))
      (is-eq (some tx-sender) (var-get voting-contract))) 
      (err ERR-UNAUTHORIZED))
    
    (let ((total-amount (var-get revenue-pool)))
      (var-set revenue-pool u0)  ;; Reset pool before distribution
      (try! (distribute-shares total-amount))
      (ok true))))

(define-private (distribute-shares (total-amount uint))
  (fold shares 
    (lambda (contributor share prior-result)
      (match prior-result
        success 
        (let ((amount (/ (* total-amount share) u100)))
          (if (> amount u0)
            (match (stx-transfer? amount tx-sender contributor)
              success (ok true)
              error (err ERR-UNAUTHORIZED))
            (ok true)))
        error error))
    (ok true)))

;; --- Read Only Functions ---

(define-read-only (get-share (contributor principal))
  (ok (default-to u0 (map-get? shares contributor))))

(define-read-only (get-total-share)
  (ok (var-get total-share)))

(define-read-only (get-revenue-pool)
  (ok (var-get revenue-pool)))