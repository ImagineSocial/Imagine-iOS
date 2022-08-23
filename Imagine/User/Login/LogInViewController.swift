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

protocol DismissDelegate {
    func loadUser()
}

enum LoginType {
    case login, signup
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
    
    
    let db = FirestoreRequest.shared.db
    
    var loginType = LoginType.login
    var name: String?
    var username: String?
    var email: String?
    var password: String?
    
    var logInFrame: LogInFrame = .enterEmail
    var signUpFrame: SignUpFrame = .enterFirstName
    var signUpInProgress = false
        
    var delegate: DismissDelegate?
    
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
        answerTextfield.delegate = self
    }
    
    func checkIfSignUpIsAllowed() {
        let ref = db.collection("TopTopicData").document("TopTopicData")
        ref.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap, let data = snap.data(), let isSignUpAllowed = data["isSignUpAllowed"] as? Bool, !isSignUpAllowed {
                    let alert = UIAlertController(title: Strings.weAreSorry, message: Strings.noSignUpsAlert, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
                        self.dismiss(animated: true) {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                    
                    alert.addAction(okAction)
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        answerTextfield.resignFirstResponder()
        answerTextfieldTwo.resignFirstResponder()
    }
    
    //MARK: - SignUp & LogIn Sessions
    
    private func startSignUpSession() {
        
        answerTextfield.text = ""
        nextButton.alpha = 0.5
        
        answerTextfield.textContentType = signUpFrame.answerContentType
        answerTextfield.keyboardType = signUpFrame.answerKeyboardType
        answerTextfield.isSecureTextEntry = signUpFrame == .enterPassword
        
        questionLabel.text = signUpFrame.questionText
        
        informationLabel.text = signUpFrame.informationText
        informationLabel.alpha = signUpFrame.informationText == nil ? 0 : 1
        
        nextButton.setTitle(signUpFrame.buttonText, for: .normal)
        
        if let placeholder = signUpFrame.answerPlaceholder {
            answerTextfield.placeholder = placeholder
        }
        
        switch signUpFrame {
        case .acceptPrivacyAgreement, .acceptEULAAgreement:
            showEulaButton()
            enableNextButton()
        case .ourPrinciples, .ready:
            enableNextButton()
        case .enterPassword:
            answerTextfieldTwo.alpha = 1
            answerTextfieldTwo.text = ""
            newStackView.insertArrangedSubview(answerTextfieldTwo, at: 3)
        default:
            break
        }
        
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
            
            self.questionLabel.alpha = 1
            self.answerTextfield.alpha = self.signUpFrame.expectAnswer ? 1 : 0
            self.eulaButton.alpha = self.signUpFrame.showEULAButton ? 1 : 0
            
            if self.signUpFrame.showInformationLabel {
                self.showInformationLabel()
            }
            
        }, completion: { (_) in })
    }
    
    private func startLogIn() {
        answerTextfield.text = ""
        nextButton.isEnabled = true
        nextButton.alpha = 0.5
        
        answerTextfield.addTarget(self, action: #selector(textGetsWritten), for: .editingChanged)
        
        answerTextfield.isSecureTextEntry = logInFrame.isSecureTextEntry
        answerTextfield.keyboardType = logInFrame.keyboardType
        questionLabel.text = logInFrame.text
        
        UIView.animate(withDuration: 0.9, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
            self.answerTextfield.alpha = 1
            self.questionLabel.alpha = 1
        })
    }
    
    func showInformationLabel() {
        UIView.animate(withDuration: 0.2) {
            self.informationLabel.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - NextButtonPushed
    
    func isPasswordAccepted() -> Bool {
        guard let input = answerTextfield.text else {
            return false
        }
        
        let answer = input.trimmingCharacters(in: .whitespaces)
        if answer.count >= 6 {
            password = answer
            if answerTextfield.text == answerTextfieldTwo.text {
                return true
            } else {
                questionLabel.text = Strings.repeatPasswordSignUpError
                return false
            }
        } else {
            questionLabel.text = Strings.weakPasswordError
            return false
        }
    }
    
    private func nextSignUpStep() {
        guard let input = answerTextfield.text else {
            return
        }
        
        let answer = input.trimmingCharacters(in: .whitespaces)
        switch signUpFrame{
        case .enterFirstName:
            name = answer
            signUpFrame = .enterUsername
        case .enterUsername, .usernameAlreadyUsed:
            username = answer
            checkIfUsernameAlreadyInUse(answer) { inUse in
                self.signUpFrame = inUse ? .usernameAlreadyUsed : .enterEmail
            }
        case .enterEmail:
            email = answer
            signUpFrame = .enterPassword
        case .enterPassword:
            signUpFrame = .acceptEULAAgreement
        case .emailAlreadyUsed:
            email = answer
            signUpFrame = .enterPassword
        case .invalidEmail:
            email = answer
            signUpFrame = .enterPassword
        case .acceptEULAAgreement:
            signUpFrame = .acceptPrivacyAgreement
        case .acceptPrivacyAgreement:
            tryToSignUp()
            signUpFrame = .wait
            self.view.activityStartAnimating()
        case .ourPrinciples:
            signUpFrame = .ready
        case .ready:
            delegate?.loadUser()
            dismiss(animated: true)
        case .error:
            dismiss(animated: true)
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
    
    private func checkIfUsernameAlreadyInUse(_ username: String, completion: @escaping (Bool) -> Void) {
        let ref = FirestoreReference.collectionRef(.users, queries: FirestoreQuery(field: "username", equalTo: username))
        ref.getDocuments { snapshot, error in
            guard let snapshot = snapshot else {
                completion(false)
                return
            }
            
            completion(!snapshot.documents.isEmpty)
        }
    }
    
    private func nextLogInStep() {
        if let input = answerTextfield.text {
            
            let answer = input.trimmingCharacters(in: .whitespaces)
            
            switch logInFrame {
            case .enterEmail:
                email = answer
                logInFrame = .enterPassword
            case .wrongEmail:
                email = answer
                logInFrame = .enterPassword
            case .enterPassword:
                password = answer
                
                tryToLogIn { user in
                    guard let user = user else {
                        self.startLogIn()
                        return
                    }

                    self.successfullyLoggedIn(with: user)
                }
                
                return
            case .wrongPassword:
                password = answer
                
                tryToLogIn { user in
                    guard let user = user else {
                        self.startLogIn()
                        return
                    }

                    self.successfullyLoggedIn(with: user)
                }
                
                return
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
    
    //MARK: - Try to Sign Up
    
    func tryToSignUp() {
        guard let email = email, let password = password, let name = name, let username = username else {
            return
        }
        
        eulaButton.alpha = 0
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("We have an error: \(error.localizedDescription)")
                
                if let errCode = AuthErrorCode.Code(rawValue: error._code) {
                    
                    switch errCode {
                    case .emailAlreadyInUse:
                        self.signUpFrame = .emailAlreadyUsed
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
                
                guard let user = Auth.auth().currentUser else {
                    return
                }
                let changeRequest = user.createProfileChangeRequest()
                
                changeRequest.displayName = name
                changeRequest.commitChanges { error in
                    guard let error = error else {
                        return
                    }
                    
                    print("Error: We couldnt change the user data: \(error.localizedDescription)")
                }
                
                let userRef = FirestoreReference.documentRef(.users, documentID: user.uid)
                let data: [String:Any] = ["name": name, "username": username, "createdAt": Timestamp(date: Date())]
                
                userRef.setData(data) { error in
                    guard let error = error else {
                        
                        self.signUpFrame = .ourPrinciples
                        self.view.activityStopAnimating()
                        self.startSignUpSession()
                        
                        self.notifyMalte(name: name)
                        
                        user.sendEmailVerification { error in
                            guard let error = error else {
                                return
                            }
                            
                            print("We have an error: \(error.localizedDescription)")
                        }
                        
                        return
                    }
                    
                    print("We got an error uploading the user: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func notifyMalte(name: String) {
        let reference = FirestoreReference.documentRef(.users, documentID: nil, collectionReferences: FirestoreCollectionReference(document: Constants.userIDs.uidMalte, collection: "notifications"))
        let notificationData: [String: Any] = ["type": "message", "message": "Wir haben einen neuen User: \(name)", "name": "System", "chatID": "Egal", "sentAt": Timestamp(date: Date()), "messageID": "Dont Know", "language": LanguageSelection.language.rawValue]
        
        
        reference.setData(notificationData) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                print("Successfully set notification")
            }
        }
    }
    
    //MARK: - Try to log in
    
    func tryToLogIn(completion: @escaping (FirebaseAuth.User?) -> Void) {
        guard let email = email, let password = password else {
            completion(nil)
            self.view.activityStopAnimating()
            return
        }
        
        view.activityStartAnimating()
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            
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
                    
                    self.view.activityStopAnimating()
                    completion(nil)
                }
            } else {
                guard let result = result else {
                    return
                }
                
                completion(result.user)
            }
        }
    }
    
    private func successfullyLoggedIn(with user: FirebaseAuth.User) {
        guard let email = email else {
            return
        }

        if !user.isEmailVerified {
            print("Not yet verified")
            self.tryToLogOut()
            self.view.activityStopAnimating()
            
            self.showVerificationAlert(for: user, email: email)
        } else {
            print("User wurde erfolgreich eingeloggt.")
            
            AuthenticationManager.shared.logIn { _ in
                self.delegate?.loadUser()
                self.dismiss(animated: true)
                self.view.activityStopAnimating()
            }
        }
    }
    
    private func showVerificationAlert(for user: FirebaseAuth.User, email: String) {
        
        let alertVC = UIAlertController(title: Strings.error, message: String.localizedStringWithFormat(Strings.verifyMailAlert, email), preferredStyle: .alert)
        let alertActionOkay = UIAlertAction(title: Strings.okay, style: .default) { _ in
            user.sendEmailVerification { err in
                
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    self.alert(message: Strings.verifyMailSentAlert)
                    self.dismiss(animated: true)
                }
            }
        }
        let alertActionCancel = UIAlertAction(title: Strings.cancel, style: .cancel) { _ in
            self.dismiss(animated: true)
        }
        
        alertVC.addAction(alertActionOkay)
        alertVC.addAction(alertActionCancel)
        self.present(alertVC, animated: true)
    }
    
    private func resetPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            guard let error = error else {
                self.alert(message: Strings.resetPasswordAlertMessage, title: Strings.resetPasswordAlertTitle)
                return
            }
            
            self.logInFrame = .wrongEmail
            self.startLogIn()
            
            print("We have an error: \(error.localizedDescription)")
        }
    }
    
    private func tryToLogOut() {
        do {
            try Auth.auth().signOut()
            print("Log Out successful")
        } catch {
            print("Log Out not successfull")
        }
    }
    
    
    //MARK: - Functions
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
        let language = LanguageSelection.language
        var urlString: String
        
        switch signUpFrame {
        case .acceptPrivacyAgreement:
            urlString = language == .en ? "https://en.imagine.social/datenschutzerklaerung-app" : "https://imagine.social/datenschutzerklaerung-app"
        default:
            urlString = language == .en ? "https://en.imagine.social/eula" : "https://imagine.social/eula"
        }
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        UIApplication.shared.open(url)
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
    
    
    // MARK: - IBActions
    
    @objc func nextButtonPushed(sender: DesignableButton) {
        
        if signUpFrame == .enterPassword && !isPasswordAccepted() {
            return
        }
        
        if loginType == .signup, signUpFrame.expectAnswer, let text = answerTextfield.text, text.isEmpty {
            return
        }
        
        nextButton.isEnabled = false
        answerTextfield.resignFirstResponder()
        
        switch loginType {
        case .login:
            nextLogInStep()
        case .signup:
            nextSignUpStep()
        }
    }
    
    @IBAction func logInTouched(_ sender: Any) {
        
        loginType = .login
        startTheProcess {
            self.startLogIn()
        }
    }
    
    
    @IBAction func signUpTouched(_ sender: Any) {
        
        loginType = .signup
        signUpInProgress = true
        
        answerTextfield.addTarget(self, action: #selector(textGetsWritten), for: .editingChanged)
        answerTextfieldTwo.addTarget(self, action: #selector(textGetsWritten), for: .editingChanged)
        
        startTheProcess {
            self.startSignUpSession()
        }
    }
    
    private func startTheProcess(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 1, animations: {
            self.initialStackView.alpha = 0
            self.peaceSignView.alpha = 0.4
        }) { (_) in
            self.initialStackView.isHidden = true
            self.setUpNewStackViewUI()
            completion()
        }
    }
    
    
    @IBAction func cancelTapped(_ sender: Any) {
        if signUpInProgress && signUpFrame != .enterFirstName {
            let alertController = UIAlertController(title: Strings.cancelSignUpAlertTitle, message: Strings.cancelSignUpAlertMessage, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: Strings.cancelSignUpConfirmation, style: .destructive, handler: { (_) in
                self.dismiss(animated: true)
                
            })
            let stayAction = UIAlertAction(title: Strings.cancelSignUpAbort, style: .cancel) { (_) in
                alertController.dismiss(animated: true)
            }
            alertController.addAction(cancelAction)
            alertController.addAction(stayAction)
            self.present(alertController, animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }
    
    
    // MARK: - UIElements
    
    let eulaButton: DesignableButton = {
        let button = DesignableButton(title: Strings.toGDPRButtonTitle, font: UIFont.standard(size: 14), cornerRadius: 6, tintColor: .white, backgroundColor: .imagineColor)
        
        button.addTarget(self, action: #selector(toEulaTapped), for: .touchUpInside)
        
        return button
    }()
    
    let resetPasswordButton: DesignableButton = {
        let button = DesignableButton(title: Strings.forgotPasswordButtonTitle, font: UIFont.standard(with: .medium, size: 10), cornerRadius: 4, tintColor: .imagineColor)
        
        button.addTarget(self, action: #selector(resetPasswordTapped), for: .touchUpInside)
        
        return button
    }()
    
    
    let questionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.standard(size: 22)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 0
        label.lineBreakMode = .byClipping
        label.textAlignment = .center
        label.alpha = 0     // Erstmal unsichtbar
        
        return label
    }()
    
    static func getTextFieldWithUnderline() -> UITextField {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textAlignment = .left
        textField.borderStyle = .none
        textField.font = UIFont(name: "IBMPlexSans", size: 18)
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        let underline = UIView()
        underline.translatesAutoresizingMaskIntoConstraints = false
        underline.backgroundColor = .secondaryLabel
        
        textField.addSubview(underline)
        underline.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        underline.trailingAnchor.constraint(equalTo: textField.trailingAnchor).isActive = true
        underline.bottomAnchor.constraint(equalTo: textField.bottomAnchor).isActive = true
        underline.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        return textField
    }
    
    let answerTextfield: UITextField = {
        let textField = getTextFieldWithUnderline()
        textField.placeholder = "..."
        textField.alpha = 0
        textField.addTarget(self, action: #selector(textGetsWritten), for: .editingChanged)
        
        return textField
    }()
    
    let answerTextfieldTwo: UITextField = {
        let textField = getTextFieldWithUnderline()
        
        textField.placeholder = Strings.repeatPasswordPlaceholder
        textField.isSecureTextEntry = true
        textField.textContentType = .newPassword
        
        return textField
    }()
    
    let informationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.standard(size: 11)
        label.textColor = UIColor.secondaryLabel
        label.alpha = 1
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.layoutIfNeeded()
        label.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        return label
    }()
    
    let nextButton: DesignableButton = {
        let button = DesignableButton(title: Strings.next, font: UIFont.standard(size: 18))
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
        
        view.addSubview(newStackView)
        newStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        newStackView.topAnchor.constraint(equalTo: peaceSignView.bottomAnchor, constant: 20).isActive = true
        newStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -75).isActive = true
        
        view.addSubview(nextButton)
        nextButton.trailingAnchor.constraint(equalTo: newStackView.trailingAnchor).isActive = true
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
}

extension LogInViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // This is a backspace
        if string == "" {
            return true
        }
        
        let character = string.trimmingCharacters(in: .whitespaces)
        guard let text = textField.text, !character.isEmpty else {
            return false
        }

        let isUsernameInput = signUpFrame == .enterUsername || signUpFrame == .usernameAlreadyUsed
        if loginType == .signup, isUsernameInput, text.first == nil {
            textField.text = "@\(text)"
        }
        
        textField.text = textField.text!.trimmingCharacters(in: .whitespaces)
        
        return true
    }
}
