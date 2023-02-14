//
//  Segway.swift
//  Segway Debug
//
//  Created by Fery Lancz on 07/04/15.
//  Copyright (c) 2015 Fery Lancz. All rights reserved.
//

import Foundation
import CoreBluetooth

class Segway: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    enum status: String {
        case Initial = "nicht Verbunden"
        case Searching = "Suchen"
        case Connecting = "Verbinden"
        case Ready = "Verbunden"
        case Disconnected = "Verbindung getrennt"
        case DidLostConnection = "Verbindung verloren"
        case PoweredOff = "Bluetooth deaktiviert"
        case Resetting = "Zurücksetzen"
        case Unauthorized = "keine Berechtigung"
        case Unknown = "Unbekannt"
        case Unsupported = "Bluetooth 4.0 nicht verfügbar"
    }
    var connectionStatus = status.Initial
    var connectToPeripheral = false
    var disconnectFromPeripheral = false
    var centralManager: CBCentralManager!
    var bluetoothPeripheral: CBPeripheral!
    var writeCharacteristic: CBCharacteristic!
    var readCharacteristic: CBCharacteristic!
    var commandByte: UInt8!
    var accelerometerValue: Float = 1.00
    var gyroscopeValue: Float = 1.00
    var angle: Float = 1.00
    var regulatedOutput: Float = 1.00
    var pwm: Float = 1.00
    var kP, kI, kD: Float
    var pwmScale: Float
    
    let peripheralName = "Segway"
    let serviceUUID = CBUUID(string: "2220")
    let writeUUID = CBUUID(string: "2222")
    let readUUID = CBUUID(string: "2221")
    
    init(kP: Float, kI: Float, kD: Float, pwmScale: Float) {
        self.kP = kP
        self.kI = kI
        self.kD = kD
        self.pwmScale = pwmScale
    }
    
    func setKP(_ kP: Float) {
        self.kP = kP
        sendByte(0x00)
        sendFloat(kP)
    }
    
    func setKI(_ kI: Float) {
        self.kI = kI
        sendByte(0x01)
        sendFloat(kI)
    }
    
    func setKD(_ kD: Float) {
        self.kD = kD
        sendByte(0x02)
        sendFloat(kD)
    }
    
    func setPWMScale(_ pwmScale: Float) {
        self.pwmScale = pwmScale
        sendByte(0x03)
        sendFloat(pwmScale)
    }
    
    func sendByte(_ data: UInt8) {
        var mutableByte = data
        let byteData = Data(bytes: &mutableByte, length: sizeof(Byte))
        send(byteData)
    }
    
    func sendFloat(_ data: Float) {
        var mutabelFloat = data
        let floatData = Data(bytes: UnsafePointer<UInt8>(&mutabelFloat), count: sizeof(Float))
        send(floatData)
    }
    
    func send(_ data: Data) {
        if connectionStatus == .Ready {
            bluetoothPeripheral.writeValue(data, for: writeCharacteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    func connect() {
        if connectionStatus != .Ready {
            connectToPeripheral = true
            connectionStatus = .Searching
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    func disconnect() {
        if connectionStatus == .Ready {
            centralManager.cancelPeripheralConnection(bluetoothPeripheral)
            disconnectFromPeripheral = true
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager!) {
        if central.state == CBCentralManagerState.poweredOn {
            if connectToPeripheral {
                connectToPeripheral = false
                central.scanForPeripherals(withServices: nil, options: nil)
            }
        }
        else if central.state == CBCentralManagerState.poweredOff {
            connectionStatus = .PoweredOff
        }
        else if central.state == CBCentralManagerState.resetting {
            connectionStatus = .Resetting
        }
        else if central.state == CBCentralManagerState.unauthorized {
            connectionStatus = .Unauthorized
        }
        else if central.state == CBCentralManagerState.unknown {
            connectionStatus = .Unknown
        }
        else if central.state == CBCentralManagerState.unsupported {
            connectionStatus = .Unsupported
        }
    }
    
    func centralManager(_ central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [AnyHashable: Any]!, RSSI: NSNumber!) {
        let nameOfFoundDevice = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString
        if nameOfFoundDevice! as String == peripheralName {
            connectionStatus = .Connecting
            centralManager.stopScan()
            bluetoothPeripheral = peripheral
            bluetoothPeripheral.delegate = self
            centralManager.connect(bluetoothPeripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager!, didConnect peripheral: CBPeripheral!) {
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral!, didDiscoverServices error: Error!) {
        for service in peripheral.services! {
            let thisService = service as CBService
            if thisService.uuid == serviceUUID {
                peripheral.discoverCharacteristics(nil, for: thisService)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral!, didDiscoverCharacteristicsFor service: CBService!, error: Error!) {
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            if thisCharacteristic.uuid == writeUUID {
                writeCharacteristic = thisCharacteristic
            }
            if thisCharacteristic.uuid == readUUID {
                readCharacteristic = thisCharacteristic
                bluetoothPeripheral.setNotifyValue(true, for: thisCharacteristic)
            }
        }
        if writeCharacteristic != nil && readCharacteristic != nil {
            connectionStatus = .Ready
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral!, didUpdateValueFor characteristic: CBCharacteristic!, error: Error!) {
        if characteristic.uuid == readUUID {
            let dataBytes = characteristic.value
            let dataLength = dataBytes?.count
            var dataArray = [Byte](count: dataLength, repeatedValue: 0)
            dataBytes.getBytes(&dataArray, length: sizeof(Float))
            if dataLength == 1 {
                commandByte = dataArray[0]
            }
            else if dataLength == 4 {
                var dataFloat: Float = 0
                memcpy(&dataFloat, dataArray, 4)
                switch commandByte {
                case 0x00:
                    accelerometerValue = dataFloat
                case 0x01:
                    gyroscopeValue = dataFloat
                case 0x02:
                    angle = dataFloat
                case 0x03:
                    regulatedOutput = dataFloat
                case 0x04:
                    pwm = dataFloat
                default:
                    println("unknown command")
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: Error!) {
        writeCharacteristic = nil
        readCharacteristic = nil
        if disconnectFromPeripheral {
            disconnectFromPeripheral = false
            connectionStatus = .Disconnected
        }
        else {
            connectionStatus = .DidLostConnection
            if central.state == CBCentralManagerState.poweredOn {
                central.scanForPeripherals(withServices: nil, options: nil)
            }
            else if central.state == CBCentralManagerState.poweredOff {
                connectionStatus = .PoweredOff
            }
            else if central.state == CBCentralManagerState.resetting {
                connectionStatus = .Resetting
            }
            else if central.state == CBCentralManagerState.unauthorized {
                connectionStatus = .Unauthorized
            }
            else if central.state == CBCentralManagerState.unknown {
                connectionStatus = .Unknown
            }
            else if central.state == CBCentralManagerState.unsupported {
                connectionStatus = .Unsupported
            }
            
        }
    }
}

