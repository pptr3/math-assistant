//
//  PreviewViewController.swift
//  MathpixClient_Example
//
//  Created by Valerio Potrimba on 10/08/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class PreviewViewController: UIViewController {

    var image:UIImage?
    @IBOutlet weak var photo: UIImageView!
    
    @IBAction func saveBtn_TouchUpInside(_ sender: Any) {
        guard let imageToSave = image else {
            return
        }
        
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeBtn_TouchUpInside(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.photo.image = image
        // Do any additional setup after loading the view.
    }
    
}
