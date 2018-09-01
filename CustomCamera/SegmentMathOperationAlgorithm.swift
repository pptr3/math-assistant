//
//  SegmentMathOperationAlgorithm.swift
//  CustomCamera
//
//  Created by Valerio Potrimba on 01/09/2018.
//  Copyright © 2018 Brian Advent. All rights reserved.
//

import UIKit
import MathpixClient
import GPUImage

class SegmentMathOperationAlgorithm {
    
   
    var imageView: UIImage?
    var takenPhoto: UIImage?
    var originalImage: UIImage?
    var filterImage: UIImage?
    var canny: CannyEdgeDetection!
    var dilation: Dilation!
    var bright: BrightnessAdjustment!
    var blackNoiseValueForVeticalGrid = 45
    var blackNoiseValueForHorizontalGrid = 20
    var mathOperations =  Array<MathOperation>()
    var currentIndex: Int!
    var rebootVar = false
    var howManyOperationsHasBeenProcessed = 0
    var observerOperation: String! {
        didSet {
            if !self.rebootVar {
                self.mathOperations[self.currentIndex].operation = self.observerOperation
                self.observerOperation = ""
                if self.howManyOperationsHasBeenProcessed < self.mathOperations.count {
                    self.setResultFromMathpix()
                } else if self.howManyOperationsHasBeenProcessed == self.mathOperations.count {
                    self.correctOperations()
                }
            }
        }
    }
    
    init(for image: UIImage, withVertical horizontal: Int, withHorizontal vertical: Int) {
        self.takenPhoto = image
        self.blackNoiseValueForHorizontalGrid = horizontal
        self.blackNoiseValueForVeticalGrid = vertical
    }
    
    func run() {
        if let availableImage = self.takenPhoto {
            
            self.originalImage = availableImage
            self.brightnessAdjustmentFilter()
            //    self.imageView.image = availableImage
            if let cannyFilteredImage = self.cannyEdgeDetectionFilter(availableImage) {
                self.segmentMathOperations(for: self.imageRotatedByDegrees(oldImage: cannyFilteredImage, deg: CGFloat(90.0)))
                self.setResultFromMathpix()
                UIImageWriteToSavedPhotosAlbum(self.filterImage!, nil, nil, nil)
            }
        }
    }
    
    private func reboot() {
        self.rebootVar = true
        self.observerOperation = ""
        self.howManyOperationsHasBeenProcessed = 0
        self.mathOperations =  Array<MathOperation>()
        self.rebootVar = false
       
    }
    
    private func brightnessAdjustmentFilter() {
        var imageToProcess = self.originalImage!
        self.bright = BrightnessAdjustment()
        imageToProcess = self.originalImage!.filterWithOperation(self.bright)
        self.originalImage! = self.imageRotatedByDegrees(oldImage: imageToProcess, deg: CGFloat(90.0))
    }
    
    private func cannyEdgeDetectionFilter(_ image: UIImage) -> UIImage? {
        var imageToProcess = image
        self.canny = CannyEdgeDetection()
        imageToProcess = image.filterWithOperation(self.canny)
        /* Try closing or opening or just erosion (for delete border paper) operations. Test bluring
         self.dilation = Dilation()
         imageToProcess = imageToProcess.filterWithOperation(self.dilation)
         self.dilation = Dilation()
         imageToProcess = imageToProcess.filterWithOperation(self.dilation)*/
        //self.takenPhoto = imageToProcess
        return imageToProcess
    }
    
    private func segmentMathOperations(for image: UIImage) {
        if let processedImage = self.processPixels(in: image) {
            self.filterImage = processedImage
        }
    }
    
    private func setResultFromMathpix() {
        for index in self.mathOperations.indices {
            if self.mathOperations[index].operation == "undefined" {
                self.howManyOperationsHasBeenProcessed += 1
                self.currentIndex = index
                let croppedImage = self.cropImage(image: self.originalImage!, cropRect: CGRect(x: self.mathOperations[index].x, y: self.mathOperations[index].y, width: self.mathOperations[index].width, height: self.mathOperations[index].height))
                
                MathpixClient.recognize(image: croppedImage!, outputFormats: [FormatLatex.simplified, FormatWolfram.on]) { (error, result) in
                    self.observerOperation = String(result.debugDescription)
                }
                break
            }
        }
    }
    
    
    private func correctOperations() {
        self.extractOperations()
        //delete nil values in mathOperations
        
        var saveMathOperations = self.mathOperations
        saveMathOperations.removeAll()
        for index in self.mathOperations.indices {
            if self.mathOperations[index].operation != nil {
                saveMathOperations.append(self.mathOperations[index])
            }
        }
        self.mathOperations = saveMathOperations
        
        for index in self.mathOperations.indices {
            if let stringWithMathematicalOperation = self.getOperation(from: Array(self.mathOperations[index].operation!)) {
                print(stringWithMathematicalOperation)
                let exp: NSExpression = NSExpression(format: stringWithMathematicalOperation.first!)
                let result: Double = exp.expressionValue(with: nil, context: nil) as! Double
                print(result)
                print(Double(stringWithMathematicalOperation[1])!)
                if result == Double(stringWithMathematicalOperation[1])! { //bug == with Double
                    self.mathOperations[index].isCorrect = true
                } else {
                    self.mathOperations[index].isCorrect = false
                }
            }
        }
        self.displayResult()
    }
    
    
    
