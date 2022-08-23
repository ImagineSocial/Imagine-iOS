//
//  UIImage.swift
//  Imagine
//
//  Created by Don Malte on 01.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

extension UIImage {

  func getThumbnail() -> UIImage? {

    guard let imageData = self.pngData() else { return nil }

    let options = [
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: 300] as CFDictionary

    guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
    guard let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }

    return UIImage(cgImage: imageReference)

  }
    
    func compressedData() -> Data? {
        guard let originalImage = jpegData(compressionQuality: 1) else { return nil }
        let data = NSData(data: originalImage)
        
        let imageSize = data.count / 1000
        
        var compression = 0.0
        
        if imageSize <= 500 {   // When the imageSize is under 500kB it wont be compressed, because you can see the difference
            // No compression
            return originalImage
        } else if imageSize <= 1000 {
            compression = 0.4
        } else if imageSize <= 2000 {
            compression = 0.25
        } else {
            compression = 0.1
        }
        
        return jpegData(compressionQuality: compression)
    }
}
