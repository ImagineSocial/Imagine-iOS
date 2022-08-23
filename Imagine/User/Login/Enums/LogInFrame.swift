//
//  LogInFrame.swift
//  Imagine
//
//  Created by Don Malte on 22.08.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

enum LogInFrame {
    case enterEmail, wrongEmail, forgotPassword
    case enterPassword, wrongPassword
    
    var isSecureTextEntry: Bool {
        switch self {
        case .enterEmail, .wrongEmail, .forgotPassword:
            return false
        default:
            return true
        }
    }
    
    var textContentType: UITextContentType {
        switch self {
        case .enterEmail, .wrongEmail:
            return .username
        case  .forgotPassword:
            return .emailAddress
        default:
            return .password
        }
    }
    
    var keyboardType: UIKeyboardType {
        switch self {
        case .enterEmail, .wrongEmail, .forgotPassword:
            return .emailAddress
        default:
            return .default
        }
    }
    
    var text: String {
        switch self {
        case .enterEmail:
            return NSLocalizedString("enter_email", comment: "enter email")
        case .wrongEmail:
            return NSLocalizedString("login_error_email", comment: "wrong email")
        case .forgotPassword:
            return NSLocalizedString("login_forgot_password", comment: "forgot password")
        case .enterPassword:
            return NSLocalizedString("login_password", comment: "enter password")
        case .wrongPassword:
            return NSLocalizedString("login_error_password", comment: "wrong password")
        }
    }
}
