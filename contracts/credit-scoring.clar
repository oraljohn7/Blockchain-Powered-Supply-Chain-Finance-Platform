;; Credit Scoring Contract

(define-map credit-scores
  { participant: principal }
  { score: uint }
)

(define-map performance-records
  { participant: principal }
  {
    total-transactions: uint,
    on-time-payments: uint,
    late-payments: uint
  }
)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u403))

(define-public (record-transaction (participant principal) (on-time bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (let
      (
        (current-record (default-to
          { total-transactions: u0, on-time-payments: u0, late-payments: u0 }
          (map-get? performance-records { participant: participant })
        ))
      )
      (map-set performance-records
        { participant: participant }
        {
          total-transactions: (+ (get total-transactions current-record) u1),
          on-time-payments: (+ (get on-time-payments current-record) (if on-time u1 u0)),
          late-payments: (+ (get late-payments current-record) (if on-time u0 u1))
        }
      )
      (ok true)
    )
  )
)

(define-public (calculate-credit-score (participant principal))
  (let
    (
      (record (unwrap! (map-get? performance-records { participant: participant }) (err u404)))
      (total-transactions (get total-transactions record))
      (on-time-payments (get on-time-payments record))
    )
    (asserts! (> total-transactions u0) (err u400))
    (let
      (
        (score (/ (* on-time-payments u1000) total-transactions))
      )
      (map-set credit-scores
        { participant: participant }
        { score: score }
      )
      (ok score)
    )
  )
)

(define-read-only (get-credit-score (participant principal))
  (ok (unwrap! (map-get? credit-scores { participant: participant }) (err u404)))
)

