# Services Architecture

This document outlines the core services used in the Halo app.

## Bluetooth Stack

The Bluetooth stack handles device communication and data transfer.

```mermaid
graph TD
    subgraph BluetoothService
        BS[BluetoothService]
        BS_Config[Configuration]
        BS_Error[BluetoothError]
        BS --> BS_Config
        BS --> BS_Error
    end
    
    subgraph ConnectionManager
        CM[BluetoothConnectionManager]
        CM_State[ConnectionState]
        CM_Delegate[ConnectionDelegate]
        CM --> CM_State
        CM --> CM_Delegate
    end
    
    subgraph DataService
        DS[BluetoothDataService]
        DS_Queue[DataQueue]
        DS_Parser[PacketParser]
        DS --> DS_Queue
        DS --> DS_Parser
    end
    
    subgraph CoreBluetooth
        CB_CM[CBCentralManager]
        CB_P[CBPeripheral]
        CB_Char[CBCharacteristic]
        CB_CM --> CB_P
        CB_P --> CB_Char
    end
    
    BS --> CM
    BS --> DS
    CM --> CB_CM
    DS --> CB_P
    BS --> DD[BluetoothDiscoveryDelegate]
```

### Key Components:
- **BluetoothService**:
  - Main facade for Bluetooth operations
  - Handles configuration and error management
  - Coordinates between connection and data services
  
- **BluetoothConnectionManager**:
  - Manages device connection states
  - Handles connection/disconnection logic
  - Delegates connection events
  
- **BluetoothDataService**:
  - Manages data transfer queue
  - Handles packet parsing and validation
  - Processes incoming sensor data

## Audio Processing Stack

The audio processing pipeline handles real-time audio analysis.

```mermaid
graph TD
    subgraph AudioProcessor
        AP[AudioProcessor]
        AP_State["@Published State"]
        AP_Engine[AVAudioEngine]
        AP --> AP_State
        AP --> AP_Engine
    end
    
    subgraph Processing
        APT[AudioProcessingType]
        SAP[StandardAudioProcessor]
        FFT[FFTProcessor]
        Config[AudioConfig]
        
        APT --> SAP
        SAP --> FFT
        SAP --> Config
    end
    
    subgraph DSP
        Buffer[AudioBuffer]
        Window[HannWindow]
        Transform[FFT]
        Cepstrum[CepstrumCalc]
        
        Buffer --> Window
        Window --> Transform
        Transform --> Cepstrum
    end
    
    AP --> APT
    SAP --> Buffer
    FFT --> Transform
```

### Key Components:
- **AudioProcessor**:
  - Manages audio capture and processing state
  - Coordinates with AVAudioEngine
  - Publishes processed results
  
- **StandardAudioProcessor**:
  - Implements core DSP algorithms
  - Configures processing parameters
  - Manages FFT operations

## Health Services

Health data management and storage services.

```mermaid
graph TD
    subgraph HealthKitService
        HKS[HealthKitService]
        Auth[Authorization]
        Store[HKHealthStore]
        Types[HealthDataTypes]
        
        HKS --> Auth
        HKS --> Store
        HKS --> Types
    end
    
    subgraph DataTypes
        HR[HeartRate]
        HRV[HeartRateVariability]
        Activity[Activity]
        
        Types --> HR
        Types --> HRV
        Types --> Activity
    end
    
    subgraph Storage
        Write[WriteData]
        Read[ReadData]
        Query[QueryBuilder]
        
        Store --> Write
        Store --> Read
        Store --> Query
    end
    
    subgraph Authorization
        Request[RequestAuth]
        Status[AuthStatus]
        Scope[DataScope]
        
        Auth --> Request
        Auth --> Status
        Auth --> Scope
    end
```

### Key Components:
- **HealthKitService**:
  - Manages HealthKit interactions
  - Handles data type configuration
  - Coordinates authorization flow
  
- **Authorization**:
  - Manages permission requests
  - Tracks authorization status
  - Defines data access scope

## Logging Service

Handles data logging and file management.

```mermaid
graph TD
    subgraph LoggingService
        LS[LoggingService]
        Config[LogConfig]
        Error[LoggingError]
        
        LS --> Config
        LS --> Error
    end
    
    subgraph FileManagement
        FM[FileManager]
        Path[PathBuilder]
        Access[FileAccess]
        
        FM --> Path
        FM --> Access
    end
    
    subgraph DataFormat
        CSV[CSVWriter]
        Format[DataFormatter]
        Schema[FileSchema]
        
        CSV --> Format
        CSV --> Schema
    end
    
    subgraph SensorData
        Raw[RawData]
        Processed[ProcessedData]
        Meta[Metadata]
        
        Raw --> Processed
        Processed --> Meta
    end
    
    LS --> FM
    LS --> CSV
    CSV --> Raw
```

### Key Components:
- **LoggingService**:
  - Manages logging configuration
  - Handles error conditions
  - Coordinates file operations
  
- **FileManagement**:
  - Manages file system operations
  - Builds file paths
  - Controls file access

## Service Dependencies

```mermaid
graph TD
    subgraph ViewModel
        RVM[RingViewModel]
        State["@Published State"]
        Commands[UserCommands]
        
        RVM --> State
        RVM --> Commands
    end
    
    subgraph Services
        BS[BluetoothService]
        HKS[HealthKitService]
        LS[LoggingService]
        AP[AudioProcessor]
        
        RVM --> BS
        RVM --> HKS
        RVM --> LS
        RVM --> AP
    end
    
    subgraph DataFlow
        Device[DeviceData]
        Health[HealthData]
        Logs[LogFiles]
        Audio[AudioData]
        
        BS --> Device
        HKS --> Health
        LS --> Logs
        AP --> Audio
        
        Device --> State
        Health --> State
        Logs --> State
        Audio --> State
    end
```

## Error Handling

Each service implements its own error type with specific error cases:

- **BluetoothError**:
  - Connection failures
  - Data transmission errors
  - Device discovery issues
  
- **HaloError**:
  - Service configuration errors
  - Resource access failures
  - State validation errors
  
- **LoggingError**:
  - File system errors
  - Data formatting issues
  - Storage capacity problems

## Configuration

Services can be configured through their respective configuration objects:

- **AudioProcessingConfig**:
  - Window size and type
  - Sample rate
  - Processing parameters
  
- **BluetoothServiceConfiguration**:
  - Service UUIDs
  - Connection timeouts
  - Retry policies

## Testing

Each service has corresponding test files in the HaloTests directory:
- BluetoothServiceTests
- HealthKitServiceTests
- LoggingServiceTests
- AudioProcessingTests
