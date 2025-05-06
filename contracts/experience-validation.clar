;; Experience Validation Contract
;; Confirms work history claims

(define-data-var admin principal tx-sender)

;; Map to store experience validations
(define-map experience-validations
  {
    identity-hash: (buff 32),
    experience-id: uint
  }
  {
    company: (string-utf8 50),
    role: (string-utf8 50),
    start-date: uint,
    end-date: uint,
    verified-by: principal,
    validator-company: (string-utf8 50),
    timestamp: uint
  }
)

;; Map of trusted validators from companies
(define-map trusted-validators
  { validator-id: uint }
  {
    name: (string-utf8 50),
    company: (string-utf8 50),
    role: (string-utf8 50),
    active: bool
  }
)

;; Next available experience ID
(define-data-var next-experience-id uint u1)

;; Next available validator ID
(define-data-var next-validator-id uint u1)

;; Public function to validate experience
(define-public (validate-experience
    (identity-hash (buff 32))
    (company (string-utf8 50))
    (role (string-utf8 50))
    (start-date uint)
    (end-date uint)
    (validator-company (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (asserts! (>= end-date start-date) (err u101))

    (let ((experience-id (var-get next-experience-id)))
      (var-set next-experience-id (+ experience-id u1))
      (ok (map-set experience-validations
        {
          identity-hash: identity-hash,
          experience-id: experience-id
        }
        {
          company: company,
          role: role,
          start-date: start-date,
          end-date: end-date,
          verified-by: tx-sender,
          validator-company: validator-company,
          timestamp: block-height
        }
      ))
    )
  )
)

;; Public function to add a trusted validator
(define-public (add-trusted-validator (name (string-utf8 50)) (company (string-utf8 50)) (role (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (let ((validator-id (var-get next-validator-id)))
      (var-set next-validator-id (+ validator-id u1))
      (map-set trusted-validators
        { validator-id: validator-id }
        { name: name, company: company, role: role, active: true }
      )
      (ok validator-id)
    )
  )
)

;; Function to get experience validation
(define-read-only (get-experience-validation (identity-hash (buff 32)) (experience-id uint))
  (map-get? experience-validations { identity-hash: identity-hash, experience-id: experience-id })
)

;; Function to revoke an experience validation
(define-public (revoke-experience (identity-hash (buff 32)) (experience-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (map-delete experience-validations { identity-hash: identity-hash, experience-id: experience-id })
    (ok true)
  )
)
