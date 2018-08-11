//
//  PhotoViewController.swift
//  CustomCamera
//
//  Created by Brian Advent on 24/01/2017.
//  Copyright © 2017 Brian Advent. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {

    var takenPhoto:UIImage?
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let availableImage = takenPhoto {
            imageView.image = availableImage
        }
    }
    
    
    @IBAction func savePhoto(_ sender: Any) {
        guard let imageToSave = self.takenPhoto else {
            return
        }
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        dismiss(animated: true, completion: nil)
    }
    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}
