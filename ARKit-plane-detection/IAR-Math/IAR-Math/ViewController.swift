//
//  ViewController.swift
//  IAR-Math
//
//  Created by Valerio Potrimba on 31/07/2018.
//  Copyright © 2018 Petru Potrimba. All rights reserved.
//

import UIKit
import ARKit
class ViewController: UIViewController, UICollectionViewDelegate, ARSCNViewDelegate {

    @IBOutlet weak var planeDetected: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var startingPosition: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        self.registerGestureRecognizer()
        self.sceneView.autoenablesDefaultLighting = true
    }
    
    func registerGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        //this line check if the location where you tapped (tapLocation) matches to an horizontal plane surface
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if !hitTest.isEmpty {
            addItem(hitTestResult: hitTest.first!)
        }
        print("tap")
    }
    
    func addItem(hitTestResult: ARHitTestResult) {
        let transform = hitTestResult.worldTransform //this transform matrix encodes the position of the detected surface in the third coloumn
        let thirdCol = transform.columns.3
        let node = self.createTextNode(string: "Hello World!")
        self.startingPosition = node
        node.position = SCNVector3(thirdCol.x, thirdCol.y, thirdCol.z)
        self.sceneView.scene.rootNode.addChildNode(node)
    }
    
    
    //this function is triggered everytime an anchor is placed (which means that a new plane has been detected)
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.planeDetected.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.planeDetected.isHidden = true
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let startingPosition = self.startingPosition else {return}
        guard let pointOfView = self.sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let xDistance = location.x - startingPosition.position.x
        let yDistance = location.y - startingPosition.position.y
        let zDistance = location.z - startingPosition.position.z
        DispatchQueue.main.async {
            //print(String(format: "%.2f", xDistance) + "m")
            //print(String(format: "%.2f", yDistance) + "m")
            //print(String(format: "%.2f", zDistance) + "m")
            print(String(format: "%.2f", self.distanceTravelled(x: xDistance, y: yDistance, z: zDistance)) + "m")
        }
        
    }
    
    func distanceTravelled(x: Float, y: Float, z: Float) -> Float {
        return (sqrtf(x*x + y*y + z*z))
    }
    
    func createTextNode(string: String) -> SCNNode {
        let text = SCNText(string: string, extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 1.0)
        text.flatness = 0.01
        text.firstMaterial?.diffuse.contents = UIColor.white
        
        let textNode = SCNNode(geometry: text)
        
        let fontSize = Float(0.04)
        textNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        textNode.eulerAngles = SCNVector3(CGFloat(-90.degreesToRadiants), 0.0, 0.0)
        
        self.centerPivot(for: textNode)
        return textNode
    }
    
    func centerPivot(for node: SCNNode) {
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        node.pivot = SCNMatrix4MakeTranslation(min.x + (max.x - min.x)/2, min.y + (max.y - min.y)/2, min.z + (max.z - min.z)/2)
    }
}

extension Int {
    var degreesToRadiants: Double { return Double(self) * Double.pi/180 }
}
