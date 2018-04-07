//
//  ViewController.swift
//  bleConnectionIos11
//
//  Created by 刘阳 on 2018/4/7.
//  Copyright © 2018年 刘阳. All rights reserved.
//

import UIKit
import SystemConfiguration
import SystemConfiguration.CaptiveNetwork
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate  {

    @IBOutlet var TFSSID: UITextField!
    @IBOutlet var TFPasswd: UITextField!
    @IBOutlet var TFCustomInfo: UITextField!
    @IBOutlet var BTStart: UIButton!
    @IBOutlet var isP2P: UISegmentedControl!
    
    var BLECM: CBCentralManager!
    var BLEPeri: CBPeripheral!
    var BLEService: CBService!
    var BLEChar: CBCharacteristic!
    
    var BLEPM: CBPeripheralManager!
    
    struct Msg: Codable {
        var SSID: String
        var Passwd: String
        //var CustomInfo: String
    }
    
    var packet = Data()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        TFSSID.text = getssid()
        //TFPasswd.text = "yangliujiezou"
        TFPasswd.text = "123456789"
        
        //self.BLEPeri.delegate = self
        
        self.BLECM = CBCentralManager(delegate: self, queue: nil)
        self.BLEPM = CBPeripheralManager(delegate: self, queue: nil)
        
        makeMsg()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startOnclick() {
        if BTStart.currentTitle!.hasPrefix("start") {
            BTStart.setTitle("stop", for: .normal)
            
            if isP2P.selectedSegmentIndex == 0 {
                makeMsg()
                startBle(true)
            }
            else {
                let alertContrl = UIAlertController(title: "sorry", message: "broadcat not implemented", preferredStyle: UIAlertControllerStyle.alert)
                 alertContrl.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                 present(alertContrl, animated: true, completion: nil)
                
                 BTStart.setTitle("start", for: .normal)
                
                /*
                self.BLEPM.startAdvertising([CBAdvertisementDataLocalNameKey: "barry", CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: "FFE0"), CBUUID(string: "FFE1")]])*/
            }
        }
        else {
            startBle(false)
            if self.BLEPM.isAdvertising {
                self.BLEPM.stopAdvertising()
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(central.description)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("didDiscover")
        print(peripheral.name ?? "")
        print(peripheral.identifier.uuidString)
        
        //if (peripheral.name ?? "" == "mtkaudio" ) {
        if peripheral.name ?? "" == "mtkaudio" {
            self.BLECM.stopScan()
            
            self.BLEPeri = peripheral;
            self.BLEPeri.delegate = self
            
            self.BLECM.connect(BLEPeri, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect")
        
        self.BLEPeri.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral")
        
        let alertContrl = UIAlertController(title: "OK", message: "configure successfully", preferredStyle: UIAlertControllerStyle.alert)
        present(alertContrl, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            alertContrl.dismiss(animated: true, completion: nil)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("didDiscoverServices")
        if self.BLEPeri.services?.count != 0 {
            for service in self.BLEPeri.services! {
                print(service.uuid.uuidString)
                if service.uuid.uuidString.contains("33445566") {
                    self.BLEService = service
                    
                    self.BLEPeri.discoverCharacteristics(nil, for: self.BLEService)
                    print("discoverCharacteristics")
                }
            }
        }
        else {
            print("no service")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristicsFor")
        if service.characteristics!.count != 0 {
            for character in service.characteristics! {
                let aC :CBCharacteristic = character as CBCharacteristic
                if service == BLEService {
                    print(aC.uuid.uuidString)
                    print(aC.description)
                    
                    if character.uuid.uuidString.contains("44556677") {
                        if self.BLEPeri.state == CBPeripheralState.connected {
                            self.BLEChar = character
                            self.BLEPeri.writeValue(packet, for: self.BLEChar, type: CBCharacteristicWriteType.withResponse)
                            print("writeValue")
                        }
                        else {
                            print("unconnect")
                        }
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error == nil) {
            print("write OK")
            startBle(false)
        }
        else {
            print("write NG: \(error.debugDescription)")
        }
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print(peripheral.state)
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("peripheralIsReady")
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("peripheralManagerDidStartAdvertising")
        if error == nil {
            
        }
        else {
            print(error.debugDescription)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        TFSSID.resignFirstResponder()
        TFPasswd.resignFirstResponder()
    }
    
    func simpleEncrypt(_ plainText: Data) -> Data {
        var cipherText = Data()
        
        for i in 0..<plainText.count {
            var key: UInt8
            
            switch i % 4 {
            case 0:
                key = 0x50 //'P'
            case 1:
                key = 0x4C //'L'
            case 2:
                key = 0x48 //'H'
            default:
                key = 0x5A //'Z'
            }
            
            if (plainText[i] ^ key) != 0 {
                cipherText.append(plainText[i] ^ key)
            }
            else {
                cipherText.append(plainText[i])
            }
        }
        
        return cipherText
    }
    
    func makeMsg() {
        //let msg = Msg(SSID: TFSSID.text!, Passwd: TFPasswd.text!, CustomInfo: TFCustomInfo.text!)
        let msg = Msg(SSID: TFSSID.text!, Passwd: TFPasswd.text!)
        //let encoder = JSONEncoder()
        //encoder.outputFormatting = .prettyPrinted
        
        do {
            packet = try JSONEncoder().encode(msg)
            //pading space
            for _ in 1...(4 - packet.count % 4) {
                packet.append(contentsOf: [0x20])
            }
            print(String(data: packet, encoding: .utf8) ?? "")
            
            packet = simpleEncrypt(packet)
        }catch {
            
        }
    }
    
    func startBle(_ enable :Bool) {
        if enable {
            BTStart.setTitle("stop", for: .normal)
            self.BLECM.scanForPeripherals(withServices: nil, options: nil)
        }
        else {
            BTStart.setTitle("start", for: .normal)
            if self.BLECM.isScanning {
                self.BLECM.stopScan()
            }
            
            if self.BLEPeri != nil && self.BLEPeri.state == CBPeripheralState.connected {
                self.BLECM.cancelPeripheralConnection(self.BLEPeri)
            }
        }
    }
    
    func getssid() -> String {
        let ifs = CNCopySupportedInterfaces()
        var SSID: String = ""
        if ifs != nil {
            let ifArray = CFBridgingRetain(ifs) as! Array<AnyObject>
            if ifArray.count > 0 {
                let ifName = ifArray[0] as! CFString
                let ifData = CNCopyCurrentNetworkInfo(ifName)
                if ifData != nil {
                    let ifDictData = ifData as! Dictionary<String, Any>
                    SSID = ifDictData["SSID"] as! String
                }
            }
        }
        
        return SSID
    }
}

