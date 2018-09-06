//
//  SecondViewController.swift
//  CustomCamera
//
//  Created by Valerio Potrimba on 06/09/2018.
//  Copyright © 2018 Brian Advent. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {

    @IBOutlet weak var image: UIImageView!
    var takenPhoto: UIImage?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.image.image = self.takenPhoto
    }
}
