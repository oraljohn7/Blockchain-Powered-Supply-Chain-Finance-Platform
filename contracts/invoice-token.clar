;; Invoice Token Contract

(define-fungible-token invoice-token)

(define-data-var token-uri (string-utf8 256) u"")

(define-map invoices
  { invoice-id: uint }
  {
    amount: uint,
    issuer: principal,
    payer: principal,
    due-date: uint,
    status: (string-ascii 20)
  }
)

(define-data-var last-invoice-id uint u0)

(define-read-only (get-token-uri)
  (ok (var-get token-uri))
)

(define-public (set-token-uri (new-uri (string-utf8 256)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (ok (var-set token-uri new-uri))
  )
)

(define-public (create-invoice (amount uint) (payer principal) (due-date uint))
  (let
    (
      (invoice-id (+ (var-get last-invoice-id) u1))
      (issuer tx-sender)
    )
    (try! (ft-mint? invoice-token amount issuer))
    (map-set invoices
      { invoice-id: invoice-id }
      {
        amount: amount,
        issuer: issuer,
        payer: payer,
        due-date: due-date,
        status: "pending"
      }
    )
    (var-set last-invoice-id invoice-id)
    (ok invoice-id)
  )
)

(define-public (transfer-invoice (invoice-id uint) (recipient principal))
  (let
    (
      (invoice (unwrap! (map-get? invoices { invoice-id: invoice-id }) (err u404)))
      (amount (get amount invoice))
    )
    (asserts! (is-eq (get issuer invoice) tx-sender) (err u403))
    (try! (ft-transfer? invoice-token amount tx-sender recipient))
    (ok (map-set invoices
      { invoice-id: invoice-id }
      (merge invoice { issuer: recipient })
    ))
  )
)

(define-public (pay-invoice (invoice-id uint))
  (let
    (
      (invoice (unwrap! (map-get? invoices { invoice-id: invoice-id }) (err u404)))
      (amount (get amount invoice))
      (issuer (get issuer invoice))
    )
    (asserts! (is-eq (get payer invoice) tx-sender) (err u403))
    (asserts! (is-eq (get status invoice) "pending") (err u400))
    (try! (stx-transfer? amount tx-sender issuer))
    (try! (ft-burn? invoice-token amount issuer))
    (ok (map-set invoices
      { invoice-id: invoice-id }
      (merge invoice { status: "paid" })
    ))
  )
)

(define-read-only (get-invoice (invoice-id uint))
  (ok (unwrap! (map-get? invoices { invoice-id: invoice-id }) (err u404)))
)

(define-constant contract-owner tx-sender)

