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
class MyViewController: UIViewController {

    
    @IBOutlet weak var capturedImage: UIImageView!
    private var hitTestResult :ARHitTestResult!
    @IBOutlet var outputTextView: UIView!
    @IBAction func onRecognize(_ sender: UIButton) {
  /*
        // Recognize image with mathpix server
        MathpixClient.recognize(image: UIImage(named: "equation")!, outputFormats: [FormatLatex.simplified, FormatWolfram.on]) { (error, result) in
            print(result ?? error ?? "")
             print(result.debugDescription)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
     */
    }
    
    
    @IBOutlet weak var sceneView: ARSCNView!
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self as? ARSCNViewDelegate
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        self.sceneView.scene = scene
        
        registerGestureRecognizers()
        //ImageView.transform = ImageView.transform.rotated(by: CGFloat(M_PI_2))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
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
    }
    
    
    
    func recognizeMathOperation(for image :UIImage) {
        MathpixClient.recognize(image: image, outputFormats: [FormatLatex.simplified, FormatWolfram.on]) { (error, result) in
            print(result ?? error ?? "")
            print(result.debugDescription)
        }
    }
    
    func displayPredictions(text :String) {
        
        /*   let node = createText(text: text)
         
         node.position = SCNVector3(self.hitTestResult.worldTransform.columns.3.x, self.hitTestResult.worldTransform.columns.3.y, self.hitTestResult.worldTransform.columns.3.z)
         
         self.sceneView.scene.rootNode.addChildNode(node)
         */
    }
    
    func createText(text: String) {
        
        
    }
    
    // Convert CIImage to CGImage
    func convert(cmage:CIImage) -> UIImage {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
       // self.capturedImage.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
       // let rect = CGRect(x: 0, y: 0, width: 50, height: 100)
        //return self.cropImage(image, bounds: rect)!
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
    
    
}