    private func extractOperations() {
        for index in self.mathOperations.indices {
            let chars = Array(self.mathOperations[index].operation!)
            if let replacedOperation = self.getWorlframOperation(from: chars) {
                self.mathOperations[index].operation = replacedOperation
            } else {
                self.mathOperations[index].operation = nil
            }
        }
    }
    
    private func getOperation(from chars: [Character]) -> [String]? {
        var operantionAndResult = [String]()
        var operation = ""
        var flag = false
        
        for index in chars.indices {
            if chars[index] != "=" && flag == false {
                operation.append(chars[index])
            } else if chars[index] == "=" {
                flag = true
                operantionAndResult.append(operation)
                operation = ""
            } else {
                operation.append(chars[index])
            }
        }
        operantionAndResult.append(operation)
        return operantionAndResult
    }
    
    private func displayResult() {
        var img = self.originalImage!
        for index in self.mathOperations.indices {
            if self.mathOperations[index].isCorrect {
                img = self.textToImage(drawText: "✅", inImage: img, atPoint: CGPoint(x: self.mathOperations[index].x, y: self.mathOperations[index].y))
            } else{
                img = self.textToImage(drawText: "❌", inImage: img, atPoint: CGPoint(x: self.mathOperations[index].x, y: self.mathOperations[index].y))
            }
        }
        self.imageView = img
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
    }
    
