(define-data-var owner principal tx-sender) ; Initial owner set as the contract deployer
(define-data-var shares (map principal uint) {}) ; Each contributor with a percentage share
(define-data-var total-share uint 0) ; Track total allocated shares
(define-data-var revenue-pool uint 0) ; Track any undistributed revenue

;; Set a contributor's share percentage (owner-only)
(define-public (set-share (contributor principal) (share uint))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Unauthorized"))
    (asserts! (<= share 100) (err "Invalid share"))
    ;; Calculate new total-share after updating or inserting
    (let ((current-share (default 0 (map-get? shares contributor)))
          (new-total-share (+ (- (var-get total-share) current-share) share)))
      (asserts! (<= new-total-share 100) (err "Total shares exceed 100%"))
      (map-insert shares contributor share)
      (var-set total-share new-total-share)
    )
    (ok true)
  )
)

;; Remove a contributor from the share map (owner-only)
(define-public (remove-contributor (contributor principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Unauthorized"))
    (match (map-get? shares contributor)
      some-share
      (begin
        ;; Update total-share after removal
        (var-set total-share (- (var-get total-share) some-share))
        (map-delete shares contributor)
        (ok true)
      )
      none (err "Contributor not found")
    )
  )
)

;; Distribute revenue based on each contributor's share
(define-public (distribute-revenue (total-amount uint))
  (begin
    (var-set revenue-pool 0) ; Reset the pool before distribution
    (map-fold shares
      (fn (contributor share)
        (let ((amount (/ (* total-amount share) 100)))
          (let ((result (stx-transfer? amount tx-sender contributor)))
            ;; Accumulate any undistributed amount in the pool in case of rounding
            (if (is-ok result)
              (ok true)
              (var-set revenue-pool (+ (var-get revenue-pool) amount))
            )
          )
        )
      )
    true)
    (ok true)
  )
)

;; Change contract owner
(define-public (set-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Unauthorized"))
    (var-set owner new-owner)
    (ok true)
  )
)

;; --- Read-Only Query Functions ---

;; Get the total allocated share
(define-read-only (get-total-share) (response uint uint)
  (ok (var-get total-share))
)

;; Get the share of a specific contributor
(define-read-only (get-contributor-share (contributor principal)) (response uint uint)
  (match (map-get? shares contributor)
    some-share (ok some-share)
    none (err "Contributor not found")
  )
)

;; List all contributors and their shares
(define-read-only (list-contributors) (response (list 200 (tuple (contributor principal) (share uint))) uint)
  (ok (map-to (tuple (contributor principal) (share uint)) shares (tuple contributor (get share shares[contributor]))))
)

;; Get the current revenue pool balance (any undistributed amount)
(define-read-only (get-revenue-pool) (response uint uint)
  (ok (var-get revenue-pool))
)

