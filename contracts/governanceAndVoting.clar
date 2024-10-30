;; Governance & Voting Contract

;; --- Constants ---
(define-constant ERR-UNAUTHORIZED u1)
(define-constant ERR-ALREADY-EXISTS u2)
(define-constant ERR-NOT-FOUND u3)
(define-constant ERR-VOTING-CLOSED u4)
(define-constant ERR-NOT-REGISTERED u5)
(define-constant ERR-ACTIVE-PROPOSAL u6)
(define-constant ERR-INVALID-PROPOSAL u7)

;; --- Proposal Types ---
(define-constant PROPOSAL-TYPE-GENERAL u1)
(define-constant PROPOSAL-TYPE-LICENSING u2)
(define-constant PROPOSAL-TYPE-REVENUE u3)

;; --- Data Variables ---
(define-data-var owner principal tx-sender)
(define-data-var votes (map principal bool) (map))
(define-data-var proposal (optional (tuple 
    (id uint)
    (title (string-ascii 100))
    (proposal-type uint)
    (target-principal (optional principal))
    (amount uint)
    (expires-at uint)
)) none)
(define-data-var proposal-passed bool false)
(define-data-var voting-open bool true)
(define-data-var total-voters uint u0)
(define-data-var registered-voters (map principal bool) (map))

;; Contract references
(define-data-var licensing-contract (optional principal) none)
(define-data-var revenue-contract (optional principal) none)

;; --- Authorization Functions ---

(define-public (set-contract-references (licensing principal) (revenue principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err ERR-UNAUTHORIZED))
    (var-set licensing-contract (some licensing))
    (var-set revenue-contract (some revenue))
    (ok true)))

(define-read-only (is-authorized-member (user principal))
  (ok (default-to false (map-get? registered-voters user))))

;; --- Proposal Management ---

(define-public (submit-proposal 
    (title (string-ascii 100))
    (proposal-type uint)
    (target-principal (optional principal))
    (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err ERR-UNAUTHORIZED))
    (asserts! (is-none (var-get proposal)) (err ERR-ACTIVE-PROPOSAL))
    (asserts! (or 
      (is-eq proposal-type PROPOSAL-TYPE-GENERAL)
      (is-eq proposal-type PROPOSAL-TYPE-LICENSING)
      (is-eq proposal-type PROPOSAL-TYPE-REVENUE)) 
      (err ERR-INVALID-PROPOSAL))
    
    (var-set proposal (some {
      id: (+ u1 (default-to u0 (get id (var-get proposal)))),
      title: title,
      proposal-type: proposal-type,
      target-principal: target-principal,
      amount: amount,
      expires-at: (+ block-height u144)  ;; ~24 hours in blocks
    }))
    (var-set votes (map))
    (var-set proposal-passed false)
    (var-set voting-open true)
    (ok true)))

;; --- Voting Functions ---

(define-public (cast-vote (vote bool))
  (begin
    (asserts! (var-get voting-open) (err ERR-VOTING-CLOSED))
    (asserts! (default-to false (map-get? registered-voters tx-sender)) (err ERR-NOT-REGISTERED))
    (ok (map-set votes tx-sender vote))))

(define-public (end-voting)
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err ERR-UNAUTHORIZED))
    (asserts! (var-get voting-open) (err ERR-VOTING-CLOSED))
    
    (let ((vote-result (count-votes-internal)))
      (var-set proposal-passed vote-result)
      (var-set voting-open false)
      ;; If proposal passed, execute it based on type
      (if vote-result
        (match (var-get proposal)
          prop (execute-proposal prop)
          (ok false))
        (ok false)))))

;; --- Internal Functions ---

(define-private (count-votes-internal)
  (let (
    (total-votes (fold votes 
      (lambda (key value acc) (+ acc u1)) 
      u0))
    (pass-votes (fold votes 
      (lambda (key value acc) (if value (+ acc u1) acc)) 
      u0)))
    (>= pass-votes (/ total-votes u2))))

(define-private (execute-proposal (prop {
    id: uint,
    title: (string-ascii 100),
    proposal-type: uint,
    target-principal: (optional principal),
    amount: uint,
    expires-at: uint
  }))
  (match (get proposal-type prop)
    PROPOSAL-TYPE-LICENSING (execute-licensing-proposal prop)
    PROPOSAL-TYPE-REVENUE (execute-revenue-proposal prop)
    (ok true)))

(define-private (execute-licensing-proposal (prop {
    id: uint,
    title: (string-ascii 100),
    proposal-type: uint,
    target-principal: (optional principal),
    amount: uint,
    expires-at: uint
  }))
  (match (var-get licensing-contract)
    contract (contract-call? contract implement-proposal 
      (get id prop)
      (get target-principal prop)
      (get amount prop))
    (err ERR-NOT-FOUND)))

(define-private (execute-revenue-proposal (prop {
    id: uint,
    title: (string-ascii 100),
    proposal-type: uint,
    target-principal: (optional principal),
    amount: uint,
    expires-at: uint
  }))
  (match (var-get revenue-contract)
    contract (contract-call? contract implement-proposal 
      (get id prop)
      (get target-principal prop)
      (get amount prop))
    (err ERR-NOT-FOUND)))