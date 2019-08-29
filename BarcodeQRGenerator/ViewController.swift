//
//  ViewController.swift
//  BarcodeQRGenerator
//
//  Created by SonNH-HAV on 8/29/19.
//  Copyright © 2019 VPS. All rights reserved.
//

import UIKit
import CoreImage

class ViewController: UIViewController {

    @IBOutlet weak var tfContent: UITextField!
    @IBOutlet weak var imvResult: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tfContent.clearButtonMode = .always
    }

    @IBAction func pressedCreateBarcode(_ sender: Any) {
        self.view.endEditing(true)
        imvResult.image = nil
        
        if let content = tfContent.text, !content.isEmpty {
            if let result = generateBarcode(from: content) {
                imvResult.image = result
            }
        }
    }
    
    @IBAction func pressedCreateQR(_ sender: Any) {
        imvResult.image = nil
        self.view.endEditing(true)
        
        if let content = tfContent.text, !content.isEmpty {
            let color = UIColor(red: 0.3, green: 0.9, blue: 0.58, alpha: 1.00)
            if let result = generateQRCode(from: content, color: color, logo: UIImage(named: "logo_half")) {
                imvResult.image = result
            }
        }
    }
    
    func generateBarcode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CICode128BarcodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
    
    func generateQRCode(from string: String, color: UIColor = .black, logo: UIImage? = nil) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 12, y: 12)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                let tintImage = color == .black ? output : output.tinted(using: color)
                
                guard let logoImage = logo?.cgImage else {
                    return UIImage(ciImage: tintImage!)
                }
                return UIImage(ciImage: tintImage!.combined(with: CIImage(cgImage: logoImage))!)
            }
        }
        
        return nil
    }
    
}

extension CIImage {
    
    /// Combines the current image with the given image centered.
    func combined(with image: CIImage) -> CIImage? {
        guard let combinedFilter = CIFilter(name: "CISourceOverCompositing") else { return nil }
        let centerTransform = CGAffineTransform(translationX: extent.midX - (image.extent.size.width / 2), y: extent.midY - (image.extent.size.height / 2))
        combinedFilter.setValue(image.transformed(by: centerTransform), forKey: "inputImage")
        combinedFilter.setValue(self, forKey: "inputBackgroundImage")
        return combinedFilter.outputImage!
    }
}

extension CIImage {
    /// Inverts the colors and creates a transparent image by converting the mask to alpha.
    /// Input image should be black and white.
    var transparent: CIImage? {
        return inverted?.blackTransparent
    }
    
    /// Inverts the colors.
    var inverted: CIImage? {
        guard let invertedColorFilter = CIFilter(name: "CIColorInvert") else { return nil }
        
        invertedColorFilter.setValue(self, forKey: "inputImage")
        return invertedColorFilter.outputImage
    }
    
    /// Converts all black to transparent.
    var blackTransparent: CIImage? {
        guard let blackTransparentFilter = CIFilter(name: "CIMaskToAlpha") else { return nil }
        blackTransparentFilter.setValue(self, forKey: "inputImage")
        return blackTransparentFilter.outputImage
    }
    
    /// Applies the given color as a tint color.
    func tinted(using color: UIColor) -> CIImage?
    {
        guard
            let transparentQRImage = transparent,
            let filter = CIFilter(name: "CIMultiplyCompositing"),
            let colorFilter = CIFilter(name: "CIConstantColorGenerator") else { return nil }
        
        let ciColor = CIColor(color: color)
        colorFilter.setValue(ciColor, forKey: kCIInputColorKey)
        let colorImage = colorFilter.outputImage
        
        filter.setValue(colorImage, forKey: kCIInputImageKey)
        filter.setValue(transparentQRImage, forKey: kCIInputBackgroundImageKey)
        
        return filter.outputImage!
    }
}

extension URL {
    
    /// Creates a QR code for the current URL in the given color.
    func qrImage(using color: UIColor) -> CIImage? {
        return qrImage?.tinted(using: color)
    }
    
    /// Returns a black and white QR code for this URL.
    var qrImage: CIImage? {
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        let qrData = absoluteString.data(using: String.Encoding.ascii)
        qrFilter.setValue(qrData, forKey: "inputMessage")
        
        let qrTransform = CGAffineTransform(scaleX: 12, y: 12)
        return qrFilter.outputImage?.transformed(by: qrTransform)
    }
}

