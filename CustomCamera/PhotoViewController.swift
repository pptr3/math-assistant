import UIKit
import MathpixClient
import GPUImage
import ARKit

class PhotoViewController: UIViewController, UICollectionViewDelegate, ARSCNViewDelegate {

    let configuration = ARWorldTrackingConfiguration()
    @IBOutlet weak var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.session.run(configuration)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       self.sceneView.session.run(configuration)
    }
}
