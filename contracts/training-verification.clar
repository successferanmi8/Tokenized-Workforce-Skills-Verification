;; Training Verification Contract
;; Validates completed education

(define-data-var admin principal tx-sender)

;; Map to store training verifications
(define-map training-verifications
  {
    identity-hash: (buff 32),
    training-id: uint
  }
  {
    training-name: (string-utf8 100),
    issuer: (string-utf8 50),
    completion-date: uint,
    verified-by: principal,
    timestamp: uint
  }
)

;; List of authorized training issuers
(define-map authorized-issuers
  { issuer-id: uint }
  {
    name: (string-utf8 50),
    website: (string-utf8 100),
    verified: bool
  }
)

;; Next available training ID
(define-data-var next-training-id uint u1)

;; Next available issuer ID
(define-data-var next-issuer-id uint u1)

;; Public function to verify a training
(define-public (verify-training
    (identity-hash (buff 32))
    (training-name (string-utf8 100))
    (issuer (string-utf8 50))
    (completion-date uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))

    (let ((training-id (var-get next-training-id)))
      (var-set next-training-id (+ training-id u1))
      (ok (map-set training-verifications
        {
          identity-hash: identity-hash,
          training-id: training-id
        }
        {
          training-name: training-name,
          issuer: issuer,
          completion-date: completion-date,
          verified-by: tx-sender,
          timestamp: block-height
        }
      ))
    )
  )
)

;; Public function to add an authorized issuer
(define-public (add-authorized-issuer (name (string-utf8 50)) (website (string-utf8 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (let ((issuer-id (var-get next-issuer-id)))
      (var-set next-issuer-id (+ issuer-id u1))
      (map-set authorized-issuers
        { issuer-id: issuer-id }
        { name: name, website: website, verified: true }
      )
      (ok issuer-id)
    )
  )
)

;; Function to get training verification
(define-read-only (get-training-verification (identity-hash (buff 32)) (training-id uint))
  (map-get? training-verifications { identity-hash: identity-hash, training-id: training-id })
)

;; Function to revoke a training verification
(define-public (revoke-training (identity-hash (buff 32)) (training-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (map-delete training-verifications { identity-hash: identity-hash, training-id: training-id })
    (ok true)
  )
)
