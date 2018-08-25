import UIKit
import MathpixClient
import GPUImage

class PhotoViewController: UIViewController {

    
    
   
    @IBOutlet weak var imageView: UIImageView!
    var takenPhoto: UIImage?
    var canny: CannyEdgeDetection!
    var dilation: Dilation!
    var mathOperations =  Array<MathOperation>()
    var currentIndex: Int!
    var observerOperation: String! {
        didSet {
            self.mathOperations[self.currentIndex].operation = self.observerOperation
            self.observerOperation = ""
            self.correctOperations()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let availableImage = self.takenPhoto {
            self.imageView.image = availableImage
            if let filteredImage = self.filterImage(availableImage) {
                self.segmentMathOperations(for: filteredImage)
                self.correctOperations()
                //self.displayResult()
                
            }
            
        }
    }
    
   
    
    
    func filterImage(_ image: UIImage) -> UIImage? {
        var imageToProcess = image
        self.canny = CannyEdgeDetection()
        imageToProcess = image.filterWithOperation(self.canny)
        /* Try closing or opening or just erosion (for delete border paper) operations
         self.dilation = Dilation()
         imageToProcess = imageToProcess.filterWithOperation(self.dilation)
         self.dilation = Dilation()
         imageToProcess = imageToProcess.filterWithOperation(self.dilation)*/
        self.takenPhoto = imageToProcess
        return imageToProcess
    }
    
    // segmentMathOperations: take the filtered image (canny + dilation) and find the coordinates of each math operation. Then add them in an array.
    func segmentMathOperations(for image: UIImage) {
        if let testImg = self.processPixels(in: image) {
            self.takenPhoto = testImg
        }
    }
    
    // correctOperations: for each math operation in array, take its coordinates, crop the operation and send it to MathPix. Then take MathPix result and, through substrings methods, compute the correctess. Then modify "isCorrect" instance variable for each math operations in array.
    func correctOperations() {
        for index in self.mathOperations.indices {
            if self.mathOperations[index].operation == "undefined" {
                self.currentIndex = index
                let croppedImage = self.cropImage(for: self.imageView.image!, with: CGRect(x: self.mathOperations[index].x, y: self.mathOperations[index].y, width: self.mathOperations[index].width, height: self.mathOperations[index].height))
            
                MathpixClient.recognize(image: self.imageRotatedByDegrees(oldImage:  croppedImage, deg: CGFloat(90.0)), outputFormats: [FormatLatex.simplified, FormatWolfram.on]) { (error, result) in
                    self.observerOperation = String(result.debugDescription)
                }
                break
            }
        }
    }
    
    
    // displayResult: depending on type of operation, compute the coordinate where to display the sign of correctness or not.
    func displayResult() -> UIImage? {
        return nil
    }
    
    
    @IBAction func savePhoto(_ sender: Any) {
        for index in self.mathOperations.indices {
            print("----------------------------------")
            print(self.mathOperations[index].operation)
            print("----------------------------------")
        }
        guard let imageToSave = self.takenPhoto else {
            return
        }
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func recognizeMathOperation(for image :UIImage) -> String {
        MathpixClient.recognize(image: self.imageRotatedByDegrees(oldImage:  image, deg: CGFloat(90.0)), outputFormats: [FormatLatex.simplified, FormatWolfram.on]) { (error, result) in
            //let chars = Array(result.debugDescription)
            /*if let coordinates = self.getCoordinates(from: chars) {
             //here is commented beacause self.imageView as been converted into RenderView for testing Canny edge detection
             //self.imageView.image = self.textToImage(drawText: ".", inImage: availableImage, atPoint: CGPoint(x: coordinates[0], y: coordinates[1]))
             // let toonFilter = CannyEdgeDetection()
             //let filteredImage = self.imageView.image?.filterWithOperation(toonFilter)
             // self.imageView.image? = self.imageView.image!.filterWithOperation(toonFilter)
             } else {
             self.dismiss(animated: true, completion: nil)
             }*/
            return result.debugDescription
        }
        return "nono"
    }
    
    func processPixels(in image: UIImage) -> UIImage? {
        guard let inputCGImage = image.cgImage else {
            print("unable to get cgImage")
            return nil
        }
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = inputCGImage.width
        let height           = inputCGImage.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = RGBA32.bitmapInfo
        
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            print("unable to create context")
            return nil
        }
        context.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let buffer = context.data else {
            print("unable to get context data")
            return nil
        }
        
        let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: width * height)
        
        
        let foregrounds = self.calculateHorizontalForeground(from: pixelBuffer, withWidth: width, andHeight: height)
        if let sums = self.calculateSum(from: foregrounds!) {
            guard let sums3 = self.fireHorizontalGrid(for: sums, in: pixelBuffer, withWidth: width, andHeight: height) else { return nil }
            self.fireVerticalGrid(for: sums3, in: pixelBuffer, withWidth: width, andHeight: height)
        }
        let outputCGImage = context.makeImage()!
        let outputImage = UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
        
        //test cropping single operations
        for index in self.mathOperations.indices {
            let croppedImage = self.cropImage(for: self.imageView.image!, with: CGRect(x: self.mathOperations[index].x, y: self.mathOperations[index].y, width: self.mathOperations[index].width, height: self.mathOperations[index].height))
            UIImageWriteToSavedPhotosAlbum(self.imageRotatedByDegrees(oldImage: croppedImage, deg: CGFloat(90.0)), nil, nil, nil)
            dismiss(animated: true, completion: nil)
        }
        return outputImage
    }
    
