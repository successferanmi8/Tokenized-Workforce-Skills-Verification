;; Skill Certification Contract
;; Records verified capabilities

(define-data-var admin principal tx-sender)

;; Map to store skill certifications
(define-map skill-certifications
  {
    identity-hash: (buff 32),
    skill-id: uint
  }
  {
    skill-name: (string-utf8 50),
    proficiency-level: uint,
    verified-by: principal,
    timestamp: uint,
    expires-at: uint
  }
)

;; Skill registry - to standardize skill definitions
(define-map skill-registry
  { skill-id: uint }
  { skill-name: (string-utf8 50), category: (string-utf8 30) }
)

;; Next available skill ID
(define-data-var next-skill-id uint u1)

;; Public function to certify a skill
(define-public (certify-skill
    (identity-hash (buff 32))
    (skill-id uint)
    (proficiency-level uint)
    (expires-at uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (asserts! (< proficiency-level u6) (err u101)) ;; Proficiency levels 0-5
    (asserts! (is-some (map-get? skill-registry { skill-id: skill-id })) (err u102))

    (ok (map-set skill-certifications
      {
        identity-hash: identity-hash,
        skill-id: skill-id
      }
      {
        skill-name: (get skill-name (unwrap-panic (map-get? skill-registry { skill-id: skill-id }))),
        proficiency-level: proficiency-level,
        verified-by: tx-sender,
        timestamp: block-height,
        expires-at: expires-at
      }
    ))
  )
)

;; Public function to add a skill to the registry
(define-public (add-skill (skill-name (string-utf8 50)) (category (string-utf8 30)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (let ((skill-id (var-get next-skill-id)))
      (var-set next-skill-id (+ skill-id u1))
      (map-set skill-registry
        { skill-id: skill-id }
        { skill-name: skill-name, category: category }
      )
      (ok skill-id)
    )
  )
)

;; Function to get skill certification
(define-read-only (get-skill-certification (identity-hash (buff 32)) (skill-id uint))
  (map-get? skill-certifications { identity-hash: identity-hash, skill-id: skill-id })
)

;; Function to revoke a skill certification
(define-public (revoke-skill (identity-hash (buff 32)) (skill-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (map-delete skill-certifications { identity-hash: identity-hash, skill-id: skill-id })
    (ok true)
  )
)
