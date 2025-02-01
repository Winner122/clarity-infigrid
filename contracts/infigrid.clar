;; InfiGrid - Decentralized IoT Infrastructure

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-device-exists (err u101))
(define-constant err-device-not-found (err u102))
(define-constant err-invalid-data (err u103))
(define-constant err-invalid-trigger (err u104))
(define-constant err-trigger-exists (err u105))
(define-constant err-group-exists (err u106))
(define-constant err-group-not-found (err u107))
(define-constant err-alert-exists (err u108))

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

;; New data structures for device groups and alerts
(define-map device-groups
    (string-ascii 64)
    {
        owner: principal,
        description: (string-ascii 256),
        created-at: uint,
        alert-threshold: uint
    }
)

(define-map group-members
    {group-id: (string-ascii 64), device-id: principal}
    {joined-at: uint}
)

(define-map group-alerts
    {group-id: (string-ascii 64), alert-id: uint}
    {
        alert-type: (string-ascii 32),
        severity: uint,
        message: (string-ascii 256),
        timestamp: uint,
        resolved: bool
    }
)

;; Original functions remain unchanged...
;; [Previous function implementations]

;; New functions for device groups
(define-public (create-device-group
    (group-id (string-ascii 64))
    (description (string-ascii 256))
    (alert-threshold uint))
    (begin
        (asserts! (is-none (map-get? device-groups group-id)) err-group-exists)
        
        (map-set device-groups
            group-id
            {
                owner: tx-sender,
                description: description,
                created-at: block-height,
                alert-threshold: alert-threshold
            }
        )
        (ok true)
    )
)

(define-public (add-device-to-group
    (group-id (string-ascii 64))
    (device-id principal))
    (let ((group (map-get? device-groups group-id)))
        (asserts! (is-some group) err-group-not-found)
        (asserts! (is-eq tx-sender (get owner (unwrap-panic group))) err-not-authorized)
        
        (map-set group-members
            {group-id: group-id, device-id: device-id}
            {joined-at: block-height}
        )
        (ok true)
    )
)

(define-public (create-group-alert
    (group-id (string-ascii 64))
    (alert-id uint)
    (alert-type (string-ascii 32))
    (severity uint)
    (message (string-ascii 256)))
    (let ((group (map-get? device-groups group-id)))
        (asserts! (is-some group) err-group-not-found)
        (asserts! (is-eq tx-sender (get owner (unwrap-panic group))) err-not-authorized)
        (asserts! (is-none (map-get? group-alerts {group-id: group-id, alert-id: alert-id})) err-alert-exists)
        
        (map-set group-alerts
            {group-id: group-id, alert-id: alert-id}
            {
                alert-type: alert-type,
                severity: severity,
                message: message,
                timestamp: block-height,
                resolved: false
            }
        )
        (ok true)
    )
)

(define-public (resolve-group-alert
    (group-id (string-ascii 64))
    (alert-id uint))
    (let ((group (map-get? device-groups group-id))
          (alert (map-get? group-alerts {group-id: group-id, alert-id: alert-id})))
        (asserts! (is-some group) err-group-not-found)
        (asserts! (is-eq tx-sender (get owner (unwrap-panic group))) err-not-authorized)
        (asserts! (is-some alert) err-invalid-data)
        
        (map-set group-alerts
            {group-id: group-id, alert-id: alert-id}
            (merge (unwrap-panic alert) {resolved: true})
        )
        (ok true)
    )
)

;; New read-only functions
(define-read-only (get-device-group (group-id (string-ascii 64)))
    (map-get? device-groups group-id)
)

(define-read-only (get-group-members (group-id (string-ascii 64)))
    (map-get? group-members {group-id: group-id, device-id: tx-sender})
)

(define-read-only (get-group-alert (group-id (string-ascii 64)) (alert-id uint))
    (map-get? group-alerts {group-id: group-id, alert-id: alert-id})
)