    func calculateHorizontalForeground(from pixelBuffer:  UnsafeMutablePointer<PhotoViewController.RGBA32>, withWidth width: Int, andHeight height: Int) -> Array<Int>? {
        var foregrounds: Array<Int> = []
        var foregroundAmount = 0
        for row in 0 ..< Int(height) {
            for column in 0 ..< Int(width) {
                let offset = row * width + column
                if pixelBuffer[offset] == .white {
                    foregroundAmount += 1
                }
            }
            foregrounds.append(foregroundAmount)
            foregroundAmount = 0
        }
        //number whose values is different than 0, became 1
        for index in foregrounds.indices {
            if foregrounds[index] != 0 {
                foregrounds[index] = 1
            }
        }
        return foregrounds
    }
    
    
    func calculateVerticalForeground(from pixelBuffer:  UnsafeMutablePointer<PhotoViewController.RGBA32>, withWidth width: Int, from start: Int, to stop: Int) -> Array<Int>? {
        var foregrounds2: Array<Int> = []
        var foregroundAmount = 0
        for col in 0 ..< Int(width) {
            for row in (start ..< stop).reversed() {
                let offset = row * width + col
                if pixelBuffer[offset] == .white {
                    foregroundAmount += 1
                }
            }
            foregrounds2.append(foregroundAmount)
            foregroundAmount = 0
        }
        //number whose values is different than 0, became 1
        for index in foregrounds2.indices {
            if foregrounds2[index] != 0 {
                foregrounds2[index] = 1
            }
        }
        return foregrounds2
    }
    
    //calculate sums array -> [0, 0, 1, 1, 0] became -> [(2, 0), (2, 1), (1, 0)]
    func calculateSum(from foregrounds: Array<Int>) -> Array<CGPoint>? {
        var sums : Array<CGPoint> = []
        var sumIndex = 0
        var cons = foregrounds[0]
        if cons == 0 {
            sums.append(CGPoint(x: 1, y: 0))
        } else {
            sums.append(CGPoint(x: 1, y: 1))
        }
        
        for index in 1..<foregrounds.count {
            if foregrounds[index] == cons {
                sums[sumIndex].x += 1
            } else {
                sumIndex += 1
                if foregrounds[index] == 0 {
                    sums.append(CGPoint(x: 1, y: 0))
                } else {
                    sums.append(CGPoint(x: 1, y: 1))
                }
                cons = foregrounds[index]
            }
        }
        if sums.count <= 1 { // means all white paper or all black paper
            //TODO: to handle this case. Make a pop-up appear saying "take another photo"
            return nil
        } else {
            return sums
        }
    }
    
    func deleteWhiteNoise(for arrayOfPoints: Array<CGPoint>, withThreshold threshold: Int) -> Array<CGPoint>? {
        var sums = arrayOfPoints
        for index in 1..<sums.count - 1 {
            if sums[index].y == 1.0 {
                if Int(sums[index].x) <= threshold { //threshold for white noise
                    if Int(sums[index - 1].x) > threshold || Int(sums[index + 1].x) > threshold { //threshold for white noise
                        sums[index].y = 0
                    }
                }
            }
        }
        //check if first element is a white-noise. Noise for first element -> 5
        if sums[0].y == 1.0, sums[0].x < 5 {
            sums[0].y = 0.0
        }
        return sums
    }
    
