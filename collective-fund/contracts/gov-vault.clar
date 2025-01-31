;; Community Treasury Smart Contract

;; Error codes
(define-constant ERROR-ACCESS-DENIED (err u100))
(define-constant ERROR-BALANCE-TOO-LOW (err u101))
(define-constant ERROR-AMOUNT-INVALID (err u102))
(define-constant ERROR-NONEXISTENT-PROPOSAL (err u103))
(define-constant ERROR-DUPLICATE-VOTE (err u104))
(define-constant ERROR-VOTING-CLOSED (err u105))
(define-constant ERROR-DEPOSIT-TOO-LOW (err u106))
(define-constant ERROR-INVALID-PAYEE (err u107))
(define-constant ERROR-INVALID-TEXT (err u108))
(define-constant ERROR-INVALID-CONTROLLER (err u109))

;; Governance Constants
(define-constant VOTE-WINDOW-BLOCKS u10000)
(define-constant INITIAL-STAKE_REQUIRED u1000000)
(define-constant MIN_PARTICIPATION_THRESHOLD u500)
(define-constant SUCCESS_VOTE_PERCENTAGE u510)

;; State Variables
(define-data-var vault-balance uint u0)
(define-data-var proposal-counter uint u0)
(define-data-var vault-controller principal tx-sender)

;; Data Storage
(define-map active-proposals
    uint
    {
        author: principal,
        withdrawal-size: uint,
        beneficiary: principal,
        details: (string-utf8 256),
        support-count: uint,
        opposition-count: uint,
        submission-height: uint,
        completed: bool,
        stake-amount: uint
    }
)

(define-map vote-registry
    {proposal-number: uint, voter: principal}
    bool
)

(define-map contributor-balances principal uint)

;; Query Functions
(define-read-only (get-vault-balance)
    (var-get vault-balance)
)

(define-read-only (fetch-proposal (proposal-number uint))
    (map-get? active-proposals proposal-number)
)

(define-read-only (check-vote-status (proposal-number uint) (voter principal))
    (default-to false (map-get? vote-registry 
        {proposal-number: proposal-number, voter: voter}))
)

(define-read-only (get-contributor-balance (contributor principal))
    (default-to u0 (map-get? contributor-balances contributor))
)

;; Helper Functions
(define-private (is-vote-active (proposal-number uint))
    (let (
        (proposal-data (unwrap! (fetch-proposal proposal-number) false))
        (current-height block-height)
    )
    (and
        (>= current-height (get submission-height proposal-data))
        (< current-height (+ (get submission-height proposal-data) VOTE-WINDOW-BLOCKS))
        (not (get completed proposal-data))
    ))
)

(define-private (check-vote-threshold (support-count uint) (opposition-count uint))
    (let (
        (vote-sum (+ support-count opposition-count))
    )
    (and
        (>= vote-sum MIN_PARTICIPATION_THRESHOLD)
        (>= (* support-count u1000) (* SUCCESS_VOTE_PERCENTAGE vote-sum))
    ))
)

(define-private (validate-beneficiary (beneficiary principal))
    (and
        (not (is-eq beneficiary (as-contract tx-sender)))  
        (not (is-eq beneficiary tx-sender))               
        true                                            
    )
)

(define-private (validate-text (details (string-utf8 256)))
    (let ((text-size (len details)))
        (and
            (> text-size u0)           
            (<= text-size u256)        
            true                      
        )
    )
)

;; Public Functions
(define-public (contribute-funds)
    (let (
        (contribution-size (stx-get-balance tx-sender))
        (previous-contribution (get-contributor-balance tx-sender))
    )
    (begin
        (try! (stx-transfer? contribution-size tx-sender (as-contract tx-sender)))
        (var-set vault-balance (+ (var-get vault-balance) contribution-size))
        (map-set contributor-balances tx-sender (+ previous-contribution contribution-size))
        (ok contribution-size)
    ))
)

