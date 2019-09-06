//
//  MasterViewController.swift
//  BluetoothScanner
//
//  Created by Sebastien on 06/09/2019.
//  Copyright © 2019 Epseelon sprl. All rights reserved.
//

import UIKit
import CoreBluetooth

class MasterViewController: UITableViewController {

    var discoveredPeripherals = [CBPeripheral]()
    var connectedPeripherals = [CBPeripheral]()
    var peripheralsSupportingDeviceInformation = [CBPeripheral]()
    
    private let scannedServices: [CBUUID]? = [CBUUID(string: "180A")]//nil
    
    private var scanning = false
    
    private var centralManager: CBCentralManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.leftBarButtonItem = editButtonItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredPeripherals.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let peripheral = discoveredPeripherals[indexPath.row]
        cell.textLabel!.text = peripheral.identifier.uuidString
        cell.detailTextLabel!.text = peripheral.name ?? ""
        if self.peripheralsSupportingDeviceInformation.contains(peripheral) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    @IBAction func scanTapped(_ sender: Any) {
        if !scanning {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Stop", style: .plain, target: self, action: #selector(scanTapped(_:)))
            self.discoveredPeripherals.removeAll()
            self.connectedPeripherals.removeAll()
            self.peripheralsSupportingDeviceInformation.removeAll()
            self.centralManager = CBCentralManager(delegate: self, queue: nil)
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Scan", style: .plain, target: self, action: #selector(scanTapped(_:)))
            self.centralManager?.stopScan()
            self.centralManager = nil
        }
        
    }
}

extension MasterViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: scannedServices, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if discoveredPeripherals.contains(where: { periph -> Bool in
            periph.identifier.uuidString == peripheral.identifier.uuidString
        }) {
            return
        }
        self.discoveredPeripherals.append(peripheral)
        self.tableView.reloadData()
        central.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.connectedPeripherals.append(peripheral)
        peripheral.delegate = self
        peripheral.discoverServices(scannedServices)
    }
}

extension MasterViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Service discovery error: \(String(describing: error))")
        } else {
            if let services = peripheral.services, services.contains(where: { service -> Bool in
                service.uuid.uuidString == "180A"
            }) {
                self.peripheralsSupportingDeviceInformation.append(peripheral)
                self.tableView.reloadData()
            } else if let services = peripheral.services {
                let serviceList = services.map { service -> String in
                    return service.uuid.uuidString
                }
                print("Services supported by \(peripheral.description): \(serviceList.joined(separator: ", "))")
            }
        }
    }
}

