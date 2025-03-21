;; Title: DePo (Decentralized Price Oracle) Aggregator
;; depo-aggregator.clar

;; title: depo-aggregator
;; version:
;; summary:
;; description:
;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_STALE_PRICE (err u101))
(define-constant ERR_INSUFFICIENT_PROVIDERS (err u102))
(define-constant ERR_PRICE_TOO_LOW (err u103))
(define-constant ERR_PRICE_TOO_HIGH (err u104))
(define-constant ERR_PRICE_DEVIATION (err u105))

;; traits
;;
(define-constant PRICE_PRECISION u100000000)  ;; 8 decimal places
(define-constant MAX_PRICE_AGE u900)          ;; 15 minutes in blocks
(define-constant MIN_PRICE_PROVIDERS u3)      ;; Minimum required price providers
(define-constant MAX_PRICE_PROVIDERS u10)     ;; Maximum allowed price providers
(define-constant MAX_PRICE_DEVIATION u200)    ;; 20% maximum deviation from median
(define-constant MIN_VALID_PRICE u100000)     ;; Minimum valid price
(define-constant MAX_VALID_PRICE u1000000000) ;; Maximum valid price

;; token definitions
;;
;; Data Variables
(define-data-var current-price uint u0)
(define-data-var last-update-block uint u0)
(define-data-var active-providers uint u0)

;; Error Handling
(define-map error-messages (response uint uint) (string-ascii 64))
(map-insert error-messages ERR_NOT_AUTHORIZED "Not authorized to perform this action")
(map-insert error-messages ERR_STALE_PRICE "Price data is stale")
(map-insert error-messages ERR_INSUFFICIENT_PROVIDERS "Insufficient number of price providers")
(map-insert error-messages ERR_PRICE_TOO_LOW "Price is below minimum threshold")
(map-insert error-messages ERR_PRICE_TOO_HIGH "Price is above maximum threshold")
(map-insert error-messages ERR_PRICE_DEVIATION "Price deviates too much from median")



;;
;; Maps
(define-map price-providers principal bool)
(define-map provider-prices principal uint)
(define-map provider-last-update principal uint)
(define-map active-provider-list uint principal)
(define-map historical-prices uint {price: uint, block: uint})
;; Add new error messages
(map-insert error-messages ERR_ZERO_PRICE "Price cannot be zero")
(map-insert error-messages ERR_INVALID_BLOCK "Invalid block height provided")
(map-insert error-messages ERR_PROVIDER_EXISTS "Provider already exists")

;; data vars
;;
;; Private Functions
(define-private (is-contract-owner)
    (is-eq tx-sender CONTRACT_OWNER))

;; data maps
;;
(define-private (is-authorized-provider (provider principal))
    (default-to false (map-get? price-providers provider)))

;; public functions
;;
(define-private (get-provider-price (provider principal))
    (default-to u0 (map-get? provider-prices provider)))

;; read only functions
;;
(define-private (collect-provider-prices (index uint) (prices (list 100 uint)))
    (match (map-get? active-provider-list index)
        provider (let ((price (get-provider-price provider)))
                    (if (> price u0)
                        (unwrap! (as-max-len? (append prices price) u100) prices)
                        prices))
        prices))

;; private functions
;; (define-private (get-all-provider-prices)
    (fold collect-provider-prices
        (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9)
        (list)))

(define-private (find-min-price (prices (list 100 uint)))
    (fold min-reducer prices u0))

(define-private (min-reducer (price uint) (min-price uint))
    (if (or (is-eq min-price u0) (< price min-price))
        price
        min-price))

