;; LootDAO - Community-driven treasury for gamers
;; A decentralized autonomous organization for funding gaming initiatives

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-member (err u101))
(define-constant err-insufficient-stake (err u102))
(define-constant err-proposal-not-found (err u103))
(define-constant err-voting-ended (err u104))
(define-constant err-voting-active (err u105))
(define-constant err-already-voted (err u106))
(define-constant err-insufficient-balance (err u107))
(define-constant err-proposal-not-passed (err u108))
(define-constant err-already-executed (err u109))
(define-constant err-execution-failed (err u110))
(define-constant err-invalid-amount (err u111))
(define-constant err-member-exists (err u112))
(define-constant err-invalid-duration (err u113))

;; Minimum stake required to become a member (1000 STX)
(define-constant min-stake u1000000000)

;; Voting duration in blocks (approximately 24 hours on Stacks)
(define-constant voting-duration u144)

;; Quorum percentage (20%)
(define-constant quorum-threshold u20)

;; Data Variables
(define-data-var proposal-counter uint u0)
(define-data-var treasury-balance uint u0)
(define-data-var total-members uint u0)
(define-data-var total-staked uint u0)

;; Data Maps
(define-map members principal 
    {
        stake: uint,
        joined-at: uint,
        voting-power: uint,
        reputation: uint
    }
)

(define-map proposals uint
    {
        title: (string-ascii 100),
        description: (string-ascii 500),
        amount: uint,
        recipient: principal,
        proposer: principal,
        created-at: uint,
        voting-ends: uint,
        votes-for: uint,
        votes-against: uint,
        total-voters: uint,
        executed: bool,
        proposal-type: (string-ascii 20)
    }
)

(define-map votes {proposal-id: uint, voter: principal}
    {
        vote: bool,
        voting-power: uint,
        timestamp: uint
    }
)

(define-map member-proposals principal (list 10 uint))

;; Tournament tracking
(define-map tournaments uint
    {
        name: (string-ascii 100),
        prize-pool: uint,
        start-date: uint,
        end-date: uint,
        organizer: principal,
        participants: (list 100 principal),
        status: (string-ascii 20)
    }
)

(define-data-var tournament-counter uint u0)

;; Reward tracking for game mods and fan art
(define-map rewards uint
    {
        creator: principal,
        category: (string-ascii 20),
        amount: uint,
        description: (string-ascii 200),
        approved: bool,
        created-at: uint
    }
)

(define-data-var reward-counter uint u0)

;; Public Functions - Member Management

;; Join DAO by staking tokens
(define-public (join-dao (stake-amount uint))
    (let 
        (
            (sender tx-sender)
            (current-balance (stx-get-balance sender))
        )
        (asserts! (>= stake-amount min-stake) err-insufficient-stake)
        (asserts! (>= current-balance stake-amount) err-insufficient-balance)
        (asserts! (is-none (map-get? members sender)) err-member-exists)
        
        (try! (stx-transfer? stake-amount sender (as-contract tx-sender)))
        
        (map-set members sender
            {
                stake: stake-amount,
                joined-at: stacks-block-height,
                voting-power: (calculate-voting-power stake-amount),
                reputation: u100
            }
        )
        
        (var-set total-members (+ (var-get total-members) u1))
        (var-set total-staked (+ (var-get total-staked) stake-amount))
        (var-set treasury-balance (+ (var-get treasury-balance) stake-amount))
        
        (ok true)
    )
)

;; Add additional stake
(define-public (increase-stake (additional-amount uint))
    (let
        (
            (sender tx-sender)
            (member-info (unwrap! (map-get? members sender) err-not-member))
            (current-stake (get stake member-info))
            (new-stake (+ current-stake additional-amount))
        )
        (asserts! (> additional-amount u0) err-invalid-amount)
        (asserts! (>= (stx-get-balance sender) additional-amount) err-insufficient-balance)
        
        (try! (stx-transfer? additional-amount sender (as-contract tx-sender)))
        
        (map-set members sender
            (merge member-info
                {
                    stake: new-stake,
                    voting-power: (calculate-voting-power new-stake)
                }
            )
        )
        
        (var-set total-staked (+ (var-get total-staked) additional-amount))
        (var-set treasury-balance (+ (var-get treasury-balance) additional-amount))
        
        (ok true)
    )
)

;; Withdraw stake (leave DAO)
(define-public (withdraw-stake)
    (let
        (
            (sender tx-sender)
            (member-info (unwrap! (map-get? members sender) err-not-member))
            (stake-amount (get stake member-info))
        )
        ;; Simple withdrawal - in production, might want cooldown period
        (try! (as-contract (stx-transfer? stake-amount tx-sender sender)))
        
        (map-delete members sender)
        (var-set total-members (- (var-get total-members) u1))
        (var-set total-staked (- (var-get total-staked) stake-amount))
        (var-set treasury-balance (- (var-get treasury-balance) stake-amount))
        
        (ok true)
    )
)

;; Donate to treasury
(define-public (donate (amount uint))
    (let ((sender tx-sender))
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (>= (stx-get-balance sender) amount) err-insufficient-balance)
        
        (try! (stx-transfer? amount sender (as-contract tx-sender)))
        (var-set treasury-balance (+ (var-get treasury-balance) amount))
        
        (ok true)
    )
)

;; Public Functions - Proposal and Voting System