    //merge consecutive equals numbers
    func mergeConsecutiveEqualsNumbers(in sumsWithoutNoise: Array<CGPoint>) -> Array<CGPoint>? {
        var sums2 : Array<CGPoint> = []
        var current = 0
        var cons2 = sumsWithoutNoise[0].y
        sums2.append(sumsWithoutNoise[0])
        
        for index in 1..<sumsWithoutNoise.count {
            if sumsWithoutNoise[index].y != cons2 {
                cons2 = sumsWithoutNoise[index].y
                sums2.append(sumsWithoutNoise[index])
                current += 1
            } else {
                sums2[current].x = sums2[current].x + sumsWithoutNoise[index].x
                
            }
        }
        return sums2
    }
    
    
    func deleteBlackNoise(for sums: Array<CGPoint>, withBlackNoise blackNoise: Int, andWhiteNoise whiteNoise: Int, noiseForFirstElement first: Int) -> Array<CGPoint>? {
        var sums2 = sums
        if sums2.count > 1 {
            //delete black noise which elapes between two big white cluster
            for index in 1..<sums2.count - 1 {
                if sums2[index].y == 0.0 {
                    if Int(sums2[index].x) <= blackNoise { //threshold for black noise
                        if Int(sums2[index - 1].x) >= whiteNoise || Int(sums2[index + 1].x) >= whiteNoise { //threshold for black noise
                            sums2[index].y = 1.0
                        }
                    }
                }
            }
            //check if first element is a zero-noise. Noise for first element -> first
            if sums2[0].y == 0.0, Int(sums2[0].x) <= first {
                sums2[0].y = 1.0
            }
        }
        return sums2
    }
    
    func drawHorizontalLines(for sums3: Array<CGPoint>, in pixelBuffer:  UnsafeMutablePointer<PhotoViewController.RGBA32>, withWidth width: Int, andHeight height: Int) {
        var startDrawing = 0
        for index in sums3.indices {
            if sums3[index].y == 0 {
                for row in startDrawing ..< (Int(sums3[index].x) + startDrawing){
                    for column in 0 ..< Int(width) {
                        let offset = row * width + column
                        pixelBuffer[offset] = .red
                    }
                    
                }
            }
            startDrawing = startDrawing + Int(sums3[index].x)
        }
    }
    
    func drawVerticalLines(for sums3: Array<CGPoint>, in pixelBuffer:  UnsafeMutablePointer<PhotoViewController.RGBA32>, withWidth width: Int, from start: Int, to stop: Int) {
        var startDrawing = 0
        for index in sums3.indices {
            if sums3[index].y == 0 {
                for col in startDrawing ..< (Int(sums3[index].x) + startDrawing){
                    for row in (start ..< stop).reversed() {
                        let offset = row * width + col
                        pixelBuffer[offset] = .blue
                    }
                    
                }
            } else {
                //width of white block operations
                //print("width white: \(Int(sums3[index].x))")
                //height of white block operations
                //print("height: \(stop - start)")
                //x coordinate of white block operation
                //print("x coordinate: \(startDrawing)")
                //y coordinate of white block operation
                //print("y coordinate: \(start)")
                
                let mathOp = MathOperation.init(operation: "undefined", width: Int(sums3[index].x), height: stop - start, x: startDrawing, y: start, isCorrect: false)
                self.mathOperations.append(mathOp)
                
                
            }
            startDrawing = startDrawing + Int(sums3[index].x)
        }
    }
    
    func fireHorizontalGrid(for sums: Array<CGPoint>, in pixelBuffer:  UnsafeMutablePointer<PhotoViewController.RGBA32>, withWidth width: Int, andHeight height: Int) -> Array<CGPoint>? {
        guard let sumsWithoutWhiteNoise = self.deleteWhiteNoise(for: sums, withThreshold: 10) else { return nil}
        guard let sums2 = self.mergeConsecutiveEqualsNumbers(in: sumsWithoutWhiteNoise) else { return nil}
        guard let sumsWithoutBlackNoise = self.deleteBlackNoise(for: sums2, withBlackNoise: 10, andWhiteNoise: 10, noiseForFirstElement: 5) else { return nil }
        let sums3 = self.mergeConsecutiveEqualsNumbers(in: sumsWithoutBlackNoise)
        self.drawHorizontalLines(for: sums3!, in: pixelBuffer, withWidth: width, andHeight: height)
        return sums3
    }
    
    
    
