import UIKit
import AVFoundation
import MathpixClient

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    let captureSession = AVCaptureSession()
    var previewLayer:CALayer!
    var captureDevice:AVCaptureDevice!
    var takePhoto = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareCamera()
    }

    func prepareCamera() {
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        if let availableDevices = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .back).devices {
            captureDevice = availableDevices.first
            beginSession()
        }
    }
    
    func beginSession () {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput)
        } catch {
            print(error.localizedDescription)
        }
        
        if let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) {
            self.previewLayer = previewLayer
            self.view.layer.addSublayer(self.previewLayer)
            self.previewLayer.frame = self.view.layer.frame
            captureSession.startRunning()
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString):NSNumber(value:kCVPixelFormatType_32BGRA)]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            if captureSession.canAddOutput(dataOutput) {
                captureSession.addOutput(dataOutput)
            }
            captureSession.commitConfiguration()
            let queue = DispatchQueue(label: "com.brianadvent.captureQueue")
            dataOutput.setSampleBufferDelegate(self, queue: queue)
        }
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        takePhoto = true
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if takePhoto {
            takePhoto = false
            if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer) {
                let photoVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhotoVC") as! PhotoViewController
                photoVC.takenPhoto = image
               // photoVC.takenPhoto = self.textToImage(drawText: "DebugMe", inImage: photoVC.takenPhoto!, atPoint: CGPoint(x: 100, y: 200))
                DispatchQueue.main.async {
                    self.recognizeMathOperation(for: image)
                    self.present(photoVC, animated: true, completion: { 
                        self.stopCaptureSession()
                    })
                }
            }
        }
    }
    
    
    func getImageFromSampleBuffer (buffer:CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
            }
        }
        return nil
    }
    
    func stopCaptureSession () {
        self.captureSession.stopRunning()
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                self.captureSession.removeInput(input)
            }
        }
    }
    
    func recognizeMathOperation(for image :UIImage){
        MathpixClient.recognize(image: self.imageRotatedByDegrees(oldImage:  image, deg: CGFloat(90.0)), outputFormats: [FormatLatex.simplified, FormatWolfram.on]) { (error, result) in
           // print(result.debugDescription)
            let chars = Array(result.debugDescription)
            self.getTopLeftX(from: chars)
            
        }
    }
    
    func getTopLeftX(from chars: [Character]) {
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
                    print("elemX: \(self.getNumber(from: chars, from: index2+5))")
                    found += 1
                    if found == 2 {
                        break
                    }
                }
                count = 0
            }
        }
    }
    
    func getNumber(from chars: [Character], from index: Int ) -> Int? {
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