;; Create a new proposal
(define-public (create-proposal 
    (title (string-ascii 100))
    (description (string-ascii 500))
    (amount uint)
    (recipient principal)
    (proposal-type (string-ascii 20))
)
    (let
        (
            (sender tx-sender)
            (proposal-id (+ (var-get proposal-counter) u1))
            (member-info (unwrap! (map-get? members sender) err-not-member))
        )
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (<= amount (var-get treasury-balance)) err-insufficient-balance)
        
        (map-set proposals proposal-id
            {
                title: title,
                description: description,
                amount: amount,
                recipient: recipient,
                proposer: sender,
                created-at: stacks-block-height,
                voting-ends: (+ stacks-block-height voting-duration),
                votes-for: u0,
                votes-against: u0,
                total-voters: u0,
                executed: false,
                proposal-type: proposal-type
            }
        )
        
        (var-set proposal-counter proposal-id)
        
        ;; Update member's proposal history
        (let ((current-proposals (default-to (list) (map-get? member-proposals sender))))
            (map-set member-proposals sender 
                (unwrap! (as-max-len? (append current-proposals proposal-id) u10) (ok proposal-id))
            )
        )
        
        (ok proposal-id)
    )
)

;; Vote on a proposal
(define-public (vote (proposal-id uint) (support bool))
    (let
        (
            (sender tx-sender)
            (proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
            (member-info (unwrap! (map-get? members sender) err-not-member))
            (voting-power (get voting-power member-info))
        )
        (asserts! (<= stacks-block-height (get voting-ends proposal)) err-voting-ended)
        (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: sender})) err-already-voted)
        
        (map-set votes {proposal-id: proposal-id, voter: sender}
            {
                vote: support,
                voting-power: voting-power,
                timestamp: stacks-block-height
            }
        )
        
        (if support
            (map-set proposals proposal-id
                (merge proposal
                    {
                        votes-for: (+ (get votes-for proposal) voting-power),
                        total-voters: (+ (get total-voters proposal) u1)
                    }
                )
            )
            (map-set proposals proposal-id
                (merge proposal
                    {
                        votes-against: (+ (get votes-against proposal) voting-power),
                        total-voters: (+ (get total-voters proposal) u1)
                    }
                )
            )
        )
        
        ;; Increase reputation for active participation
        (map-set members sender
            (merge member-info
                {
                    reputation: (+ (get reputation member-info) u5)
                }
            )
        )
        
        (ok true)
    )
)

;; Execute a passed proposal
(define-public (execute-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
            (votes-for (get votes-for proposal))
            (votes-against (get votes-against proposal))
            (total-voters (get total-voters proposal))
            (total-voting-power (calculate-total-voting-power))
        )
        (asserts! (> stacks-block-height (get voting-ends proposal)) err-voting-active)
        (asserts! (not (get executed proposal)) err-already-executed)
        
        ;; Check if proposal passed (simple majority + quorum)
        (asserts! (> votes-for votes-against) err-proposal-not-passed)
        (asserts! (>= (* total-voters u100) (* total-voting-power quorum-threshold)) err-proposal-not-passed)
        
        ;; Execute transfer
        (try! (as-contract (stx-transfer? (get amount proposal) tx-sender (get recipient proposal))))
        
        ;; Update proposal status
        (map-set proposals proposal-id
            (merge proposal { executed: true })
        )
        
        ;; Update treasury balance
        (var-set treasury-balance (- (var-get treasury-balance) (get amount proposal)))
        
        ;; Reward proposer with reputation
        (let ((proposer-info (unwrap! (map-get? members (get proposer proposal)) err-not-member)))
            (map-set members (get proposer proposal)
                (merge proposer-info
                    {
                        reputation: (+ (get reputation proposer-info) u50)
                    }
                )
            )
        )
        
        (ok true)
    )
)

;; Create tournament
(define-public (create-tournament 
    (name (string-ascii 100))
    (prize-pool uint)
    (duration uint)
)
    (let
        (
            (sender tx-sender)
            (tournament-id (+ (var-get tournament-counter) u1))
            (member-info (unwrap! (map-get? members sender) err-not-member))
        )
        (asserts! (> prize-pool u0) err-invalid-amount)
        (asserts! (> duration u0) err-invalid-duration)
        (asserts! (<= prize-pool (var-get treasury-balance)) err-insufficient-balance)
        
        (map-set tournaments tournament-id
            {
                name: name,
                prize-pool: prize-pool,
                start-date: stacks-block-height,
                end-date: (+ stacks-block-height duration),
                organizer: sender,
                participants: (list),
                status: "active"
            }
        )
        
        (var-set tournament-counter tournament-id)
        (var-set treasury-balance (- (var-get treasury-balance) prize-pool))
        
        (ok tournament-id)
    )
)

;; Submit reward request (for game mods, fan art, etc.)
(define-public (submit-reward-request
    (category (string-ascii 20))
    (amount uint)
    (description (string-ascii 200))
)
    (let
        (
            (sender tx-sender)
            (reward-id (+ (var-get reward-counter) u1))
        )
        (asserts! (is-some (map-get? members sender)) err-not-member)
        (asserts! (> amount u0) err-invalid-amount)
        
        (map-set rewards reward-id
            {
                creator: sender,
                category: category,
                amount: amount,
                description: description,
                approved: false,
                created-at: stacks-block-height
            }
        )
        
        (var-set reward-counter reward-id)
        
        (ok reward-id)
    )
)