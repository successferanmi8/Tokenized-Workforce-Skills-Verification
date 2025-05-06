;; Individual Verification Contract
;; Validates worker identities

(define-data-var admin principal tx-sender)

;; Map to store verified identities
(define-map verified-identities
  { identity-hash: (buff 32) }
  {
    verified: bool,
    verified-by: principal,
    timestamp: uint,
    expires-at: uint
  }
)

;; Public function to verify an identity
(define-public (verify-identity (identity-hash (buff 32)) (expires-at uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok (map-set verified-identities
      { identity-hash: identity-hash }
      {
        verified: true,
        verified-by: tx-sender,
        timestamp: block-height,
        expires-at: expires-at
      }
    ))
  )
)

;; Public function to check if an identity is verified
(define-read-only (is-identity-verified (identity-hash (buff 32)))
  (let ((entry (map-get? verified-identities { identity-hash: identity-hash })))
    (if (is-some entry)
      (let ((identity-data (unwrap-panic entry)))
        (if (> (get expires-at identity-data) block-height)
          (ok true)
          (ok false)
        )
      )
      (ok false)
    )
  )
)

;; Function to revoke verification
(define-public (revoke-verification (identity-hash (buff 32)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (map-delete verified-identities { identity-hash: identity-hash })
    (ok true)
  )
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (var-set admin new-admin)
    (ok true)
  )
)
