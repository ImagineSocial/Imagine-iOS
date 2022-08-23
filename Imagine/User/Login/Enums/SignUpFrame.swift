//
//  SignUpFrame.swift
//  Imagine
//
//  Created by Don Malte on 22.08.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

enum SignUpFrame {
    case enterFirstName
    case enterUsername, usernameAlreadyUsed
    case enterEmail, invalidEmail, emailAlreadyUsed
    case enterPassword
    case ourPrinciples
    case acceptPrivacyAgreement, acceptEULAAgreement
    case wait, ready
    case error
    
    var answerContentType: UITextContentType? {
        switch self {
        case .enterFirstName:
            return .givenName
        case .enterEmail, .invalidEmail, .emailAlreadyUsed:
            return .emailAddress
        case .enterPassword:
            return .newPassword
        case .enterUsername, .usernameAlreadyUsed:
            return .nickname
        default:
            return nil
        }
    }
    
    var answerKeyboardType: UIKeyboardType {
        switch self {
        case .enterEmail, .invalidEmail, .emailAlreadyUsed:
            return .emailAddress
        default:
            return .default
        }
    }
    
    var expectAnswer: Bool {
        answerContentType != nil
    }
    
    var questionText: String {
        switch self {
        case .enterFirstName:
            return NSLocalizedString("enter_first_name", comment: "Enter your name (with a 'too much' touch)")
        case .enterUsername:
            return "Enter a username"
        case .usernameAlreadyUsed:
            return "The username is already in use, please choose another one"
        case .enterEmail:
            return NSLocalizedString("enter_email", comment: "Enter the email adress")
        case .invalidEmail:
            return NSLocalizedString("invalid email", comment: "invalid email")
        case .emailAlreadyUsed:
            return NSLocalizedString("email already in use", comment: "email already in use, use a different one")
        case .enterPassword:
            return NSLocalizedString("enter password", comment: "Enter password")
        case .ourPrinciples:
            return NSLocalizedString("welcome to imagine", comment: "Welcome & respect our principles")
        case .acceptPrivacyAgreement:
            return NSLocalizedString("approve GDPR rules", comment: "Do you accept the data agreement?")
        case .acceptEULAAgreement:
            return NSLocalizedString("approve_eula_rules", comment: "dont be a shitty person!")
        case .wait:
            return ""
        case .ready:
            return NSLocalizedString("ready to go", comment: "Ready to go and confirm email")
        case .error:
            return NSLocalizedString("signup_error", comment: "Something is wrong, try later")
        }
    }
    
    var informationText: String? {
        switch self {
        case .enterFirstName:
            return NSLocalizedString("name_placeholder", comment: "Visible for everybody")
        case .enterPassword:
            return NSLocalizedString("password must be safe", comment: "Hint that the password must be safe and at least 6 characters")
        case .ourPrinciples:
            return NSLocalizedString("need your help", comment: "Need your help to obtain order")
        case .enterUsername:
            return "The username isn't utilized yet, but will be in the future. It will be used to connect with your friends more easily and tag relevant users."
        default:
            return nil
        }
    }
    
    var showInformationLabel: Bool {
        informationText != nil
    }
    
    var answerPlaceholder: String? {
        switch self {
        case .enterFirstName:
            return NSLocalizedString("name_example_placeholder", comment: "John/Max")
        case .enterEmail:
            return NSLocalizedString("email_example_placeholder", comment: "")
        case .invalidEmail:
            return NSLocalizedString("email_example_placeholder", comment: "")
        case .emailAlreadyUsed:
            return NSLocalizedString("email_example_placeholder", comment: "")
        case .enterPassword:
            return NSLocalizedString("password_placeholder", comment: "")
        case .enterUsername, .usernameAlreadyUsed:
            return "@MacCalcium"
        default:
            return nil
        }
    }
    
    var buttonText: String {
        switch self {
        case .acceptPrivacyAgreement, .acceptEULAAgreement:
            return NSLocalizedString("I agree", comment: "I agree")
        case .ready:
            return NSLocalizedString("go_to_imagine", comment: "to imagine")
        case .ourPrinciples:
            return "Okay"
        default:
            return NSLocalizedString("next", comment: "next")
        }
    }
    
    var showEULAButton: Bool {
        switch self {
        case .acceptEULAAgreement, .acceptPrivacyAgreement:
            return true
        default:
            return false
        }
    }
}
