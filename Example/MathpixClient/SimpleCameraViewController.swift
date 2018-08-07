//
//  SimpleCameraViewController.swift
//  MathpixClient
//
//  Created by Дмитрий Буканович on 08.09.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import MathpixClient

class SimpleCameraViewController: UIViewController {
    
    
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.setStatusBarStyle(.default, animated: true)
    }
    
    
    
    @IBAction func onLaunchCamera(_ sender: Any) {
        // Setup camera properties
        /*
         0.set camera for get image
         1.get image
         2.segment the math operations within image
         3.give each segmented image in input at MathpixClient.recognize()
         4.for each image store if operation is correct or not and his starter position on starter image
         5.augmented reality
        */
        
       
        
        MathpixClient.recognize(image: UIImage(named: "equation")!, outputFormats: [FormatLatex.simplified, FormatWolfram.on]) { (error, result) in
            print(result ?? error ?? "")
           // self.outputTextView.text = result.debugDescription
        }
        
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
              //  self.outputTextView.text = result.debugDescription + "  " + (error?.localizedDescription ?? "")
        })
        
    
    }
    
    
}
