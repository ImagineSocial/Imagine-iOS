//
//  UIKit.swift
//  Imagine
//
//  Created by Don Malte on 01.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

extension URL {
    
    func loadImage() -> UIImage? {
        
        guard let imageData = try? Data(contentsOf: self) else {
            return nil
        }
        
        let image = UIImage(data: imageData)
        return image
    }
}
