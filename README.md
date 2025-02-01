# InfiGrid
A decentralized infrastructure for IoT devices built on the Stacks blockchain. This contract enables IoT devices to register, authenticate, and securely exchange data on the blockchain.

## Features
- Device registration and authentication
- Secure data storage and exchange
- Device access control
- Data validation and verification
- Real-time data aggregation and analytics
- Configurable triggers and automated responses

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

## Usage Examples
### Setting up Data Aggregation
Data aggregation is automatically handled when storing device data. Access aggregated statistics using the `get-aggregation` function:
```clarity
(get-aggregation device-id data-type)
```

### Creating Triggers
Set up automated responses using the trigger system:
```clarity
(create-trigger device-id trigger-id data-type condition threshold action)
```

## Security Considerations
- All operations require proper authentication
- Trigger actions are validated before execution
- Data aggregation maintains data integrity
