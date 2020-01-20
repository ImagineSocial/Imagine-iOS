//
//  LogInViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

enum LogInFrame {
    case enterEmail
    case enterPassword
    case wrongPassword
    case wrongEmail
    case forgotPassword
}

enum SignUpFrame {
    case enterFirstName
    case enterLastName
    case enterEmail
    case invalidEmail
    case EmailAlreadyInUse
    case enterPassword
    case repeatPassword
    case wrongRepeatedPassword
    case weakPassword
    case respectYourFellowMan
    case keepCalm
    case supportImagine
    case ready
    case acceptEULA
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
    
    let attentionLabel = UILabel()
    let db = Firestore.firestore()
    
    var signUp = false
    var name = ""
    var surname = ""
    var signUpAnswers:[String:String] = ["":""]
    var email = ""
    var password = ""
    var logInFrame: LogInFrame = .enterEmail
    var signUpFrame: SignUpFrame = .enterFirstName
    var signUpInProgress = false
    
    let maltesUID = "CZOcL3VIwMemWwEfutKXGAfdlLy1"
    
    var delegate:DismissDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
  
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        answerTextfield.resignFirstResponder()
    }
    
    //MARK: - SignUp & LogIn Sessions
    
    func startSignUpSession() {
        
        signUpInProgress = true
        answerTextfield.text = ""
        nextButton.isEnabled = true
        answerTextfield.addTarget(self, action: #selector(textGetsWritten), for: .editingChanged)
        
        switch signUpFrame {
        case .enterFirstName:
            answerTextfield.textContentType = .givenName
            questionLabel.text = NSLocalizedString("Child of earth, what is your name?", comment: "Enter your name (with a 'too much' touch)")
            informationLabel.text = "Dein gewählter Vorname wird auf deinem Profil & in deinen Beiträgen für \"Fremde\" sichtbar sein"
        case .enterLastName:
            answerTextfield.textContentType = .familyName
                let surnameText = NSLocalizedString("Glad to meet you %@. What is the name of your family?", comment: "Enter your surname (with a 'too much' touch)")
            print("name:", name)
            questionLabel.text = String.localizedStringWithFormat(surnameText, name)
            informationLabel.text = "Dein Nachname wird nur für deine Freunde auf Imagine sichtbar sein" //und in der User-Suche (um Freunde zu finden)
        case .enterEmail:
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
            questionLabel.text = "Wie ist deine Email-Adresse?"
        case .invalidEmail:
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
            questionLabel.text = "Die angegebene Email-Adresse scheint nicht korrekt zu sein. Gib sie bitte erneut ein:"
        case .EmailAlreadyInUse:
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
            questionLabel.text = "Die Email-Adresse wird bereits bei uns verwendet. Bitte nutze eine andere:"
        case .enterPassword:
            answerTextfield.textContentType = .newPassword
            answerTextfield.isSecureTextEntry = true
            questionLabel.text = "Wie soll dein Passwort sein?"
            informationLabel.text = "Das Passwort muss mindestens 6 Zeichen haben, und schon ein bisschen sicher sein!"
        case .weakPassword:
            answerTextfield.textContentType = .newPassword
            answerTextfield.isSecureTextEntry = true
            questionLabel.text = "Dein Passwort ist zu schwach. Es muss mindestens 6 Buchstaben haben und schon ein bisschen sicher sein"
        case .repeatPassword:
            answerTextfield.textContentType = .newPassword
            answerTextfield.isSecureTextEntry = true
            questionLabel.text = "Wiederhole zur Sicherheit dein Passwort"
        case .wrongRepeatedPassword:
            answerTextfield.textContentType = .newPassword
            answerTextfield.isSecureTextEntry = true
            questionLabel.text = "Deine beiden Passwörter stimmen nicht überein. Versuch es bitte noch einmal:"
        case .keepCalm: // Is set in "tryTOSignUp
            eulaButton.isHidden = true
            answerTextfield.isEnabled = true
            answerTextfield.textContentType = .none
            answerTextfield.isSecureTextEntry = false
            questionLabel.text = "Herzlich Willkommen bei Imagine. Wir wollen eine respektvolle Stimmung bei Imagine bewahren. Daher wollen wir beleidigende und verletzende Aussagen aus dem Netzwerk fernhalten. Ok?"
            nextButton.setTitle("Weiter", for: .normal)
        case .respectYourFellowMan:
            answerTextfield.isSecureTextEntry = false
            questionLabel.text = "Wirst du die Ansichten und Meinungen deiner Mit-User respektieren, auch wenn diese sich von deinen Unterscheiden?"
        case .supportImagine:
            questionLabel.text = "Wirst du Ungerechtigkeiten und Verstöße gegen die eben genannten Regeln melden und die Stimmung bei Imagine gerecht und einvernehmlich halten?"
        case .ready:
            questionLabel.text = "Super. Wir freuen uns dich bei uns zu begrüßen! Schau dich ein wenig um und vergiss nicht deine Email Adresse zu bestätigen🙏 (vielleicht Spam Ordner)"
            nextButton.setTitle("Zu Imagine", for: .normal)
        case .error:
            questionLabel.text = "Irgendwas ist hier kaputt, versuch es bitte später nochmal!"
        case .acceptEULA:
            self.nextButton.alpha = 1
            self.answerTextfield.alpha = 0
            self.informationLabel.alpha = 0
            self.answerTextfield.isEnabled = false
            questionLabel.text = "Stimmst du den Apple Nutzungsbedingungen zu und lädst keine unangebrachten Inhalte hoch?"
            nextButton.setTitle("Ich stimme zu", for: .normal)
            showEulaButton()
        case .wait:
            print("Waitin'")
        }
        UIView.animate(withDuration: 0.9, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
        self.answerTextfield.alpha = 1
        self.questionLabel.alpha = 1
        }, completion: { (_) in
            
            switch self.signUpFrame {
            case .enterFirstName:
                self.showInformationLabel()
            case .enterLastName:
                self.showInformationLabel()
            case .enterPassword:
                self.showInformationLabel()
            default:
                print("Nothing")
            }
        })
    }

    func showInformationLabel() {
        UIView.animate(withDuration: 0.2) {
            self.informationLabel.alpha = 1
        }
    }
    
    func startLogIn() {
        answerTextfield.text = ""
        nextButton.isEnabled = true
        
        switch logInFrame {
        case .enterEmail:
            questionLabel.text = "Kind der Erde, wie lautet deine Email-Adresse?"
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
        case .enterPassword:
            questionLabel.text = "Nun noch dein Kennwort und wir können loslegen!"
            answerTextfield.textContentType = .password
            answerTextfield.isSecureTextEntry = true
            resetPasswordButton.isHidden = false
        case .wrongEmail:
            self.questionLabel.text = "Deine eingegebene Email-Adresse ist nicht korrekt"
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
        case .wrongPassword:
            self.questionLabel.text = "Dein Passwort ist nicht korrekt, versuche es erneut:"
            answerTextfield.textContentType = .password
            answerTextfield.isSecureTextEntry = true
            resetPasswordButton.isHidden = false
        case .forgotPassword:
            questionLabel.text = "Gib deine EmailAdresse ein, damit wir dir eine Mail zum zurücksetzen deines Passwortes senden können."
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
        }
        UIView.animate(withDuration: 0.9, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
            self.answerTextfield.alpha = 1
            self.questionLabel.alpha = 1
        })
        
    }
    
    // MARK: - NextButtonTapped
    
    @objc func nextButtonPushed(sender: DesignableButton!) {
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
                    if answer.count >= 6 {
                        password = answer
                        signUpFrame = .repeatPassword
                    } else {
                        signUpFrame = .weakPassword
                    }
                case .weakPassword:
                    if answer.count >= 6 {
                        password = answer
                        signUpFrame = .repeatPassword
                    } else {
                        signUpFrame = .weakPassword
                    }
                case .repeatPassword:
                    if password == answer {
                        self.signUpFrame = .acceptEULA
                    } else {
                        self.signUpFrame = .wrongRepeatedPassword
                    }
                case .wrongRepeatedPassword:
                    password = answer
                    signUpFrame = .repeatPassword
                case .EmailAlreadyInUse:
                    email = answer
                    signUpFrame = .enterPassword
                case .invalidEmail:
                    email = answer
                    signUpFrame = .enterPassword
                case .keepCalm:
                    signUpFrame = .respectYourFellowMan
                // ToDo: Save the Answer
                case .respectYourFellowMan:
                    signUpFrame = .supportImagine
                // ToDo: Save the Answer
                case .supportImagine:
                    signUpFrame = .ready
                case .acceptEULA:
                    tryToSignUp()
                    self.signUpFrame = .wait
                    print("Zu dings schicken")
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
                    self.informationLabel.alpha = 0
                    self.nextButton.alpha = 0
                    self.questionLabel.alpha = 0
                }, completion: { (_) in
        
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
                self.nextButton.alpha = 0
                self.questionLabel.alpha = 0
            }, completion: { (_) in
                
                self.startLogIn()
                
            })
        }
        print(signUpAnswers)
    }
    
    //MARK: - Try to Sign Up
    
    func tryToSignUp() {
        print("Hier zum registrieren")
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("We have an error: \(error.localizedDescription)")
                
                if let errCode = AuthErrorCode(rawValue: error._code) {
                    
                    switch errCode {
                    case .emailAlreadyInUse:
                        self.signUpFrame = .EmailAlreadyInUse
                    case .invalidEmail:
                        self.signUpFrame = .invalidEmail
                    case .weakPassword:
                        self.signUpFrame = .weakPassword
                    default:
                        self.signUpFrame = .error
                    }
                    self.view.activityStopAnimating()
                    self.startSignUpSession()
                }
            } else {
                print("User wurde erfolgreich erstellt.")
                
                Analytics.logEvent(AnalyticsEventSignUp, parameters: [
                    AnalyticsParameterMethod: "email"
                ])
                
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
                    let data: [String:Any] = ["name": self.name, "surname": self.surname, "full_name": fullName, "createDate": Timestamp(date: Date())] //"username": self.displayName,
                    
                    userRef.setData(data, completion: { (error) in
                        if let error = error {
                            print("We have an error: \(error.localizedDescription)")
                        } else {
                            print("User wurde in Datenbank übertragen")
                            self.signUpFrame = .keepCalm
                            self.view.activityStopAnimating()
                            self.startSignUpSession()
                            
                            self.notifyMalte(name: fullName)
                            self.addMalteAsAFriend(userID: user.uid)
                            
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
    
    func addMalteAsAFriend(userID: String) {
        let friendsRef = db.collection("Users").document(userID).collection("friends").document(maltesUID)
        let data: [String:Any] = ["accepted": true, "requestedAt" : Timestamp(date: Date())]
        
        friendsRef.setData(data) { (error) in
            if error != nil {
                print("We couldnt add as Friend: Error \(error?.localizedDescription ?? "No error")")
            } else {
               print("Malte is now your friend")
            }
        }
    }
    
    func notifyMalte(name: String) {
        let notificationRef = db.collection("Users").document(maltesUID).collection("notifications").document()
        let notificationData: [String: Any] = ["type": "message", "message": "Wir haben einen neuen User: \(name)", "name": "System", "chatID": "Egal", "sentAt": Timestamp(date: Date()), "messageID": "Dont Know"]
        
        
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
                if let errCode = AuthErrorCode(rawValue: error._code) {
                    
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
                        
                        let alertVC = UIAlertController(title: "Error", message: "Deine Email Adresse wurde noch nicht verifiziert. Sollen wir dir erneut eine Bestätigungs Email an \(self.email) senden?", preferredStyle: .alert)
                        let alertActionOkay = UIAlertAction(title: "Okay", style: .default) {
                            (_) in
                            result.user.sendEmailVerification { (err) in
                                                                
                                if let error = err {
                                    print("We have an error: \(error.localizedDescription)")
                                } else {
                                    self.alert(message: "Der Link wurde verschickt")
                                    self.dismiss(animated: true, completion: nil)
                                }
                            }
                        }
                        let alertActionCancel = UIAlertAction(title: "Abbrechen", style: .cancel) { (_) in
                            self.dismiss(animated: true, completion: nil)
                        }

                        alertVC.addAction(alertActionOkay)
                        alertVC.addAction(alertActionCancel)
                        self.present(alertVC, animated: true, completion: nil)
                    } else {
                        print("User wurde erfolgreich eingeloggt.")
                        
                        Analytics.logEvent(AnalyticsEventLogin, parameters: [
                        AnalyticsParameterMethod: "email"
                        ])
                    
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
                if let errCode = AuthErrorCode(rawValue: error._code) {
                    
                    switch errCode {
                    case .invalidEmail:
                        self.logInFrame = .wrongEmail
                        
                    default:
                        self.logInFrame = .wrongEmail
                    }
                    self.startLogIn()
                }
            } else {
                self.alert(message: "Die E-Mail wurde gesendet", title: "Schau in dein Postfach, ändere dein Passwort und versuche es erneut. Bis gleich!")
                
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
        eulaButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        eulaButton.topAnchor.constraint(equalTo: nextButton.bottomAnchor, constant: 25).isActive = true
        eulaButton.widthAnchor.constraint(equalToConstant: 180).isActive = true
        eulaButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
    }
    @objc func toEulaTapped() {
        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
            UIApplication.shared.open(url)
        }
    }
    
    let eulaButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.cornerRadius = 4
        button.backgroundColor = Constants.imagineColor
        button.setTitle("Zur Vereinbarung", for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 18)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(toEulaTapped), for: .touchUpInside)
        
        return button
    }()
    
    let resetPasswordButton: DesignableButton = {
       let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.cornerRadius = 4
        button.clipsToBounds = true
        button.setTitle("Passwort vergessen", for: .normal)
        button.setTitleColor(Constants.imagineColor, for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 10)
        button.addTarget(self, action: #selector(resetPasswordTapped), for: .touchUpInside)
        
        return button
    }()
    
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
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
            self.nextButton.alpha = 1
        })
    }
    
    
    let questionLabel: UILabel = {
       let label = UILabel()
        label.font = UIFont(name: "IBMPlexSans", size: 26)
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
        textField.textAlignment = .center
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        textField.font = UIFont(name: "IBMPlexSans", size: 18)
        textField.placeholder = "..."
        textField.autocorrectionType = .no
        textField.alpha = 0
        textField.addTarget(self, action: #selector(textGetsWritten), for: .editingChanged)

        return textField
    }()
    
    let informationLabel: UILabel = {
       let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont(name: "IBMPlexSans", size:11)
        if #available(iOS 13.0, *) {
            label.textColor = UIColor.secondaryLabel
        } else {
            label.textColor = .lightGray
        }
        label.alpha = 0
        label.text = ""
        label.numberOfLines = 0
        
        return label
    }()
    
    let nextButton: DesignableButton = {
       let button = DesignableButton()
        button.layer.cornerRadius = 5
        button.backgroundColor = Constants.imagineColor
        button.tag = 0
        button.setTitle("Weiter", for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 22)
        button.alpha = 0
        button.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        return button
    }()
    
    func setUpUI() {
        
        let newStackView = UIStackView(arrangedSubviews: [questionLabel, informationLabel, answerTextfield,nextButton])
        newStackView.axis = .vertical
        newStackView.distribution = .fillProportionally
        newStackView.spacing = 20
        
        view.addSubview(newStackView)
        newStackView.translatesAutoresizingMaskIntoConstraints = false  // Enables AutoLayout
        newStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        newStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100).isActive = true
        newStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -75).isActive = true
        //nextButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        questionLabel.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        showResetPasswordButton()
    }
    
    
    @IBAction func logInTouched(_ sender: Any) {
        if signUp { // Wenn die Button sich geändert haben
            UIView.animate(withDuration: 1.5, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.initialStackView.alpha = 0
                self.attentionLabel.alpha = 0
                self.peaceSignView.alpha = 0.3
                
//                if let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as? UIView{
//                    statusBar.alpha = 0
//                }
                
            }, completion: { (_) in
                self.initialStackView.isHidden = true
                self.attentionLabel.isHidden = true
                self.setUpUI()
                self.startSignUpSession()
            })
        } else {
            //Start Log-In
            UIView.animate(withDuration: 1.5, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.initialStackView.alpha = 0
                self.peaceSignView.alpha = 0.3
                
//                if let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as? UIView{
//                    statusBar.alpha = 0
//                }
                
            }, completion: { (_) in
                self.initialStackView.isHidden = true
                self.setUpUI()
                self.startLogIn()
            })
        }
    }
    
    
    @IBAction func signUpTouched(_ sender: Any) {
        
        if signUp { // Wenn der Button sich geändert haben
            UIView.animate(withDuration: 1.5, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.initialStackView.alpha = 0
                self.attentionLabel.alpha = 0
                
                
            }, completion: { (_) in
                self.dismiss(animated: true, completion: nil)
            })
        } else {
            // Erster Schritt
            UIView.animate(withDuration: 2.0, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
                self.initialStackView.alpha = 0
                self.peaceSignView.alpha = 0.5
                self.signUp = true  // Button verändern sich
                
            }, completion: { (_) in
                self.initialButton2.backgroundColor = UIColor(red:1.00, green:0.54, blue:0.52, alpha:1.0)
                self.initialLabel.text = "Willkommen bei Imagine. Lass uns das Ritual starten und dich in unserer Gemeinschaft aufnehmen! Vergiss nicht ehrlich zu sein und ganz du selbst!"
                self.initialButton1.setTitle("Ich bin bereit!", for: .normal)
                self.initialButton2.setTitle("Lieber Später!", for: .normal)
                self.initialButton2.backgroundColor = UIColor(red:1.00, green:0.54, blue:0.52, alpha:1.0)
                //  Achtung Label
//                self.view.addSubview(self.attentionLabel)
//                self.attentionLabel.alpha = 0
//                self.attentionLabel.translatesAutoresizingMaskIntoConstraints = false
//                self.attentionLabel.centerXAnchor.constraint(equalTo: self.initialStackView.centerXAnchor, constant: 0).isActive = true
//                self.attentionLabel.topAnchor.constraint(equalTo: self.initialStackView.topAnchor, constant: -55).isActive = true
//                self.attentionLabel.text = ""
//                self.attentionLabel.font = UIFont(name: "IBMPlexSans", size: 30)
//                self.attentionLabel.shadowColor = UIColor.white
//                self.attentionLabel.shadowOffset = CGSize(width: 3, height: -1)
                
                self.initialLabelConstraint.constant = 150
                
                // Zweiter Schritt
                UIView.animate(withDuration: 0.9, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    self.attentionLabel.alpha = 1
                    self.view.layoutIfNeeded()
                }, completion: { (_) in
                    //Dritter Schritt
                    UIView.animate(withDuration: 0.9, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
                        self.initialStackView.alpha = 1
                    })
                })
            })
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
//        if let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as? UIView{
//            statusBar.alpha = 1
//        }
    }
    
    
    @IBAction func cancelTapped(_ sender: Any) {
        if signUpInProgress {
            let alertController = UIAlertController(title: "Anmeldung abbrechen?", message: "Möchtest du die Anmeldung abbrechen? Die aktuellen Eingaben gehen verloren.", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Anmeldung abbrechen", style: .destructive, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
            })
            let stayAction = UIAlertAction(title: "Hier bleiben", style: .cancel) { (_) in
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