    private func getWorlframOperation(from chars: [Character]) -> String? {
        let topLeftX = Array("wolfram")
        var topIndex = 0
        var count = 0
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
                    if let wolframOperation = self.getNumber(from: chars, from: index2+3) { //"+3" is where the result starts
                        return wolframOperation
                    }
                }
                count = 0
            }
        }
        return nil
    }
    
    private func getNumber(from chars: [Character], from index: Int ) -> String? {
        if chars[index] != "\"" {
            return nil
        }
        var myStringNumber = ""
        var i = index + 1
        for _ in chars.indices {
            if i >= chars.count - 1 {
                return nil
            }
            if chars[i] != "\"" {
                myStringNumber.append(chars[i])
                i += 1
            } else {
                break
            }
        }
        if myStringNumber.contains("div") {
            myStringNumber = myStringNumber.replacingOccurrences(of: "div", with: "/")
            myStringNumber = myStringNumber.replacingOccurrences(of: "\\", with: "")
            myStringNumber = myStringNumber.replacingOccurrences(of: "\\", with: "")
        }
        
        if myStringNumber.contains("times") {
            myStringNumber = myStringNumber.replacingOccurrences(of: "times", with: "*")
            myStringNumber = myStringNumber.replacingOccurrences(of: "\\", with: "")
            myStringNumber = myStringNumber.replacingOccurrences(of: "\\", with: "")
        }
        
        if myStringNumber.contains("x") {
            myStringNumber = myStringNumber.replacingOccurrences(of: "x", with: "*")
        }
        
        //check if string operation contains alphabet letters.
        if myStringNumber.containsIgnoringCase("y") || myStringNumber.containsIgnoringCase("a") || myStringNumber.containsIgnoringCase("t") {
            return nil
        }
        
        if Array(myStringNumber).first == "{" { //means that is coloumn operation
            myStringNumber = myStringNumber.replacingOccurrences(of: " ", with: "")
            myStringNumber = myStringNumber.replacingOccurrences(of: "{", with: "")
            
            //handle this case: "{{ 127 /},{ 4/408} }"; or "{{ 127 *},{ 4/408} }";
            if myStringNumber.contains("/") {
                var charMyStringNumber = Array(myStringNumber)
                var counterForCurlyBrackets = 0
                for index in charMyStringNumber.indices {
                    if charMyStringNumber[index] == "}" {
                        counterForCurlyBrackets += 1
                    }
                    if charMyStringNumber[index] == "/" && counterForCurlyBrackets > 0 {
                        charMyStringNumber[index] = "="
                        myStringNumber = String(charMyStringNumber)
                        break
                    }
                }
            }
            
            
            //check if equals sign is present. If not, add it.
            if !myStringNumber.contains("=") {
                var charMyStringNumber = Array(myStringNumber)
                var counterForCurlyBrackets = 0
                for index in charMyStringNumber.indices {
                    if charMyStringNumber[index] == "}" && counterForCurlyBrackets < 2 {
                        counterForCurlyBrackets += 1
                    } else if counterForCurlyBrackets == 2 {
                        charMyStringNumber[index] = "="
                        myStringNumber = String(charMyStringNumber)
                        break
                    }
                }
            }
            
            //check if at least one operator is present. If not, means that the operator is a "-",.
            if !myStringNumber.containsIgnoringCase("x") && !myStringNumber.containsIgnoringCase("+") && !myStringNumber.containsIgnoringCase("-") && !myStringNumber.containsIgnoringCase("/") && !myStringNumber.containsIgnoringCase("*") {
                var charMyStringNumber = Array(myStringNumber)
                for index in charMyStringNumber.indices {
                    if charMyStringNumber[index] == "}" {
                        if charMyStringNumber[index - 1] == "=" { //this is to avoid case like this: "{{ 100 =},{ 50 =},{ 50 }}";
                            charMyStringNumber[index - 1] = "-"
                            myStringNumber = String(charMyStringNumber)
                            break
                        } else {
                            charMyStringNumber[index] = "-"
                            myStringNumber = String(charMyStringNumber)
                            break
                        }
                    }
                }
            }
            
            if myStringNumber.contains("(") {
                myStringNumber = myStringNumber.replacingOccurrences(of: "(", with: "")
            }
            
            if myStringNumber.contains(")") {
                myStringNumber = myStringNumber.replacingOccurrences(of: ")", with: "")
            }
            
            myStringNumber = myStringNumber.replacingOccurrences(of: "}", with: "")
            myStringNumber = myStringNumber.replacingOccurrences(of: ",", with: "")
        }
        
        
        if checkIfOperationIsWellFormatted(for: myStringNumber.replacingOccurrences(of: " ", with: "")) {
            myStringNumber = myStringNumber.replacingOccurrences(of: " ", with: "")
            return myStringNumber
        }
        return nil
    }
    
    
    private func checkIfOperationIsWellFormatted(for operation: String) -> Bool {
        if operation.isEmpty || operation.count < 5 {
            return false
        }
        
        var charsOperation = Array(operation)
        
        if !String(charsOperation[0]).isNumber || !String(charsOperation[charsOperation.count - 1]).isNumber {
            return false
        }
        var equals = false
        var operators = false
        for index in 1..<operation.count - 1 {
            //TODO: check if there are two operators or equals in a row. Check if each operator/equals has on left and right a number.
            
            if !operators, (charsOperation[index] == "+" || charsOperation[index] == "-" || charsOperation[index] == "*" || charsOperation[index] == "/") {
                operators = true
            }
            
            if !equals, charsOperation[index] == "=" {
                equals = true
            }
        }
        return equals && operators
    }
    
    
    private func processPixels(in image: UIImage) -> UIImage? {
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
        return outputImage
    }
    
    private func calculateHorizontalForeground(from pixelBuffer:  UnsafeMutablePointer<SegmentMathOperationAlgorithm.RGBA32>, withWidth width: Int, andHeight height: Int) -> Array<Int>? {
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
    
    
    private func calculateVerticalForeground(from pixelBuffer:  UnsafeMutablePointer<SegmentMathOperationAlgorithm.RGBA32>, withWidth width: Int, from start: Int, to stop: Int) -> Array<Int>? {
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
    private func calculateSum(from foregrounds: Array<Int>) -> Array<CGPoint>? {
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
    
    private func deleteWhiteNoise(for arrayOfPoints: Array<CGPoint>, withThreshold threshold: Int, leftAndRightBlackValues leftAndRight: Int) -> Array<CGPoint>? {
        var sums = arrayOfPoints
        for index in 1..<sums.count - 1 {
            if sums[index].y == 1.0 {
                if Int(sums[index].x) <= threshold { //threshold for white noise
                    if Int(sums[index - 1].x) > leftAndRight || Int(sums[index + 1].x) > leftAndRight { //threshold for white noise
                        sums[index].y = 0
                    }
                }
            }
        }
        //check if first element is a white-noise. Noise for first element -> 5
        if sums[0].y == 1.0, sums[0].x < 5 { //TODO: this 5 should be in the signature ad "first element noise"
            sums[0].y = 0.0
        }
        return sums
    }
    
    //merge consecutive equals numbers
    private func mergeConsecutiveEqualsNumbers(in sumsWithoutNoise: Array<CGPoint>) -> Array<CGPoint>? {
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
    
    
    private func deleteBlackNoise(for sums: Array<CGPoint>, withBlackNoise blackNoise: Int, andWhiteNoise whiteNoise: Int, noiseForFirstElement first: Int) -> Array<CGPoint>? {
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
    
    private func fireHorizontalGrid(for sums: Array<CGPoint>, in pixelBuffer:  UnsafeMutablePointer<SegmentMathOperationAlgorithm.RGBA32>, withWidth width: Int, andHeight height: Int) -> Array<CGPoint>? {
        guard let sumsWithoutWhiteNoise = self.deleteWhiteNoise(for: sums, withThreshold: 10, leftAndRightBlackValues: 10) else { return nil}
        guard let sums2 = self.mergeConsecutiveEqualsNumbers(in: sumsWithoutWhiteNoise) else { return nil}
        guard let sumsWithoutBlackNoise = self.deleteBlackNoise(for: sums2, withBlackNoise: self.blackNoiseValueForHorizontalGrid, andWhiteNoise: 10, noiseForFirstElement: 5) else { return nil }
        let sums3 = self.mergeConsecutiveEqualsNumbers(in: sumsWithoutBlackNoise)
        self.drawHorizontalLines(for: sums3!, in: pixelBuffer, withWidth: width, andHeight: height)
        return sums3
    }
    
    
    
    private func fireVerticalGrid(for sums3: Array<CGPoint>, in pixelBuffer: UnsafeMutablePointer<SegmentMathOperationAlgorithm.RGBA32>, withWidth width: Int, andHeight height: Int) {
        var start = 0
        var stop = 0
        for index in 0 ..< sums3.count {
            if sums3[index].y == 1.0 && start <= height {
                stop = start + Int(sums3[index].x)
                let foregrounds2 = self.calculateVerticalForeground(from: pixelBuffer, withWidth: width, from: start, to: stop)
                if let sums = self.calculateSum(from: foregrounds2!) {
                    guard let sumsWithoutWhiteNoise = self.deleteWhiteNoise(for: sums, withThreshold: 5, leftAndRightBlackValues: 15) else { return }
                    guard let sums2 = self.mergeConsecutiveEqualsNumbers(in: sumsWithoutWhiteNoise) else { return }
                    guard let sumsWithoutBlackNoise = self.deleteBlackNoise(for: sums2, withBlackNoise: self.blackNoiseValueForVeticalGrid, andWhiteNoise: 5, noiseForFirstElement: 5) else { return }
                    guard let sums32 = self.mergeConsecutiveEqualsNumbers(in: sumsWithoutBlackNoise) else { return}
                    self.drawVerticalLines(for: sums32, in: pixelBuffer, withWidth: width, from: start, to: stop)
                }
            }
            start = start + Int(sums3[index].x)
        }
    }
    
    private func drawHorizontalLines(for sums3: Array<CGPoint>, in pixelBuffer:  UnsafeMutablePointer<SegmentMathOperationAlgorithm.RGBA32>, withWidth width: Int, andHeight height: Int) {
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
    
    private func drawVerticalLines(for sums3: Array<CGPoint>, in pixelBuffer:  UnsafeMutablePointer<SegmentMathOperationAlgorithm.RGBA32>, withWidth width: Int, from start: Int, to stop: Int) {
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
                let mathOp = MathOperation.init(operation: "undefined", width: Int(sums3[index].x), height: stop - start, x: startDrawing, y: start, isCorrect: false)
                self.mathOperations.append(mathOp)
                
                
            }
            startDrawing = startDrawing + Int(sums3[index].x)
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
    
    
    private func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
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
    
    private func textToImage(drawText text: NSString, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        let textColor = UIColor.blue
        let textFont = UIFont(name: "Helvetica Bold", size: 30)!
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
    
    private func cropImage(image:UIImage, cropRect:CGRect) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(cropRect.size, false, image.scale)
        let origin = CGPoint(x: cropRect.origin.x * CGFloat(-1), y: cropRect.origin.y * CGFloat(-1))
        image.draw(at: origin)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        return result
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

public class BrightnessAdjustment: BasicOperation {
    public var brightness:Float = 0.0 { didSet { uniformSettings["brightness"] = brightness } }
    
    public init() {
        super.init(fragmentShader:BrightnessFragmentShader, numberOfInputs:1)
        
        ({brightness = 0.0})()
    }
}

extension String  {
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    func contains(_ find: String) -> Bool{
        return self.range(of: find) != nil
    }
    
    func containsIgnoringCase(_ find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
}
