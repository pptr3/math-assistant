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
        print("tap")
        performVisionRequest(pixelBuffer: pixelBuffer)
    }
    
    func displayPredictions(text :String) {
        
     /*   let node = createText(text: text)
        
        node.position = SCNVector3(self.hitTestResult.worldTransform.columns.3.x, self.hitTestResult.worldTransform.columns.3.y, self.hitTestResult.worldTransform.columns.3.z)
        
        self.sceneView.scene.rootNode.addChildNode(node)
        */
    }
    
    func createText(text: String) {
        
        
    }
    
    func performVisionRequest(pixelBuffer :CVPixelBuffer) {
        
        
        
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
    
    
}
