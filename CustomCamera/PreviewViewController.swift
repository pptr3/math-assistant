import UIKit

class PreviewViewController: UIViewController {

    @IBOutlet weak var photo: UIImageView!
    
    var image:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photo.image = image
        // Do any additional setup after loading the view.
    }

    @IBAction func saveBtn_TouchUpInside(_ sender: Any) {
        guard let imageToSave = image else {
            return
        }
        
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        dismiss(animated: true, completion: nil)
    }
    @IBAction func closeBtn_TouchUpInside(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