    func fireVerticalGrid(for sums3: Array<CGPoint>, in pixelBuffer: UnsafeMutablePointer<PhotoViewController.RGBA32>, withWidth width: Int, andHeight height: Int) {
        var start = 0
        var stop = 0
        for index in 0 ..< sums3.count {
            if sums3[index].y == 1.0 && start <= height {
                stop = start + Int(sums3[index].x)
                let foregrounds2 = self.calculateVerticalForeground(from: pixelBuffer, withWidth: width, from: start, to: stop)
                if let sums = self.calculateSum(from: foregrounds2!) {
                    guard let sumsWithoutWhiteNoise = self.deleteWhiteNoise(for: sums, withThreshold: 10) else { return }
                    guard let sums2 = self.mergeConsecutiveEqualsNumbers(in: sumsWithoutWhiteNoise) else { return }
                    guard let sumsWithoutBlackNoise = self.deleteBlackNoise(for: sums2, withBlackNoise: 25, andWhiteNoise: 10, noiseForFirstElement: 5) else { return }
                    guard let sums32 = self.mergeConsecutiveEqualsNumbers(in: sumsWithoutBlackNoise) else { return}
                    self.drawVerticalLines(for: sums32, in: pixelBuffer, withWidth: width, from: start, to: stop)
                }
            }
            start = start + Int(sums3[index].x)
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    struct RGBA32: Equatable {
        private var color: UInt32
        
        var redComponent: UInt8 {
            return UInt8((color >> 24) & 255)
        }
        
        var greenComponent: UInt8 {
            return UInt8((color >> 16) & 255)
        }
        
        var blueComponent: UInt8 {
            return UInt8((color >> 8) & 255)
        }
        
        var alphaComponent: UInt8 {
            return UInt8((color >> 0) & 255)
        }
        
        init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
            let red   = UInt32(red)
            let green = UInt32(green)
            let blue  = UInt32(blue)
            let alpha = UInt32(alpha)
            color = (red << 24) | (green << 16) | (blue << 8) | (alpha << 0)
        }
        
        static let red     = RGBA32(red: 255, green: 0,   blue: 0,   alpha: 255)
        static let green   = RGBA32(red: 0,   green: 255, blue: 0,   alpha: 255)
        static let blue    = RGBA32(red: 0,   green: 0,   blue: 255, alpha: 255)
        static let white   = RGBA32(red: 255, green: 255, blue: 255, alpha: 255)
        static let black   = RGBA32(red: 0,   green: 0,   blue: 0,   alpha: 255)
        static let magenta = RGBA32(red: 255, green: 0,   blue: 255, alpha: 255)
        static let yellow  = RGBA32(red: 255, green: 255, blue: 0,   alpha: 255)
        static let cyan    = RGBA32(red: 0,   green: 255, blue: 255, alpha: 255)
        
        static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        
        static func ==(lhs: RGBA32, rhs: RGBA32) -> Bool {
            return lhs.color == rhs.color
        }
    }
    
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
    
    func cropImage(for image: UIImage, with bounds: CGRect) -> UIImage {
        let cgImage = image.cgImage?.cropping(to: bounds)
        let image = UIImage(cgImage: cgImage!)
        return image
    }
    
}

public class CannyEdgeDetection: OperationGroup {
    public var blurRadiusInPixels:Float = 2.0 { didSet { gaussianBlur.blurRadiusInPixels = blurRadiusInPixels } }
    public var upperThreshold:Float = 0.4 { didSet { directionalNonMaximumSuppression.uniformSettings["upperThreshold"] = upperThreshold } }
    public var lowerThreshold:Float = 0.1 { didSet { directionalNonMaximumSuppression.uniformSettings["lowerThreshold"] = lowerThreshold } }
    
    let luminance = Luminance()
    let gaussianBlur = SingleComponentGaussianBlur()
    let directionalSobel = TextureSamplingOperation(fragmentShader:DirectionalSobelEdgeDetectionFragmentShader)
    let directionalNonMaximumSuppression = TextureSamplingOperation(vertexShader:OneInputVertexShader, fragmentShader:DirectionalNonMaximumSuppressionFragmentShader)
    let weakPixelInclusion = TextureSamplingOperation(fragmentShader:WeakPixelInclusionFragmentShader)
    
    public override init() {
        super.init()
        
        ({blurRadiusInPixels = 2.0})()
        ({upperThreshold = 0.4})()
        ({lowerThreshold = 0.1})()
        
        self.configureGroup{input, output in
            input --> self.luminance --> self.gaussianBlur --> self.directionalSobel --> self.directionalNonMaximumSuppression --> self.weakPixelInclusion --> output
        }
    }
}

class CustomLabel: UILabel {
    
    override var text: String? {
        didSet {
            if let text = text {
                print("changed")
            }
        }
    }
}
