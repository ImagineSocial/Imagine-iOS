//
//  UIApplication.swift
//  Imagine
//
//  Created by Don Malte on 03.12.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    
    static func keyWindow() -> UIWindow? {
        UIApplication.shared.windows.first(where: \.isKeyWindow)
    }
}
