;; InfiGrid - Decentralized IoT Infrastructure

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-device-exists (err u101))
(define-constant err-device-not-found (err u102))
(define-constant err-invalid-data (err u103))
(define-constant err-invalid-trigger (err u104))
(define-constant err-trigger-exists (err u105))

;; Data structures
(define-map devices
    principal
    {
        name: (string-ascii 64),
        device-type: (string-ascii 32),
        registered-at: uint,
        is-active: bool
    }
)

(define-map device-data
    {device-id: principal, timestamp: uint}
    {
        data-type: (string-ascii 32),
        value: (string-ascii 256),
        verified: bool
    }
)

(define-map device-permissions
    {device-id: principal, operator: principal}
    {can-write: bool, can-read: bool}
)

(define-map data-aggregations
    {device-id: principal, data-type: (string-ascii 32)}
    {
        count: uint,
        sum: int,
        average: int,
        last-updated: uint
    }
)

(define-map device-triggers
    {device-id: principal, trigger-id: uint}
    {
        data-type: (string-ascii 32),
        condition: (string-ascii 32),
        threshold: int,
        action: (string-ascii 256),
        is-active: bool
    }
)

;; Public functions
(define-public (register-device 
    (name (string-ascii 64))
    (device-type (string-ascii 32)))
    (let ((device-id tx-sender))
        (if (is-some (map-get? devices device-id))
            err-device-exists
            (begin
                (map-set devices
                    device-id
                    {
                        name: name,
                        device-type: device-type,
                        registered-at: block-height,
                        is-active: true
                    }
                )
                (ok device-id)
            )
        )
    )
)

(define-public (store-data 
    (device-id principal)
    (data-type (string-ascii 32))
    (value (string-ascii 256)))
    (let (
        (timestamp block-height)
        (permissions (get-permission device-id tx-sender))
        (numeric-value (to-int value))
    )
        (asserts! (is-some (map-get? devices device-id)) err-device-not-found)
        (asserts! (is-some permissions) err-not-authorized)
        (asserts! (get can-write (unwrap-panic permissions)) err-not-authorized)
        
        (map-set device-data
            {device-id: device-id, timestamp: timestamp}
            {
                data-type: data-type,
                value: value,
                verified: true
            }
        )
        
        ;; Update aggregations
        (update-aggregation device-id data-type numeric-value)
        
        ;; Check triggers
        (check-triggers device-id data-type numeric-value)
        
        (ok timestamp)
    )
)

(define-public (set-device-permission
    (device-id principal)
    (operator principal)
    (can-write bool)
    (can-read bool))
    (begin
        (asserts! (or 
            (is-eq tx-sender contract-owner)
            (is-eq tx-sender device-id)
        ) err-not-authorized)
        
        (map-set device-permissions
            {device-id: device-id, operator: operator}
            {can-write: can-write, can-read: can-read}
        )
        (ok true)
    )
)

(define-public (create-trigger
    (device-id principal)
    (trigger-id uint)
    (data-type (string-ascii 32))
    (condition (string-ascii 32))
    (threshold int)
    (action (string-ascii 256)))
    (begin
        (asserts! (or
            (is-eq tx-sender contract-owner)
            (is-eq tx-sender device-id)
        ) err-not-authorized)
        
        (asserts! (is-none (map-get? device-triggers {device-id: device-id, trigger-id: trigger-id}))
            err-trigger-exists)
        
        (map-set device-triggers
            {device-id: device-id, trigger-id: trigger-id}
            {
                data-type: data-type,
                condition: condition,
                threshold: threshold,
                action: action,
                is-active: true
            }
        )
        (ok true)
    )
)

;; Private functions
(define-private (update-aggregation
    (device-id principal)
    (data-type (string-ascii 32))
    (value int))
    (let (
        (current-agg (default-to
            {count: u0, sum: 0, average: 0, last-updated: u0}
            (map-get? data-aggregations {device-id: device-id, data-type: data-type})
        ))
        (new-count (+ (get count current-agg) u1))
        (new-sum (+ (get sum current-agg) value))
    )
        (map-set data-aggregations
            {device-id: device-id, data-type: data-type}
            {
                count: new-count,
                sum: new-sum,
                average: (/ new-sum (to-int new-count)),
                last-updated: block-height
            }
        )
    )
)

(define-private (check-triggers
    (device-id principal)
    (data-type (string-ascii 32))
    (value int))
    (begin
        (print {event: "trigger-check", device: device-id, value: value})
        (ok true)
    )
)

;; Read only functions
(define-read-only (get-device-info (device-id principal))
    (map-get? devices device-id)
)

(define-read-only (get-device-data (device-id principal) (timestamp uint))
    (map-get? device-data {device-id: device-id, timestamp: timestamp})
)

(define-read-only (get-permission (device-id principal) (operator principal))
    (map-get? device-permissions {device-id: device-id, operator: operator})
)

(define-read-only (get-aggregation (device-id principal) (data-type (string-ascii 32)))
    (map-get? data-aggregations {device-id: device-id, data-type: data-type})
)

(define-read-only (get-trigger (device-id principal) (trigger-id uint))
    (map-get? device-triggers {device-id: device-id, trigger-id: trigger-id})
)

(define-read-only (is-device-active (device-id principal))
    (match (map-get? devices device-id)
        device (ok (get is-active device))
        (err err-device-not-found)
    )
)
