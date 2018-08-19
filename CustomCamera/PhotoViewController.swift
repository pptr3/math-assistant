//
//  PhotoViewController.swift
//  CustomCamera
//
//  Created by Brian Advent on 24/01/2017.
//  Copyright © 2017 Brian Advent. All rights reserved.
//

import UIKit
import MathpixClient
import GPUImage

class PhotoViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    var takenPhoto: UIImage?
    var canny: CannyEdgeDetection!
    var dilation: Dilation!
   

    override func viewDidLoad() {
        super.viewDidLoad()
        if let availableImage = self.takenPhoto {
            self.imageView.image = availableImage
            if let filteredImage = self.filterImage(availableImage) {
                self.segmentMathOperations(for: filteredImage)
                //self.correctOperations()
                //self.displayResult()
            }
        }
    }
    
    func filterImage(_ image: UIImage) -> UIImage? {
        var imageToProcess = image
        self.canny = CannyEdgeDetection()
        imageToProcess = image.filterWithOperation(self.canny)
      /*  self.dilation = Dilation()
        imageToProcess = imageToProcess.filterWithOperation(self.dilation)
        self.dilation = Dilation()
        imageToProcess = imageToProcess.filterWithOperation(self.dilation)
    */  self.takenPhoto = imageToProcess
        return imageToProcess
    }
    // segmentMathOperations: take the filtered image (canny + dilation) and find the coordinates of each math operation. Then add them in an array.
    func segmentMathOperations(for image: UIImage) {
        let img =  self.imageRotatedByDegrees(oldImage: image, deg: CGFloat(90.0))
        if let testImg = self.processPixels(in: img) {
            self.takenPhoto = testImg
        }
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
        //calculate foregrounds array
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
        //number whose values is different than 0, became 1. (note the noise of image could cause some 1 or 2 or other values (to test), should be converted to 0 instead of 1) -- smooth operation
        for index in foregrounds.indices {
            if foregrounds[index] != 0 {
               foregrounds[index] = 1
            }
        }
        
        
        //calculate sums array -> [0, 0, 1, 1, 0] became -> [(2, 0), (2, 1), (1, 0)]
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
        }
        //delete noise
        for index in 1..<sums.count - 1 { // to test with "-1"
            if sums[index].y == 1.0 {
                if Int(sums[index].x) < 10 { //threshold for white noise
                    if sums[index - 1].x >= 10 || sums[index + 1].x >= 10 { //threshold for white noise
                        sums[index].y = 0
                    }
                }
            }
        }
        //check if first element is a white-noise. Noise for first element -> 5
        if sums[0].y == 1.0, sums[0].x < 5 {
            sums[0].y = 0.0
        }
        
        
        //merge consecutive zeros
        var sums2 : Array<CGPoint> = []
        var current = 0
        var cons2 = sums[0].y
        sums2.append(sums[0])
        
        for index in 1..<sums.count {
            if sums[index].y != cons2 {
                cons2 = sums[index].y
                sums2.append(sums[index])
                current += 1
            } else {
                sums2[current].x = sums2[current].x + sums[index].x
                
            }
        }

        if sums2.count > 1 {
            //delete black noise which elapes between two big white cluster
            for index in 1..<sums2.count - 1 {
                if sums2[index].y == 0.0 {
                    if Int(sums2[index].x) <= 20 { //threshold for black noise
                        if sums2[index - 1].x >= 10 || sums2[index + 1].x >= 10 { //threshold for black noise
                            sums2[index].y = 1.0
                        }
                        
                    }
                }
            }
            //check if first element is a zero-noise. Noise for first element -> 5
            if sums2[0].y == 0.0, sums2[0].x < 5 {
                sums2[0].y = 1.0
            }
        }
        
        //merge consecutive ones
        var sums3 : Array<CGPoint> = []
        var current2 = 0
        var cons3 = sums2[0].y
        sums3.append(sums2[0])
        
        for index in 1..<sums2.count {
            if sums2[index].y != cons3 {
                cons3 = sums2[index].y
                sums3.append(sums2[index])
                current2 += 1
            } else {
                sums3[current2].x = sums3[current2].x + sums2[index].x
                
            }
        }
        print(sums3)
        
        //draw zeros
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
        let outputCGImage = context.makeImage()!
        let outputImage = UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
        //TODO: need to coun how many pixels corresponds 0.5 cm (square of paper distance) and set the threshold accordly. Need also to test a full page of operations or in others orders.
        return outputImage
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
    
    
    
    // correctOperations: for each math operation in array, take its coordinates, crop the operation and send it to MathPix. Then take MathPix result and, through substrings methods, compute the correctess. Then modify "isCorrect" instance variable for each math operations in array.
    func correctOperations() {
        
    }
    // displayResult: depending on type of operation, compute the coordinate where to display the sign of correctness or not.
    func displayResult() -> UIImage? {
        return nil
    }
    
    @IBAction func savePhoto(_ sender: Any) {
        guard let imageToSave = self.takenPhoto else {
            return
        }
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
/*
    func recognizeMathOperation(for image :UIImage){
        MathpixClient.recognize(image: self.imageRotatedByDegrees(oldImage:  image, deg: CGFloat(90.0)), outputFormats: [FormatLatex.simplified, FormatWolfram.on]) { (error, result) in
            let chars = Array(result.debugDescription)
            if let coordinates = self.getCoordinates(from: chars) {
                //here is commented beacause self.imageView as been converted into RenderView for testing Canny edge detection
                //self.imageView.image = self.textToImage(drawText: ".", inImage: availableImage, atPoint: CGPoint(x: coordinates[0], y: coordinates[1]))
                // let toonFilter = CannyEdgeDetection()
                //let filteredImage = self.imageView.image?.filterWithOperation(toonFilter)
                // self.imageView.image? = self.imageView.image!.filterWithOperation(toonFilter)
            } else {
                self.dismiss(animated: true, completion: nil)
            }

        }
    }*/
    
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
