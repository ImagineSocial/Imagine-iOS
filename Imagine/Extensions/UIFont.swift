//
//  UIFont.swift
//  Imagine
//
//  Created by Don Malte on 27.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

extension UIFont {
    
    static func standard(with weight: UIFont.Weight = .regular, size: CGFloat = 15) -> UIFont? {
        switch weight {
        case .semibold:
            return UIFont(name: "IBMPlexSans-SemiBold", size: size)
        case .light:
            return UIFont(name: "IBMPlexSans-Light", size: size)
        case .ultraLight:
            return UIFont(name: "IBMPlexSans-ExtraLight", size: size)
        case .bold:
            return UIFont(name: "IBMPlexSans-Bold", size: size)
        case .medium:
            return UIFont(name: "IBMPlexSans-Medium", size: size)
        case .thin:
            return UIFont(name: "IBMPlexSans-Thin", size: size)
        default:
            return UIFont(name: "IBMPlexSans", size: size)
        }
    }
}
