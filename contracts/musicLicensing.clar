;; Licensing and Royalty Management Contract

;; Initial variables
(define-data-var owner principal tx-sender)
(define-data-var licensing-fee uint 1000) ; Initial licensing fee
(define-data-var royalties (map principal uint) {}) ; Royalties owed to contributors
(define-data-var authorized-users (map principal bool) {}) ; Authorized users for licensing rights

;; --- Ownership Management ---

;; Set a new owner for the contract
(define-public (set-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Unauthorized"))
    (var-set owner new-owner)
    (ok true)
  )
)

;; --- Licensing Fee Management ---

;; Set the licensing fee (only owner can call this)
(define-public (set-licensing-fee (fee uint))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Unauthorized"))
    (var-set licensing-fee fee)
    (ok true)
  )
)

;; --- Authorization Management ---

;; Grant authorization to a specific user to transfer licensing rights
(define-public (authorize-user (user principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Unauthorized"))
    (map-insert authorized-users user true)
    (ok true)
  )
)

;; Remove authorization from a user
(define-public (remove-authorization (user principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Unauthorized"))
    (map-delete authorized-users user)
    (ok true)
  )
)

;; Transfer licensing rights to another user (if authorized)
(define-public (transfer-licensing-rights (new-owner principal))
  (begin
    (asserts! (is-eq (map-get? authorized-users tx-sender) (some true)) (err "Not authorized"))
    (var-set owner new-owner)
    (map-delete authorized-users tx-sender)
    (ok true)
  )
)

;; --- Royalty Management ---

;; Record royalties owed to a contributor
(define-public (add-royalty (recipient principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Unauthorized"))
    (let ((current-royalty (default 0 (map-get? royalties recipient))))
      (map-insert royalties recipient (+ current-royalty amount))
    )
    (ok true)
  )
)

;; Distribute royalties to all contributors
(define-public (distribute-royalties)
  (begin
    (map-fold royalties (fn (contributor royalty)
      (stx-transfer? royalty tx-sender contributor)
    ) true)
    (ok "Royalties distributed successfully.")
  )
)

;; --- State Query Functions ---

;; View current licensing fee
(define-read-only (get-licensing-fee) (response uint uint)
  (ok (var-get licensing-fee))
)

;; Check if a user is authorized
(define-read-only (is-authorized (user principal)) (response bool bool)
  (ok (default false (map-get? authorized-users user)))
)

;; View current owner
(define-read-only (get-owner) (response principal principal)
  (ok (var-get owner))
)

;; View royalties for a specific contributor
(define-read-only (get-royalty (recipient principal)) (response uint uint)
  (ok (default 0 (map-get? royalties recipient)))
)

;; View total royalties owed
(define-read-only (get-total-royalties) (response uint uint)
  (map-fold royalties (fn (_ amount sum) (+ amount sum)) u0)
)