;; Public Functions
(define-public (add-price-provider (provider principal))
    (begin
        (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
        (asserts! (< (var-get active-providers) MAX_PRICE_PROVIDERS) ERR_NOT_AUTHORIZED)
        (let ((provider-count (var-get active-providers)))
            (map-set price-providers provider true)
            (map-set active-provider-list provider-count provider)
            (var-set active-providers (+ provider-count u1))
            (ok true))))

(define-public (remove-price-provider (provider principal))
    (begin
        (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
        (let ((provider-count (var-get active-providers)))
            (map-delete price-providers provider)
            (map-delete provider-prices provider)
            (map-delete provider-last-update provider)
            (map-delete active-provider-list (- provider-count u1))
            (var-set active-providers (- provider-count u1))
            (ok true))))

(define-public (submit-price (price uint))
    (begin
        (asserts! (is-authorized-provider tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (>= price MIN_VALID_PRICE) ERR_PRICE_TOO_LOW)
        (asserts! (<= price MAX_VALID_PRICE) ERR_PRICE_TOO_HIGH)

        (map-set provider-prices tx-sender price)
        (map-set provider-last-update tx-sender stacks-block-height)

        (let ((prices (get-all-provider-prices)))
            (asserts! (>= (len prices) MIN_PRICE_PROVIDERS) ERR_INSUFFICIENT_PROVIDERS)
            (let ((median (find-min-price prices)))
                (var-set current-price median)
                (var-set last-update-block stacks-block-height)
                (ok median)))))

(define-read-only (get-current-price)
    (begin
        (asserts! (< (- stacks-block-height (var-get last-update-block)) MAX_PRICE_AGE)
                 ERR_STALE_PRICE)
        (ok (var-get current-price))))

(define-read-only (get-price-provider-count)
    (var-get active-providers))

(define-read-only (get-provider-status (provider principal))
    (map-get? price-providers provider))

(define-read-only (get-last-update-block)
    (var-get last-update-block))


(define-read-only (get-historical-price (block uint))
    (match (map-get? historical-prices block)
        price-data (ok price-data)
        (err u106)))  ;; Error if no price exists for that block

;; Adding new error codes for unchecked scenarios
(define-constant ERR_ZERO_PRICE (err u106))
(define-constant ERR_INVALID_BLOCK (err u107))
(define-constant ERR_PROVIDER_EXISTS (err u108))



;; Data structures
(define-map donations
  (tuple (donor principal) (cause-id uint))
  (tuple (amount uint) (timestamp uint))
)

(define-map causes
  (tuple (cause-id uint))
  (tuple (name (string-ascii 64)) (target uint) (raised uint) (recipient principal))
)

(define-non-fungible-token donation-certificate uint)
(define-data-var next-cause-id uint u1)
(define-data-var next-certificate-id uint u1)

;; Read-only functions
(define-read-only (get-cause (cause-id uint))
  (map-get? causes {cause-id: cause-id})
)

(define-read-only (get-donation (donor principal) (cause-id uint))
  (map-get? donations {donor: donor, cause-id: cause-id})
)

;; Public functions
(define-public (create-cause (name (string-ascii 64)) (target uint) (recipient principal))
  (let
    (
      (cause-id (var-get next-cause-id))
    )
    (begin
      (map-set causes
        {cause-id: cause-id}
        {
          name: name,
          target: target,
          raised: u0,
          recipient: recipient
        }
      )
      (var-set next-cause-id (+ cause-id u1))
      (ok cause-id)
    )
  )
)

(define-private (mint-certificate (donor principal) (cause-id uint))
  (let
    (
      (cert-id (var-get next-certificate-id))
    )
    (begin
      (try! (nft-mint? donation-certificate cert-id donor))
      (var-set next-certificate-id (+ cert-id u1))
      (ok cert-id)
    )
  )
)

(define-public (donate (cause-id uint) (amount uint))
  (let
    (
      (cause (get-cause cause-id))
    )
    (match cause cause-data
      (begin
        (asserts! (> amount u0) (err u400))
        (let
          (
            (new-raised (+ (get raised cause-data) amount))
          )
          (begin
            (map-set donations
              {donor: tx-sender, cause-id: cause-id}
              {amount: amount, timestamp: stacks-block-height}
            )
            (map-set causes
              {cause-id: cause-id}
              (merge cause-data {raised: new-raised})
            )
            (try! (mint-certificate tx-sender cause-id))
            (ok true)
          )
        )
      )
      (err u404)
    )
  )
)

(define-public (get-cause-donations (cause-id uint))
  (ok (map-get? causes {cause-id: cause-id}))
)

(define-public (disburse-funds (cause-id uint))
  (let
    (
      (cause (get-cause cause-id))
    )
    (match cause cause-data
      (begin
        (asserts! (>= (get raised cause-data) (get target cause-data)) (err u402))
        (asserts! (is-eq tx-sender (get recipient cause-data)) (err u403))
        (try! (stx-transfer? (get raised cause-data) (as-contract tx-sender) (get recipient cause-data)))
        (map-delete causes {cause-id: cause-id})
        (ok true)
      )
      (err u404)
    )
  )
)
