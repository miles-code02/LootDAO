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