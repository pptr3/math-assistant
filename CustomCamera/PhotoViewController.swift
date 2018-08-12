//
//  PhotoViewController.swift
//  CustomCamera
//
//  Created by Brian Advent on 24/01/2017.
//  Copyright © 2017 Brian Advent. All rights reserved.
//

import UIKit
import MathpixClient

class PhotoViewController: UIViewController {

    var takenPhoto:UIImage?
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let availableImage = self.takenPhoto {
            MathpixClient.recognize(image: self.imageRotatedByDegrees(oldImage:  availableImage, deg: CGFloat(90.0)), outputFormats: [FormatLatex.simplified, FormatWolfram.on]) { (error, result) in
                let chars = Array(result.debugDescription)
                if let coordinates = self.getCoordinates(from: chars) {
                    self.imageView.image = self.textToImage(drawText: ".", inImage: availableImage, atPoint: CGPoint(x: coordinates[0], y: coordinates[1]))
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            }
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
/*Used directly in viewDidLoad()
    func recognizeMathOperation(for image :UIImage){
        MathpixClient.recognize(image: self.imageRotatedByDegrees(oldImage:  image, deg: CGFloat(90.0)), outputFormats: [FormatLatex.simplified, FormatWolfram.on]) { (error, result) in
            // print(result.debugDescription)
            let chars = Array(result.debugDescription)
            let coordinates = self.getTopLeftX(from: chars)
            
            //  self.textToImage(drawText: "CIAO", inImage: image, atPoint: CGPoint(x: coordinates![0], y: coordinates![1]))
            //image = self.textToImage(drawText: "ciaooooo", inImage: image, atPoint: CGPoint(x: 10, y: 10))
        }
    }*/
    
    func getCoordinates(from chars: [Character]) -> Array<Int>? {
        var coordinates: Array<Int> = []
        let topLeftX = Array("top_left_")
        var topIndex = 0
        var count = 0
        var found = 0
        for index in chars.indices {
            if chars[index] == topLeftX[topIndex] {
                var index2 = index
                for _ in topLeftX.indices {
                    if chars[index2] == topLeftX[topIndex] {
                        count += 1
                        index2 += 1
                        topIndex += 1
                    }
                }
                topIndex = 0
                if count == topLeftX.count {
                    if let coordinate = self.getNumber(from: chars, from: index2+5) { //"+5" is where the number starts
                        coordinates.append(coordinate)
                    }
                    found += 1
                    if found == 2 {
                        return coordinates
                    }
                }
                count = 0
            }
        }
        return nil
    }
    
    private func getNumber(from chars: [Character], from index: Int ) -> Int? {
        var myStringNumber = ""
        var i = index
        for _ in chars.indices {
            if chars[i] != ";" {
                myStringNumber.append(chars[i])
                i += 1
            } else {
                break
            }
        }
        return Int(myStringNumber) ?? nil
    }
    
    func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.width, height: oldImage.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func textToImage(drawText text: NSString, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        let textColor = UIColor.blue
        let textFont = UIFont(name: "Helvetica Bold", size: 50)!
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            ] as [String : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        let rect = CGRect(origin: point, size: image.size)
        text.draw(in: rect, withAttributes: textFontAttributes)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
