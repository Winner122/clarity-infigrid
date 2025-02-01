# InfiGrid
A decentralized infrastructure for IoT devices built on the Stacks blockchain. This contract enables IoT devices to register, authenticate, and securely exchange data on the blockchain.

## Features
- Device registration and authentication
- Secure data storage and exchange
- Device access control
- Data validation and verification
- Real-time data aggregation and analytics
- Configurable triggers and automated responses
- Device group management and monitoring
- Group-wide alert system

## Contract Functions
### Core Functions
- Register new IoT devices
- Authenticate devices
- Store and retrieve device data
- Manage device access permissions
- Query device status and history

### Data Analytics
- Real-time data aggregation
- Statistical calculations (count, sum, average)
- Historical data analysis

### Trigger System
- Create and manage data triggers
- Configure trigger conditions and thresholds
- Define automated responses
- Monitor trigger status

### Device Groups
- Create and manage device groups
- Add/remove devices from groups
- Set group-wide alert thresholds
- Monitor group performance

### Alert System
- Create group-wide alerts
- Configure alert severity levels
- Track alert history
- Manage alert resolution

## Usage Examples
### Setting up Data Aggregation
Data aggregation is automatically handled when storing device data. Access aggregated statistics using the `get-aggregation` function:
```clarity
(get-aggregation device-id data-type)
```

### Creating Device Groups
Create logical groups of devices for easier management:
```clarity
(create-device-group group-id description alert-threshold)
```

### Managing Group Alerts
Set up and manage alerts for device groups:
```clarity
(create-group-alert group-id alert-id alert-type severity message)
```

## Security Considerations
- All operations require proper authentication
- Trigger actions are validated before execution
- Data aggregation maintains data integrity
- Group management restricted to authorized users
- Alert system with graduated severity levels
