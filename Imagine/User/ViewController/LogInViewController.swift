//
//  LogInViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

private enum LogInFrame {
    case enterEmail
    case enterPassword
    case wrongPassword
    case wrongEmail
    case forgotPassword
}

private enum SignUpFrame {
    case enterFirstName
    case enterLastName
    case enterEmail
    case invalidEmail
    case EmailAlreadyInUse
    case enterPassword
    case ourPrinciples
    case ready
    case acceptPrivacyAgreement
    case acceptEULAAgreement
    case wait
    case error
}

protocol DismissDelegate {
    func loadUser()
}

class LogInViewController: UIViewController {
    
    @IBOutlet weak var initialStackView: UIStackView!
    @IBOutlet weak var initialLabel: UILabel!
    @IBOutlet weak var initialLabelConstraint: NSLayoutConstraint!
    @IBOutlet weak var initialButton1: DesignableButton!
    @IBOutlet weak var initialButton2: DesignableButton!
    @IBOutlet weak var peaceSignView: UIImageView!
    
    @IBOutlet weak var imagineSignCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var imagineSignTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imagineSignHeightConstraint: NSLayoutConstraint! //FML!
    @IBOutlet weak var imagineSignWidthConstraint: NSLayoutConstraint!
    
    
    let attentionLabel = UILabel()
    let db = FirestoreRequest.shared.db
    
    var signUp = false
    var name = ""
    var surname = ""
    var signUpAnswers:[String:String] = ["":""]
    var email = ""
    var password = ""
    fileprivate var logInFrame: LogInFrame = .enterEmail
    fileprivate var signUpFrame: SignUpFrame = .enterFirstName
    var signUpInProgress = false
    
    let maltesUID = "CZOcL3VIwMemWwEfutKXGAfdlLy1"
    
    var delegate:DismissDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layer = initialButton1.layer
        layer.borderColor = Constants.green.cgColor
        layer.borderWidth = 1
        
