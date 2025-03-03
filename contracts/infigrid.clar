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
(define-constant err-invalid-severity (err u109))
(define-constant err-device-not-in-group (err u110))
(define-constant MAX-SEVERITY u5)

;; [Previous data structures remain unchanged...]

;; Enhanced group management functions
(define-public (remove-device-from-group
    (group-id (string-ascii 64))
    (device-id principal))
    (let (
        (group (map-get? device-groups group-id))
        (member (map-get? group-members {group-id: group-id, device-id: device-id}))
        )
        (asserts! (is-some group) err-group-not-found)
        (asserts! (is-eq tx-sender (get owner (unwrap-panic group))) err-not-authorized)
        (asserts! (is-some member) err-device-not-in-group)
        
        (map-delete group-members
            {group-id: group-id, device-id: device-id}
        )
        (ok true)
    )
)

;; Enhanced read-only functions
(define-read-only (list-group-devices (group-id (string-ascii 64)))
    (let ((group (map-get? device-groups group-id)))
        (match group
            group-data (ok (map-get? group-members
                (where group-id == group-id)))
            none err-group-not-found
        ))
)

;; [Rest of the contract remains unchanged...]
