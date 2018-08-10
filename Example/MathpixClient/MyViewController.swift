//
//  MyViewController.swift
//  MathpixClient_Example
//
//  Created by Valerio Potrimba on 07/08/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import MathpixClient
import ARKit
import AVFoundation
import CoreML
import Vision



@available(iOS 11.0, *)
class MyViewController: UIViewController, UICollectionViewDelegate, ARSCNViewDelegate {

    
    @IBOutlet weak var res: UITextView!
    @IBOutlet weak var capturedImage: UIImageView!
    @IBOutlet var outputTextView: UIView!
    @IBOutlet weak var sceneView: ARSCNView!
    
    private var hitTestResult :ARHitTestResult!
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        self.registerGestureRecognizers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.sceneView.session.pause()
    }
    
    
    func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func tapped(recognizer :UIGestureRecognizer) {
        let sceneView = recognizer.view as! ARSCNView
        let touchLocation = self.sceneView.center
        guard let currentFrame = sceneView.session.currentFrame else {
            return
        }
        let hitTestResults = sceneView.hitTest(touchLocation, types: .featurePoint)
        if hitTestResults.isEmpty {
            return
        }
        guard let hitTestResult = hitTestResults.first else {
            return
        }
        self.hitTestResult = hitTestResult
        let pixelBuffer = currentFrame.capturedImage
        let ciimage : CIImage = CIImage(cvPixelBuffer: pixelBuffer)
        var capturedImage : UIImage = self.convert(cmage: ciimage)
        capturedImage = self.imageRotatedByDegrees(oldImage: capturedImage, deg: CGFloat(90.0))
        //self.capturedImage.image = capturedImage
        self.recognizeMathOperation(for: capturedImage)
      /*  if let rgbCapturedImage = RGBAImage(image: capturedImage) {
            //testing drawing on image
            let y = 100
            for x in 0..<100 {
    
                let index = y * rgbCapturedImage.width + x
                var pixel = rgbCapturedImage.pixels[index]
            
                //here I'm setting one pixel of my rgb image to be red
                pixel.red = 255
                pixel.green = 0
                pixel.blue = 0
                rgbCapturedImage.pixels[index] = pixel
            }
            let newUIImageFromRGBAImage = rgbCapturedImage.toUIImage()
            self.capturedImage.image = newUIImageFromRGBAImage
        }*/
        let textImage = textToImage(drawText: "❌", inImage: capturedImage, atPoint: CGPoint(x: 200, y: 200))
        self.capturedImage.image = textImage
    }
    
    func recognizeMathOperation(for image :UIImage) {
        MathpixClient.recognize(image: image, outputFormats: [FormatLatex.simplified, FormatWolfram.on]) { (error, result) in
           // print(result ?? error ?? "")
           // print(result.debugDescription)
            self.res.text =  String(result.debugDescription)
            
        }
           
    }
    
    // Convert CIImage to CGImage
    func convert(cmage:CIImage) -> UIImage {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    func cropImage(_ image: UIImage, bounds: CGRect) -> UIImage? {
        //Resize image with aspectRation to screen
        var rect = CGRect.zero
        let aspectX = image.size.width / bounds.size.width
        let aspectY = image.size.height / bounds.size.height
        var aspectRationImage: CGFloat = 0.0
        
        if aspectX > aspectY {
            aspectRationImage = bounds.size.width / bounds.size.height
            rect.origin.y = 0
            rect.size.height = image.size.height
            
            let widthOfImage = aspectRationImage * image.size.height
            let halfOriginalImage = image.size.width / 2
            let halfNewImage = widthOfImage / 2
            let offsetImageX = halfOriginalImage - halfNewImage
            rect.origin.x = offsetImageX
            rect.size.width = widthOfImage
        }
        else {
            aspectRationImage = bounds.size.height / bounds.size.width
            rect.origin.x = 0
            rect.size.width = image.size.width
            
            let heightOfImage = aspectRationImage * image.size.width
            let halfOriginalImage = image.size.height / 2
            let halfNewImage = heightOfImage / 2
            let offsetImageY = halfOriginalImage - halfNewImage
            rect.origin.y = offsetImageY
            rect.size.height = heightOfImage
        }
        
        //Crop image with aspectRation to screen. If it not make then result cropped image will scaled
        let resultImage = image.fixOrientation().croppedImage(rect)
        
        return resultImage
        
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
    
    func centerPivot(for node: SCNNode) {
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        node.pivot = SCNMatrix4MakeTranslation(min.x + (max.x - min.x)/2, min.y + (max.y - min.y)/2, min.z + (max.z - min.z)/2)
    }
    
    func textToImage(drawText text: String, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        let textColor = UIColor.blue
        let textFont = UIFont(name: "Helvetica Bold", size: 200)!
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            ] as [NSAttributedString.Key : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        let rect = CGRect(origin: point, size: image.size)
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

extension Int {
    var degreesToRadiants: Double { return Double(self) * Double.pi/180 }
}

extension String {
    
    func contains(find: String) -> Bool{
        return self.range(of: find) != nil
    }
    
    func containsIgnoringCase(find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    
    
}

extension StringProtocol where Index == String.Index {
    func index<T: StringProtocol>(of string: T, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }
    func endIndex<T: StringProtocol>(of string: T, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.upperBound
    }
    func indexes<T: StringProtocol>(of string: T, options: String.CompareOptions = []) -> [Index] {
        var result: [Index] = []
        var start = startIndex
        while start < endIndex, let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range.lowerBound)
            start = range.lowerBound < range.upperBound ? range.upperBound : index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
    func ranges<T: StringProtocol>(of string: T, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var start = startIndex
        while start < endIndex, let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range)
            start = range.lowerBound < range.upperBound  ? range.upperBound : index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}


