import UIKit
import MathpixClient
import GPUImage
import ARKit

class PhotoViewController: UIViewController, UICollectionViewDelegate, ARSCNViewDelegate {

    @IBOutlet weak var planeDetected: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    private var hitTestResult :ARHitTestResult!
    let configuration = ARWorldTrackingConfiguration()
    var startingPosition: SCNNode?
    var isStartingPositionPlaced = false
    var algo = SegmentMathOperationAlgorithm(withVertical: 20, withHorizontal: 45) //vertical ad horizontal are switched
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        self.registerGestureRecognizerForPlaneAndDistance()
        self.sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       self.sceneView.session.run(configuration)
    }
    
    func registerGestureRecognizerForPlaneAndDistance() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedForPlaceAndDistance))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    //First time the screen is tapped, an anchor is placed. The others time, photo frame is exracted and algorithm runs.
    @objc func tappedForPlaceAndDistance(sender: UITapGestureRecognizer) {
        if !self.isStartingPositionPlaced {
            let sceneView = sender.view as! ARSCNView
            let tapLocation = sender.location(in: sceneView)
            //this line check if the location where you tapped (tapLocation) matches to an horizontal plane surface
            let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
            if !hitTest.isEmpty {
                addItem(hitTestResult: hitTest.first!)
                self.isStartingPositionPlaced = true
            }
        } else {
            //image saved when screen is tapped. This should be perfomed when a button is clicked
            let sceneView2 = sender.view as! ARSCNView
            let touchLocation = self.sceneView.center
            guard let currentFrame = sceneView2.session.currentFrame else {
                return
            }
            let hitTestResults = sceneView2.hitTest(touchLocation, types: .featurePoint)
            if hitTestResults.isEmpty {
                return
            }
            guard let hitTestResult = hitTestResults.first else {
                return
            }
            self.hitTestResult = hitTestResult
            let pixelBuffer = currentFrame.capturedImage
            let ciimage : CIImage = CIImage(cvPixelBuffer: pixelBuffer)
            var capturedImage : UIImage = self.convertCIImageToCGImage(cmage: ciimage)
            //UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil)
            //capturedImage = self.imageRotatedByDegrees(oldImage: capturedImage, deg: CGFloat(90.0))
           // UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil)
            DispatchQueue.main.async {
                self.algo.run2()
                //self.algo.run(for: capturedImage)
                self.algo = SegmentMathOperationAlgorithm(withVertical: 20, withHorizontal: 45)
            }
            //self.algo.run(for: capturedImage)
            //self.algo = SegmentMathOperationAlgorithm(withVertical: 20, withHorizontal: 45)
        }
    }
    
    func addItem(hitTestResult: ARHitTestResult) {
        let transform = hitTestResult.worldTransform //this transform matrix encodes the position of the detected surface in the third coloumn
        let thirdCol = transform.columns.3
        let node = SCNNode()
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
    
   
    func centerPivot(for node: SCNNode) {
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        node.pivot = SCNMatrix4MakeTranslation(min.x + (max.x - min.x)/2, min.y + (max.y - min.y)/2, min.z + (max.z - min.z)/2)
    }
   
    
    // Convert CIImage to CGImage
    func convertCIImageToCGImage(cmage:CIImage) -> UIImage {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
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

extension Int {
    var degreesToRadiants: Double { return Double(self) * Double.pi/180 }
}

