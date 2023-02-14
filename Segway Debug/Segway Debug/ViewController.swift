//
//  ViewController.swift
//  Segway Debug
//
//  Created by Fery Lancz on 07/04/15.
//  Copyright (c) 2015 Fery Lancz. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var accelerometerLabel: UILabel!
    @IBOutlet weak var gyroscopeLabel: UILabel!
    @IBOutlet weak var angleLabel: UILabel!
    @IBOutlet weak var regulatorLabel: UILabel!
    @IBOutlet weak var pwmLabel: UILabel!
    @IBOutlet weak var proportionalTextField: UITextField!
    @IBOutlet weak var integralTextField: UITextField!
    @IBOutlet weak var derivativeTextField: UITextField!
    @IBOutlet weak var pwmScaleTextField: UITextField!
    
    let segway = Segway(kP: 0.89, kI: 0.00, kD: 0.22, pwmScale: 1.50)
    var textFields: [UITextField]!
    
    @IBAction func connectTapped(_ sender: AnyObject) {
        segway.connect()
    }
    
    @IBAction func disconnectTapped(_ sender: AnyObject) {
        segway.disconnect()
    }
    
    @IBAction func proportionalEdited(_ sender: AnyObject) {
        segway.setKP((proportionalTextField.text as NSString).floatValue)
    }
    
    @IBAction func integralEdited(_ sender: AnyObject) {
        segway.setKI((integralTextField.text as NSString).floatValue)
    }
    
    @IBAction func derivativeEdited(_ sender: AnyObject) {
        segway.setKD((derivativeTextField.text as NSString).floatValue)
    }
    
    @IBAction func pwmScaleEdited(_ sender: AnyObject) {
        segway.setPWMScale((pwmScaleTextField.text as NSString).floatValue)
    }
    
    @IBAction func viewTapped(_ sender: AnyObject) {
        for textField in textFields {
            textField.resignFirstResponder()
        }
    }
    
    func updateLabels() {
        statusLabel.text = segway.connectionStatus.rawValue
        accelerometerLabel.text = NSString(format: "%.2fg", segway.accelerometerValue) as String
        gyroscopeLabel.text = NSString(format: "%.2f°/s", segway.gyroscopeValue) as String
        angleLabel.text = NSString(format: "%.2f°", segway.angle) as String
        regulatorLabel.text = NSString(format: "%.2f", segway.regulatedOutput) as String
        pwmLabel.text = NSString(format: "%.2f°/o", segway.pwm) as String
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textFields = [proportionalTextField, integralTextField, derivativeTextField, pwmScaleTextField]
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ViewController.updateLabels), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

