//
//  MyViewController.swift
//  MathpixClient_Example
//
//  Created by Valerio Potrimba on 07/08/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import MathpixClient

class MyViewController: UIViewController {

    @IBOutlet var outputTextView: UIView!
    @IBAction func onRecognize(_ sender: UIButton) {
        
        // Recognize image with mathpix server
        MathpixClient.recognize(image: UIImage(named: "equation")!, outputFormats: [FormatLatex.simplified, FormatWolfram.on]) { (error, result) in
            print(result ?? error ?? "")
             print(result.debugDescription)
        }
    }
    @IBAction func button(_ sender: UIButton) {
        let properties = MathCaptureProperties(captureType: .gesture,
                                               requiredButtons: [.flash, .back],
                                               cropColor: UIColor.green,
                                               errorHandling: true)
        
        // Launch camera with back and completion blocks
        MathpixClient.launchCamera(source: self,
                                   outputFormats: [FormatLatex.simplified],
                                   withProperties: properties,
                                   completion:
            { (error, result) in
                print(result.debugDescription + "  " + (error?.localizedDescription ?? ""))
        })
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        print("my view controller")
        // Do any additional setup after loading the view, typically from a nib.
    }
}
