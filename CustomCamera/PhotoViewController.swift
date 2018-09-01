import UIKit
import MathpixClient
import GPUImage
import ARKit

class PhotoViewController: UIViewController, UICollectionViewDelegate, ARSCNViewDelegate {

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
        UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil)
    }
    
   
    
    // Convert CIImage to CGImage
    func convert(cmage:CIImage) -> UIImage {
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
    
    func centerPivot(for node: SCNNode) {
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        node.pivot = SCNMatrix4MakeTranslation(min.x + (max.x - min.x)/2, min.y + (max.y - min.y)/2, min.z + (max.z - min.z)/2)
    }
    
    
}

extension Int {
    var degreesToRadiants: Double { return Double(self) * Double.pi/180 }
}

