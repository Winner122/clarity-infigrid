;; InfiGrid - Decentralized IoT Infrastructure

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-device-exists (err u101))
(define-constant err-device-not-found (err u102))
(define-constant err-invalid-data (err u103))

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

(define-read-only (is-device-active (device-id principal))
    (match (map-get? devices device-id)
        device (ok (get is-active device))
        (err err-device-not-found)
    )
)