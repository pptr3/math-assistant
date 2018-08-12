//
//  ViewController.swift
//  MathPix-API-Sample
//
//  Created by Valerio Potrimba on 12/08/2018.
//  Copyright © 2018 MathPix. All rights reserved.
//

import UIKit
import MathpixClient

class ViewController: UIViewController, CACameraSessionDelegate {

   
    @IBAction func press(_ sender: Any) {
        self.cameraView?.onTapShutterButton()
        guard let button = sender as? UIButton else { return }
        print("button")
    }
    
    @IBOutlet weak var capturedImage: UIImageView!
    @IBOutlet weak var cameraView: CameraSessionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    func setupCamera() {
        self.cameraView?.delegate = self
        //self.cameraView?.hideCameraToogleButton()
        DispatchQueue.main.async {
            self.cameraView?.hideFlashButton()
        }
        
    }
    
   
    func didCapture(_ image: UIImage!) {
        if let cameraView = self.cameraView {
            
            self.capturedImage.image = image
            MathpixClient.recognize(image: image, outputFormats: [FormatLatex.simplified, FormatWolfram.on]) { (error, result) in
                print(result.debugDescription)
            }
        }
        
    }


}
