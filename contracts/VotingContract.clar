(define-data-var owner principal tx-sender) ; Owner is the contract deployer
(define-data-var votes (map principal bool) {}) ; Store votes as boolean values
(define-data-var proposal (option (string-ascii 100)) none) ; Active proposal for voting
(define-data-var proposal-passed bool false) ; Proposal outcome
(define-data-var voting-open bool true) ; Indicates if voting is still open
(define-data-var total-voters uint 0) ; Total registered voters
(define-data-var registered-voters (map principal bool) {}) ; Registered voters

;; Submit a proposal (owner-only)
(define-public (submit-proposal (new-proposal (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Unauthorized"))
    (asserts! (is-none (var-get proposal)) (err "Active proposal exists"))
    (var-set proposal (some new-proposal))
    (var-set votes {})
    (var-set proposal-passed false)
    (var-set voting-open true)
    (ok "Proposal submitted and voting opened")
  )
)

;; Register a voter (owner-only)
(define-public (register-voter (voter principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Unauthorized"))
    (asserts! (is-none (map-get? registered-voters voter)) (err "Already registered"))
    (map-insert registered-voters voter true)
    (var-set total-voters (+ (var-get total-voters) 1))
    (ok true)
  )
)

;; Cast a vote (only registered voters and if voting is open)
(define-public (cast-vote (vote bool))
  (begin
    (asserts! (is-eq (var-get voting-open) true) (err "Voting has ended"))
    (asserts! (is-some (map-get? registered-voters tx-sender)) (err "Not a registered voter"))
    (map-insert votes tx-sender vote)
    (ok "Vote casted successfully")
  )
)

;; Count votes and determine if the proposal passed (owner-only)
(define-public (count-votes)
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Unauthorized"))
    (let (
      (total-votes (fold votes (fn (acc uint voted) (+ acc 1)) 0))
      (pass-votes (fold votes (fn (acc uint vote) (if vote (+ acc 1) acc)) 0))
    )
      (var-set proposal-passed (>= pass-votes (/ total-votes 2)))
    )
    (ok (var-get proposal-passed))
  )
)

;; End voting (owner-only)
(define-public (end-voting)
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Unauthorized"))
    (asserts! (is-eq (var-get voting-open) true) (err "Voting already closed"))
    (var-set voting-open false)
    (ok "Voting ended")
  )
)

;; --- Read-Only Query Functions ---

;; Get the current proposal
(define-read-only (get-proposal) (response (option (string-ascii 100)) (string-ascii 100))
  (ok (var-get proposal))
)

;; Check if the proposal passed
(define-read-only (proposal-passed?) (response bool (string-ascii 100))
  (ok (var-get proposal-passed))
)

;; Get total voters and voting results
(define-read-only (get-voting-results) (response (tuple (total-voters uint) (total-votes uint) (pass-votes uint)) (string-ascii 100))
  (let (
    (total-votes (fold votes (fn (acc uint _) (+ acc 1)) 0))
    (pass-votes (fold votes (fn (acc uint vote) (if vote (+ acc 1) acc)) 0))
  )
    (ok (tuple (total-voters (var-get total-voters)) (total-votes total-votes) (pass-votes pass-votes)))
  )
)

