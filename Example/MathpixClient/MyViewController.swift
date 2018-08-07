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
        print("button")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        print("my view controller")
        // Do any additional setup after loading the view, typically from a nib.
    }
}