        let layer2 = initialButton2.layer
        layer2.borderColor = UIColor.imagineColor.cgColor
        layer2.borderWidth = 1
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        checkIfSignUpIsAllowed()
    }
  
    func checkIfSignUpIsAllowed() {
        let ref = db.collection("TopTopicData").document("TopTopicData")
        ref.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    if let data = snap.data() {
                        if let isSignUpAllowed = data["isSignUpAllowed"] as? Bool {
                            if !isSignUpAllowed {
                                let alert = UIAlertController(title: "We're Sorry", message: "There are more Sign-Up requests, than we can handle. In order to protect the app and our database, we pause the Sign-Up/Log-In for now. Please try later again. Thanks for your support!", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
                                    self.dismiss(animated: true, completion: nil)
                                }
                                
                                alert.addAction(okAction)
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        answerTextfield.resignFirstResponder()
        answerTextfieldTwo.resignFirstResponder()
    }
    
    //MARK: - SignUp & LogIn Sessions
    
    func startSignUpSession() {
        
        signUpInProgress = true
        answerTextfield.text = ""
        nextButton.alpha = 0.5
        
        answerTextfield.addTarget(self, action: #selector(textGetsWritten), for: .editingChanged)
        answerTextfieldTwo.addTarget(self, action: #selector(textGetsWritten), for: .editingChanged)
        
        switch signUpFrame {
        case .enterFirstName:
            answerTextfield.textContentType = .givenName
            questionLabel.text = NSLocalizedString("enter_first_name", comment: "Enter your name (with a 'too much' touch)")
            informationLabel.text = NSLocalizedString("name_placeholder", comment: "Visible for everybody")
            self.informationLabel.alpha = 1
            self.answerTextfield.placeholder = NSLocalizedString("name_example_placeholder", comment: "John/Max")
        case .enterLastName:
            answerTextfield.textContentType = .familyName
            self.answerTextfield.placeholder = NSLocalizedString("surname_example_placeholder", comment: "Doe/Mustermann")
                let surnameText = NSLocalizedString("enter_second_name", comment: "Enter your surname (with a 'too much' touch)")
            questionLabel.text = String.localizedStringWithFormat(surnameText, name)
            informationLabel.text = NSLocalizedString("surname_placeholder", comment: "Just visible for friends")
        case .enterEmail:
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
            answerTextfield.placeholder = NSLocalizedString("email_example_placeholder", comment: "")
            questionLabel.text = NSLocalizedString("enter_email", comment: "Enter the email adress")
        case .invalidEmail:
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
            answerTextfield.placeholder = NSLocalizedString("email_example_placeholder", comment: "")
            questionLabel.text = NSLocalizedString("invalid email", comment: "invalid email")
            nextButton.setTitle(NSLocalizedString("next", comment: "next"), for: .normal)
            answerTextfield.isEnabled = true
        case .EmailAlreadyInUse:
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
            answerTextfield.placeholder = NSLocalizedString("email_example_placeholder", comment: "")
            questionLabel.text = NSLocalizedString("email already in use", comment: "email already in use, use a different one")
            nextButton.setTitle(NSLocalizedString("next", comment: "next"), for: .normal)
            answerTextfield.isEnabled = true
        case .enterPassword:
            answerTextfield.textContentType = .newPassword
            answerTextfield.isSecureTextEntry = true
            answerTextfieldTwo.alpha = 1
            answerTextfield.placeholder = NSLocalizedString("password_placeholder", comment: "")
            questionLabel.text = NSLocalizedString("enter password", comment: "Enter password")
            informationLabel.text = NSLocalizedString("password must be safe", comment: "Hint that the password must be safe and at least 6 characters")
            newStackView.insertArrangedSubview(answerTextfieldTwo, at: 3)
        case .ourPrinciples: // Is set in "tryTOSignUp
            eulaButton.isHidden = true
            answerTextfield.alpha = 0
            questionLabel.text = NSLocalizedString("welcome to imagine", comment: "Welcome & respect our principles")
            nextButton.setTitle("Okay", for: .normal)
            nextButton.isEnabled = true
            nextButton.alpha = 1
            informationLabel.text = NSLocalizedString("need your help", comment: "Need your help to obtain order")
//        case .respectYourFellowMan:
//            questionLabel.text = "Wirst du die Ansichten und Meinungen deiner Mit-User respektieren, auch wenn diese sich von deinen Unterscheiden?"
//        case .supportImagine:
//            questionLabel.text = "Wirst du Ungerechtigkeiten und Verstöße gegen die eben genannten Regeln melden und die Stimmung bei Imagine gerecht und einvernehmlich halten?"
        case .ready:
            answerTextfield.alpha = 0
            questionLabel.text = NSLocalizedString("ready to go", comment: "Ready to go and confirm email")
            nextButton.setTitle(NSLocalizedString("go_to_imagine", comment: "to imagine"), for: .normal)
            nextButton.isEnabled = true
            nextButton.alpha = 1
        case .error:
            questionLabel.text = NSLocalizedString("signup_error", comment: "Something is wrong, try later")
        case .acceptEULAAgreement:
            answerTextfield.resignFirstResponder()
            answerTextfieldTwo.resignFirstResponder()
            self.nextButton.alpha = 1
            self.nextButton.isEnabled = true
            self.eulaButton.isEnabled = true
            self.answerTextfield.alpha = 0
            self.informationLabel.alpha = 0
            self.answerTextfield.isEnabled = false
            questionLabel.text = NSLocalizedString("approve_eula_rules", comment: "dont be a shitty person!")
            nextButton.setTitle(NSLocalizedString("I agree", comment: "I agree"), for: .normal)
            
            showEulaButton()
        case .acceptPrivacyAgreement:
            answerTextfield.resignFirstResponder()
            answerTextfieldTwo.resignFirstResponder()
            self.nextButton.alpha = 1
            self.nextButton.isEnabled = true
            self.eulaButton.isEnabled = true
            self.answerTextfield.alpha = 0
            self.informationLabel.alpha = 0
            self.answerTextfield.isEnabled = false
            questionLabel.text = NSLocalizedString("approve GDPR rules", comment: "Do you accept the data agreement?")
            nextButton.setTitle(NSLocalizedString("I agree", comment: "I agree"), for: .normal)
            
            showEulaButton()
        case .wait:
            print("Waitin'")
        }
        
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
            
            self.questionLabel.alpha = 1
            
            switch self.signUpFrame {
            case .enterFirstName:
                self.showInformationLabel()
                self.answerTextfield.alpha = 1
            case .enterLastName:
                self.showInformationLabel()
                self.answerTextfield.alpha = 1
            case .enterEmail:
                self.answerTextfield.alpha = 1
            case .invalidEmail:
                self.eulaButton.alpha = 0
                self.answerTextfield.alpha = 1
            case .EmailAlreadyInUse:
                self.eulaButton.alpha = 0
                self.answerTextfield.alpha = 1
            case .enterPassword:
                self.showInformationLabel()
                self.answerTextfield.alpha = 1
            case .ourPrinciples:
                self.eulaButton.alpha = 0
                self.showInformationLabel()
                self.answerTextfield.alpha = 0
            case .ready:
                self.answerTextfield.alpha = 0
            case .acceptEULAAgreement:
                self.eulaButton.alpha = 1
                self.answerTextfield.alpha = 0
            case .acceptPrivacyAgreement:
                self.eulaButton.alpha = 1
                self.answerTextfield.alpha = 0
            case .wait:
                self.answerTextfield.alpha = 0
            case .error:
                self.answerTextfield.alpha = 0
            }
        }, completion: { (_) in
            
            
        })
    }

    func showInformationLabel() {
        UIView.animate(withDuration: 0.2) {
            self.informationLabel.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    func startLogIn() {
        answerTextfield.text = ""
        nextButton.isEnabled = true
        nextButton.alpha = 0.5
        
        answerTextfield.addTarget(self, action: #selector(textGetsWritten), for: .editingChanged)
        
        switch logInFrame {
        case .enterEmail:
            questionLabel.text = NSLocalizedString("enter_email", comment: "enter email")
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
        case .enterPassword:
            questionLabel.text = NSLocalizedString("login_password", comment: "enter password")
            answerTextfield.textContentType = .password
            answerTextfield.isSecureTextEntry = true
            resetPasswordButton.isHidden = false
        case .wrongEmail:
            self.questionLabel.text = NSLocalizedString("login_error_email", comment: "wrong email")
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
        case .wrongPassword:
            self.questionLabel.text = NSLocalizedString("login_error_password", comment: "wrong password")
            answerTextfield.textContentType = .password
            answerTextfield.isSecureTextEntry = true
            resetPasswordButton.isHidden = false
        case .forgotPassword:
            questionLabel.text = NSLocalizedString("login_forgot_password", comment: "forgot password")
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
        }
        UIView.animate(withDuration: 0.9, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
            self.answerTextfield.alpha = 1
            self.questionLabel.alpha = 1
        })
        
    }
    
    // MARK: - NextButtonPushed
    
    func isPasswordAccepted() -> Bool {
        if let input = answerTextfield.text {
            
            let answer = input.trimmingCharacters(in: .whitespaces)
            
            if answer.count >= 6 {
                password = answer
                if answerTextfield.text == answerTextfieldTwo.text {
                    return true
                } else {
                    questionLabel.text = NSLocalizedString("signup_error_repeat_password", comment: "not the same")
                    return false
                }
            } else {
                questionLabel.text = NSLocalizedString("signup_error_weak_password", comment: "at least 6 signs")
                return false
            }
        } else {
            return false
        }
    }
    
    @objc func nextButtonPushed(sender: DesignableButton!) {
        
        if signUpFrame == .enterPassword && !isPasswordAccepted() {
            return
        }
        
        nextButton.isEnabled = false
        answerTextfield.resignFirstResponder()
                
        if signUp {
            if let input = answerTextfield.text {
                
                let answer = input.trimmingCharacters(in: .whitespaces)
                switch signUpFrame{
                case .enterFirstName:
                    name = answer
                    signUpFrame = .enterLastName
                case .enterLastName:
                    surname = answer
                    signUpFrame = .enterEmail
                case .enterEmail:
//                    replace spaces
                    email = answer
                    signUpFrame = .enterPassword
                case .enterPassword:
                    self.signUpFrame = .acceptEULAAgreement
                case .acceptEULAAgreement:
                    self.signUpFrame = .acceptPrivacyAgreement
                case .EmailAlreadyInUse:
                    email = answer
                    signUpFrame = .enterPassword
                case .invalidEmail:
                    email = answer
                    signUpFrame = .enterPassword
                case .ourPrinciples:
                    signUpFrame = .ready
                case .acceptPrivacyAgreement:
                    tryToSignUp()
                    self.signUpFrame = .wait
                    self.view.activityStartAnimating()
                case .ready:
                    self.delegate?.loadUser()
                    self.dismiss(animated: true, completion: nil)
                case .error:
                    self.dismiss(animated: true, completion: nil)
                case .wait:
                    print("Nothing")
                }
                
                UIView.animate(withDuration: 0.7, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
                    self.answerTextfield.alpha = 0
                    self.answerTextfieldTwo.alpha = 0
                    self.informationLabel.alpha = 0
                    self.nextButton.alpha = 0
                    self.questionLabel.alpha = 0
                }, completion: { (_) in
                    self.answerTextfieldTwo.text = ""
                    if self.signUpFrame == .enterPassword {
                        self.answerTextfieldTwo.removeFromSuperview()
                    }
                    
                    switch self.signUpFrame {
                    case .wait:
                        print("Wait for the signUp")
                    default:
                        self.startSignUpSession()
                    }
                })
                
            }
        } else {    // Wenn es Log-In ist
            print("else")
            
            if let input = answerTextfield.text {

                let answer = input.trimmingCharacters(in: .whitespaces)
                
                switch logInFrame {
                case .enterEmail:
                    email = answer
                    logInFrame = .enterPassword
                case .enterPassword:
                    password = answer
                    tryToLogIn()
                case .wrongEmail:
                    email = answer
                    logInFrame = .enterPassword
                case .wrongPassword:
                    password = answer
                    tryToLogIn()
                case .forgotPassword:
                    self.resetPassword(email: answer)
                }
            }
            UIView.animate(withDuration: 0.9, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
                self.answerTextfield.alpha = 0
                self.informationLabel.alpha = 0
                self.nextButton.alpha = 0.5
                self.questionLabel.alpha = 0
            }, completion: { (_) in
                
                self.startLogIn()
                
            })
        }
        print(signUpAnswers)
    }
    
    //MARK: - Try to Sign Up
    
    func tryToSignUp() {
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("We have an error: \(error.localizedDescription)")
                
                if let errCode = AuthErrorCode.Code(rawValue: error._code) {
                    
                    switch errCode {
                    case .emailAlreadyInUse:
                        self.signUpFrame = .EmailAlreadyInUse
                    case .invalidEmail:
                        self.signUpFrame = .invalidEmail
                    case .weakPassword:
                        self.signUpFrame = .enterPassword
                    default:
                        self.signUpFrame = .error
                    }
                    self.view.activityStopAnimating()
                    self.startSignUpSession()
                }
            } else {
                print("User wurde erfolgreich erstellt.")
                
                if let user = Auth.auth().currentUser {
                    let changeRequest = user.createProfileChangeRequest()
                    let fullName = "\(self.name) \(self.surname)"
                    
                    changeRequest.displayName = fullName
                    changeRequest.commitChanges { error in
                        if error != nil {
                            // An error happened.
                            print("Wir haben einen error beim changeRequest: \(String(describing: error?.localizedDescription))")
                        } else {
                            // Profile updated.
                            print("changeRequest hat geklappt")
                        }
                    }
                
                    let userRef = self.db.collection("Users").document(user.uid)
                    let data: [String:Any] = ["badges": ["first500"], "name": self.name, "surname": self.surname, "full_name": fullName, "createDate": Timestamp(date: Date())] //"username": self.displayName,
                    
                    userRef.setData(data, completion: { (error) in
                        if let error = error {
                            print("We have an error: \(error.localizedDescription)")
                        } else {
                            print("User wurde in Datenbank übertragen")
                            self.signUpFrame = .ourPrinciples
                            self.view.activityStopAnimating()
                            self.startSignUpSession()
                            
                            self.notifyMalte(name: fullName)
                            
                            user.sendEmailVerification { (error) in
                                if let err = error {
                                    print("We have an error: \(err.localizedDescription)")
                                } else {
                                    print("Email Verification send")
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    func notifyMalte(name: String) {
        let notificationRef = db.collection("Users").document(maltesUID).collection("notifications").document()
        let language = Locale.preferredLanguages[0]
        let notificationData: [String: Any] = ["type": "message", "message": "Wir haben einen neuen User: \(name)", "name": "System", "chatID": "Egal", "sentAt": Timestamp(date: Date()), "messageID": "Dont Know", "language": language]
        
        
        notificationRef.setData(notificationData) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                print("Successfully set notification")
            }
        }
    }
    
    //MARK: -Try to log in
    
    func tryToLogIn() {
        print(" Hier zum einloggen")

        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            
            if let error = error {
                if let errCode = AuthErrorCode.Code(rawValue: error._code) {
                    
                    switch errCode {
                    case .wrongPassword:
                        self.logInFrame = .wrongPassword
                    case .invalidEmail:
                        self.logInFrame = .wrongEmail
                        print("invalid email")
                    default:
                        print("Other error!")
                    }
                    
                    self.startLogIn()
                    
                }
            } else {
                if let result = result {
                    if !result.user.isEmailVerified {
                        print("Not yet verified")
                        self.tryToLogOut()
                        
                        let emailText = NSLocalizedString("login_verify_email", comment: "verify email first, should send again?")
                        
                        
                        let alertVC = UIAlertController(title: "Error", message: String.localizedStringWithFormat(emailText, self.email), preferredStyle: .alert)
                        let alertActionOkay = UIAlertAction(title: "Okay", style: .default) {
                            (_) in
                            result.user.sendEmailVerification { (err) in
                                                                
                                if let error = err {
                                    print("We have an error: \(error.localizedDescription)")
                                } else {
                                    self.alert(message: NSLocalizedString("verify_email_send_again", comment: ""))
                                    self.dismiss(animated: true, completion: nil)
                                }
                            }
                        }
                        let alertActionCancel = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel) { (_) in
                            self.dismiss(animated: true, completion: nil)
                        }

                        alertVC.addAction(alertActionOkay)
                        alertVC.addAction(alertActionCancel)
                        self.present(alertVC, animated: true, completion: nil)
                    } else {
                        print("User wurde erfolgreich eingeloggt.")
                    
                        self.delegate?.loadUser()
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func resetPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
                if let errCode = AuthErrorCode.Code(rawValue: error._code) {
                    
                    switch errCode {
                    case .invalidEmail:
                        self.logInFrame = .wrongEmail
                        
                    default:
                        self.logInFrame = .wrongEmail
                    }
                    self.startLogIn()
                }
            } else {
                self.alert(message: NSLocalizedString("reset_password_title", comment: "email was sent"), title: NSLocalizedString("reset_password_message", comment: "change and come back"))
            }
        }
    }
    
    func tryToLogOut() {
        do {
            try Auth.auth().signOut()
            print("Log Out successful")
        } catch {
            print("Log Out not successfull")
        }
    }
    
    
    //MARK: -Functions
    func showEulaButton() {
        self.view.addSubview(eulaButton)
        eulaButton.centerXAnchor.constraint(equalTo: nextButton.centerXAnchor).isActive = true
        eulaButton.topAnchor.constraint(equalTo: nextButton.bottomAnchor, constant: 25).isActive = true
        eulaButton.widthAnchor.constraint(equalTo: nextButton.widthAnchor, constant: -50).isActive = true
        eulaButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        eulaButton.addTarget(self, action: #selector(toEulaTapped), for: .touchUpInside)
        
        eulaButton.alpha = 1
    }
    
    @objc func toEulaTapped() {
        let language = LanguageSelection().getLanguage()
        if self.signUpFrame == .acceptPrivacyAgreement {
            
            if language == .en {
                if let url = URL(string: "https://en.imagine.social/datenschutzerklaerung-app") {
                    UIApplication.shared.open(url)
                }
            } else {
                if let url = URL(string: "https://imagine.social/datenschutzerklaerung-app") {
                    UIApplication.shared.open(url)
                }
            }
        } else {
            if language == .en {
                if let url = URL(string: "https://en.imagine.social/eula") {
                    UIApplication.shared.open(url)
                }
            } else {
                if let url = URL(string: "https://imagine.social/eula") {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
    
    
    
    @objc func resetPasswordTapped() {
        self.logInFrame = .forgotPassword
        self.startLogIn()
    }
    
    func showResetPasswordButton() {
        self.view.addSubview(resetPasswordButton)
        resetPasswordButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        resetPasswordButton.topAnchor.constraint(equalTo: nextButton.bottomAnchor, constant: 3).isActive = true
        resetPasswordButton.isHidden = true
    }
    
    @objc func textGetsWritten() {
        
        if self.signUpFrame == .enterPassword {
            
            if answerTextfield.text != "" && answerTextfield.text != "" {
                if answerTextfield.text!.count >= 6 && answerTextfieldTwo.text!.count >= 6 {
                    self.enableNextButton()
                } else {
                    self.lockNextButton()
                }
            }
            
        } else {
            enableNextButton()
        }
    }
    
    func lockNextButton() {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
            
            self.nextButton.alpha = 0.5
            self.nextButton.isEnabled = false
        })
    }
    
    func enableNextButton() {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
            
            self.nextButton.alpha = 1
            self.nextButton.isEnabled = true
        })
    }
    
    let eulaButton: DesignableButton = {
        let button = DesignableButton(title: NSLocalizedString("go_to_gdpr", comment: ""), font: UIFont(name: "IBMPlexSans", size: 14), cornerRadius: 6, tintColor: .white, backgroundColor: .imagineColor)
        
        button.addTarget(self, action: #selector(toEulaTapped), for: .touchUpInside)
        
        return button
    }()
    
    let resetPasswordButton: DesignableButton = {
        let button = DesignableButton(title: NSLocalizedString("forgot_password", comment: ""), font: UIFont(name: "IBMPlexSans-Medium", size: 10), cornerRadius: 4, tintColor: .imagineColor)
        
        button.addTarget(self, action: #selector(resetPasswordTapped), for: .touchUpInside)
        
        return button
    }()
    
    
    let questionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "IBMPlexSans", size: 22)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 0
        label.lineBreakMode = .byClipping
        label.textAlignment = .center
        label.alpha = 0     // Erstmal unsichtbar
        return label
    }()
    
    let answerTextfield: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .left
        textField.borderStyle = .none
        textField.font = UIFont(name: "IBMPlexSans", size: 18)
        textField.placeholder = "..."
        textField.autocorrectionType = .no
        textField.alpha = 0
        textField.addTarget(self, action: #selector(textGetsWritten), for: .editingChanged)
        
        let underline = UIView()
        underline.translatesAutoresizingMaskIntoConstraints = false
        underline.backgroundColor = .secondaryLabel
        
        textField.addSubview(underline)
        underline.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        underline.trailingAnchor.constraint(equalTo: textField.trailingAnchor).isActive = true
        underline.bottomAnchor.constraint(equalTo: textField.bottomAnchor).isActive = true
        underline.heightAnchor.constraint(equalToConstant: 1).isActive = true

        return textField
    }()
    
    let answerTextfieldTwo: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .left
        textField.borderStyle = .none
        textField.font = UIFont(name: "IBMPlexSans", size: 18)
        textField.placeholder = NSLocalizedString("repeat_password_placeholder", comment: "")
        textField.autocorrectionType = .no
        textField.isSecureTextEntry = true
        
        let underline = UIView()
        underline.translatesAutoresizingMaskIntoConstraints = false
        underline.backgroundColor = .secondaryLabel
        
        textField.addSubview(underline)
        underline.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        underline.trailingAnchor.constraint(equalTo: textField.trailingAnchor).isActive = true
        underline.bottomAnchor.constraint(equalTo: textField.bottomAnchor).isActive = true
        underline.heightAnchor.constraint(equalToConstant: 1).isActive = true

        return textField
    }()
    
    let informationLabel: UILabel = {
       let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont(name: "IBMPlexSans", size:11)
        label.textColor = UIColor.secondaryLabel
        label.alpha = 1
        label.text = ""
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.layoutIfNeeded()
        
        return label
    }()
    
    let nextButton: DesignableButton = {
       let button = DesignableButton(title: NSLocalizedString("next", comment: ""), font: UIFont(name: "IBMPlexSans", size: 18))
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.imagineColor.cgColor
        button.tag = 0
        button.alpha = 0
        button.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        return button
    }()
    
    let newStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.spacing = 20
        
        return stack
    }()
    
    func setUpNewStackViewUI() {
        
        newStackView.addArrangedSubview(questionLabel)
        newStackView.addArrangedSubview(informationLabel)
        newStackView.addArrangedSubview(answerTextfield)
//        newStackView.addArrangedSubview(nextButton)
        
        view.addSubview(newStackView)
        newStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        newStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
//        newStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100).isActive = true
        newStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -75).isActive = true
        
        view.addSubview(nextButton)
        nextButton.trailingAnchor.constraint(equalTo: newStackView.trailingAnchor).isActive = true
//        nextButton.centerXAnchor.constraint(equalTo: newStackView.centerXAnchor).isActive = true
        nextButton.topAnchor.constraint(equalTo: newStackView.bottomAnchor, constant: 25).isActive = true
        nextButton.widthAnchor.constraint(equalTo: newStackView.widthAnchor, constant: -100).isActive = true
        nextButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        questionLabel.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        self.imagineSignCenterXConstraint.constant = (self.view.frame.width/2)-60
        self.imagineSignTopConstraint.constant = 20
        self.imagineSignWidthConstraint.constant = 40
        self.imagineSignHeightConstraint.constant = 40
        
        UIView.animate(withDuration: 0.7) {
            self.peaceSignView.alpha = 0.7
            self.view.layoutIfNeeded()
        }
        
        showResetPasswordButton()
    }
    
    
    @IBAction func logInTouched(_ sender: Any) {
        
        UIView.animate(withDuration: 1, animations: {
            self.initialStackView.alpha = 0
            self.peaceSignView.alpha = 0.3
        }) { (_) in
            self.initialStackView.isHidden = true
            self.setUpNewStackViewUI()
            self.startLogIn()
        }
    }
    
    
    @IBAction func signUpTouched(_ sender: Any) {
        
        signUp = true
        
        UIView.animate(withDuration: 1, animations: {
            self.initialStackView.alpha = 0
            self.attentionLabel.alpha = 0
        }) { (_) in
            self.initialStackView.isHidden = true
            self.attentionLabel.isHidden = true
            self.setUpNewStackViewUI()
            self.startSignUpSession()
        }
        
        
        
        
        
//        if signUp { // If the button is changed so it means dont sign up
//            UIView.animate(withDuration: 1.5, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
//                self.initialStackView.alpha = 0
//                self.attentionLabel.alpha = 0
//
//
//            }, completion: { (_) in
//                self.dismiss(animated: true, completion: nil)
//            })
//        } else {
//            // First Step
//            UIView.animate(withDuration: 2.0, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
//                self.initialStackView.alpha = 0
//                self.peaceSignView.alpha = 0.5
//                self.signUp = true  // Button verändern sich
//
//            }, completion: { (_) in
//                self.initialButton2.backgroundColor = UIColor(red:1.00, green:0.54, blue:0.52, alpha:1.0)
//                self.initialLabel.text = "Willkommen bei Imagine. Lass uns das Ritual starten und dich in unserer Gemeinschaft aufnehmen! Vergiss nicht ehrlich zu sein und ganz du selbst!"
//                self.initialButton1.setTitle("Ich bin bereit!", for: .normal)
//                self.initialButton2.setTitle("Lieber Später!", for: .normal)
//                self.initialButton2.backgroundColor = UIColor(red:1.00, green:0.54, blue:0.52, alpha:1.0)
//                //  Achtung Label
////                self.view.addSubview(self.attentionLabel)
////                self.attentionLabel.alpha = 0
////                self.attentionLabel.translatesAutoresizingMaskIntoConstraints = false
////                self.attentionLabel.centerXAnchor.constraint(equalTo: self.initialStackView.centerXAnchor, constant: 0).isActive = true
////                self.attentionLabel.topAnchor.constraint(equalTo: self.initialStackView.topAnchor, constant: -55).isActive = true
////                self.attentionLabel.text = ""
////                self.attentionLabel.font = UIFont(name: "IBMPlexSans", size: 30)
////                self.attentionLabel.shadowColor = UIColor.white
////                self.attentionLabel.shadowOffset = CGSize(width: 3, height: -1)
//
//                self.initialLabelConstraint.constant = 150
//
//                // Zweiter Schritt
//                UIView.animate(withDuration: 0.9, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
//                    self.attentionLabel.alpha = 1
//                    self.view.layoutIfNeeded()
//                }, completion: { (_) in
//                    //Dritter Schritt
//                    UIView.animate(withDuration: 0.9, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
//                        self.initialStackView.alpha = 1
//                    })
//                })
//            })
//        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
//        if let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as? UIView{
//            statusBar.alpha = 1
//        }
    }
    
    
    @IBAction func cancelTapped(_ sender: Any) {
        if signUpInProgress && signUpFrame != .enterFirstName {
            let alertController = UIAlertController(title: NSLocalizedString("cancel_signup_title", comment: ""), message: NSLocalizedString("cancel_signup_message", comment: "all data will be lost.."), preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Anmeldung abbrechen", style: .destructive, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
                
            })
            let stayAction = UIAlertAction(title: NSLocalizedString("cancel_stay_here", comment: ""), style: .cancel) { (_) in
                alertController.dismiss(animated: true, completion: nil)
            }
            alertController.addAction(cancelAction)
            alertController.addAction(stayAction)
            self.present(alertController, animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
}