(define-public (initiate-proposal (withdrawal-size uint) (beneficiary principal) (details (string-utf8 256)))
    (let (
        (proposal-number (var-get proposal-counter))
    )
    (begin
        ;; Input validation
        (asserts! (validate-beneficiary beneficiary) ERROR-INVALID-PAYEE)
        (asserts! (validate-text details) ERROR-INVALID-TEXT)
        (asserts! (>= withdrawal-size u0) ERROR-AMOUNT-INVALID)
        (asserts! (<= withdrawal-size (var-get vault-balance)) ERROR-BALANCE-TOO-LOW)
        
        ;; Handle stake
        (try! (stx-transfer? INITIAL-STAKE_REQUIRED tx-sender (as-contract tx-sender)))
        
        ;; Record proposal
        (map-set active-proposals proposal-number {
            author: tx-sender,
            withdrawal-size: withdrawal-size,
            beneficiary: beneficiary,
            details: details,
            support-count: u0,
            opposition-count: u0,
            submission-height: block-height,
            completed: false,
            stake-amount: INITIAL-STAKE_REQUIRED
        })
        
        (var-set proposal-counter (+ proposal-number u1))
        (ok proposal-number)
    ))
)

(define-public (record-vote (proposal-number uint) (support bool))
    (let (
        (proposal-data (unwrap! (fetch-proposal proposal-number) ERROR-NONEXISTENT-PROPOSAL))
    )
    (begin
        (asserts! (is-vote-active proposal-number) ERROR-VOTING-CLOSED)
        (asserts! (not (check-vote-status proposal-number tx-sender)) ERROR-DUPLICATE-VOTE)
        
        (map-set vote-registry 
            {proposal-number: proposal-number, voter: tx-sender} 
            true)
        
        (if support
            (map-set active-proposals proposal-number 
                (merge proposal-data {support-count: (+ (get support-count proposal-data) u1)}))
            (map-set active-proposals proposal-number 
                (merge proposal-data {opposition-count: (+ (get opposition-count proposal-data) u1)}))
        )
        
        (ok true)
    ))
)

(define-public (execute-proposal (proposal-number uint))
    (let (
        (proposal-data (unwrap! (fetch-proposal proposal-number) ERROR-NONEXISTENT-PROPOSAL))
    )
    (begin
        (asserts! (not (get completed proposal-data)) ERROR-VOTING-CLOSED)
        (asserts! (check-vote-threshold 
            (get support-count proposal-data) 
            (get opposition-count proposal-data)) 
            ERROR-ACCESS-DENIED)
        
        ;; Execute transfer
        (try! (as-contract (stx-transfer? (get withdrawal-size proposal-data) 
                                        tx-sender 
                                        (get beneficiary proposal-data))))
        
        ;; Update vault
        (var-set vault-balance 
            (- (var-get vault-balance) (get withdrawal-size proposal-data)))
        
        ;; Return stake
        (try! (as-contract (stx-transfer? (get stake-amount proposal-data)
                                        tx-sender
                                        (get author proposal-data))))
        
        ;; Update status
        (map-set active-proposals proposal-number 
            (merge proposal-data {completed: true}))
            
        (ok true)
    ))
)

;; Administrative Functions
(define-public (reassign-controller (new-controller principal))
    (begin
        (asserts! (is-eq tx-sender (var-get vault-controller)) ERROR-ACCESS-DENIED)
        (asserts! (not (is-eq new-controller (as-contract tx-sender))) ERROR-INVALID-CONTROLLER)
        (var-set vault-controller new-controller)
        (ok true)
    ))

;; Emergency Functions
(define-public (emergency-withdrawal)
    (begin
        (asserts! (is-eq tx-sender (var-get vault-controller)) ERROR-ACCESS-DENIED)
        (try! (as-contract (stx-transfer? (var-get vault-balance)
                                  tx-sender
                                  (var-get vault-controller))))
        (var-set vault-balance u0)
        (ok true)
    ))