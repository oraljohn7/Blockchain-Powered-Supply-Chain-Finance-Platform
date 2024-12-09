;; Automated Payment Contract

(define-map payments
  { payment-id: uint }
  {
    invoice-id: uint,
    amount: uint,
    payer: principal,
    payee: principal,
    status: (string-ascii 20),
    delivery-confirmation: bool
  }
)

(define-data-var last-payment-id uint u0)

(define-public (create-payment (invoice-id uint) (amount uint) (payee principal))
  (let
    (
      (payment-id (+ (var-get last-payment-id) u1))
      (payer tx-sender)
    )
    (map-set payments
      { payment-id: payment-id }
      {
        invoice-id: invoice-id,
        amount: amount,
        payer: payer,
        payee: payee,
        status: "pending",
        delivery-confirmation: false
      }
    )
    (var-set last-payment-id payment-id)
    (ok payment-id)
  )
)

(define-public (confirm-delivery (payment-id uint))
  (let
    (
      (payment (unwrap! (map-get? payments { payment-id: payment-id }) (err u404)))
    )
    (asserts! (is-eq (get payee payment) tx-sender) (err u403))
    (ok (map-set payments
      { payment-id: payment-id }
      (merge payment { delivery-confirmation: true })
    ))
  )
)

(define-public (execute-payment (payment-id uint))
  (let
    (
      (payment (unwrap! (map-get? payments { payment-id: payment-id }) (err u404)))
    )
    (asserts! (get delivery-confirmation payment) (err u400))
    (asserts! (is-eq (get status payment) "pending") (err u400))
    (try! (stx-transfer? (get amount payment) (get payer payment) (get payee payment)))
    (ok (map-set payments
      { payment-id: payment-id }
      (merge payment { status: "completed" })
    ))
  )
)

(define-read-only (get-payment (payment-id uint))
  (ok (unwrap! (map-get? payments { payment-id: payment-id }) (err u404)))
)

