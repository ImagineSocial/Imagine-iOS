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
}

enum SignInFrame {
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
    
    var signUp = false
    var name = ""
    var surname = ""
    var signUpAnswers:[String:String] = ["":""]
    var email = ""
    var password = ""
    var logInFrame: LogInFrame = .enterEmail
    var signUpFrame: SignInFrame = .enterFirstName
    var signUpInProgress = false
    
    var delegate:DismissDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
  
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        answerTextfield.resignFirstResponder()
    }
    
    
    func startSignUpSession() {
        signUpInProgress = true
        answerTextfield.text = ""
        nextButton.isEnabled = true
        answerTextfield.addTarget(self, action: #selector(textGetsWritten), for: .editingChanged)
        
        switch signUpFrame {
        case .enterFirstName:
            answerTextfield.textContentType = .givenName
            questionLabel.text = NSLocalizedString("Child of earth, what is your name?", comment: "Enter your name (with a 'too much' touch)")
        case .enterLastName:
            answerTextfield.textContentType = .familyName
                let surnameText = NSLocalizedString("Glad to meet you %@. What is the name of your family?", comment: "Enter your surname (with a 'too much' touch)")
            print("name:", name)
            questionLabel.text = String.localizedStringWithFormat(surnameText, name)
        case .enterEmail:
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
            questionLabel.text = "Wie ist deine Email-Adresse?"
        case .invalidEmail:
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
            questionLabel.text = "Die angegebene Email-Adresse scheint nicht korrekt zu sein. Gib sie noch einmal ein:"
        case .EmailAlreadyInUse:
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
            questionLabel.text = "Die Email-Adresse wird bereits bei uns verwendet. Bitte nutze eine andere:"
        case .enterPassword:
            answerTextfield.textContentType = .newPassword
            answerTextfield.isSecureTextEntry = true
            questionLabel.text = "Wie soll dein Passwort sein?"
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
            answerTextfield.textContentType = .none
            answerTextfield.isSecureTextEntry = false
            questionLabel.text = "Wirst du Ruhe bewahren wenn dich etwas oder jemand bei Imagine aufregt und keine verletzenden Begriffe nutzen?"
        case .respectYourFellowMan:
            answerTextfield.isSecureTextEntry = false
            questionLabel.text = "Wirst du die Ansichten und Meinungen deiner Mit-User respektieren?"
        case .supportImagine:
            questionLabel.text = "Würdest du Imagine als Netzwerk unterstützen und melden, upvoten und schlichten wenn es angebracht ist? "
        case .ready:
            questionLabel.text = "Wir freuen uns dich bei uns zu begrüßen! Schau dich doch ein wenig um"
            nextButton.setTitle("Zu Imagine", for: .normal)
        case .error:
            questionLabel.text = "Irgendwas ist hier kaputt, versuch es bitte später nochmal!"
        }
        
        UIView.animate(withDuration: 1.3, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
            self.answerTextfield.alpha = 1
            self.questionLabel.alpha = 1
        })
        
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
        case .wrongEmail:
            self.questionLabel.text = "Deine eingegebene Email-Adresse ist nicht korrekt"
            answerTextfield.textContentType = .emailAddress
            answerTextfield.isSecureTextEntry = false
        case .wrongPassword:
            self.questionLabel.text = "Dein Passwort oder deine Email-Adresse ist nicht korrekt"
            answerTextfield.textContentType = .password
            answerTextfield.isSecureTextEntry = true
        }
        
        UIView.animate(withDuration: 1.3, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
            self.answerTextfield.alpha = 1
            self.questionLabel.alpha = 1
        })
        
    }
    
    @objc func textGetsWritten() {
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
            self.nextButton.alpha = 1
        })
    }
    
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
                        self.tryToSignUp()
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
                // ToDo: Save the Answer
                case .ready:
                    self.delegate?.loadUser()
                    self.dismiss(animated: true, completion: nil)
                case .error:
                    self.dismiss(animated: true, completion: nil)
                }
                
                UIView.animate(withDuration: 1.3, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
                    self.answerTextfield.alpha = 0
                    self.nextButton.alpha = 0
                    self.questionLabel.alpha = 0
                }, completion: { (_) in
        
                    self.startSignUpSession()
                    
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
                }
            }
            
            UIView.animate(withDuration: 1.3, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
                self.answerTextfield.alpha = 0
                self.nextButton.alpha = 0
                self.questionLabel.alpha = 0
            }, completion: { (_) in
                
                self.startLogIn()
                
            })
        }
        print(signUpAnswers)
    }
    
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
                
                    let userRef = Firestore.firestore().collection("Users").document(user.uid)
                    let data = ["name": self.name, "surname": self.surname, "full_name": fullName]
                    
                    userRef.setData(data, completion: { (error) in
                        if let error = error {
                            print("We have an error: \(error.localizedDescription)")
                        } else {
                            print("User wurde in Datenbank übertragen")
                            self.signUpFrame = .keepCalm
                            self.startSignUpSession()
                        }
                    })
                }
            }
        }
        
    }
    
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
                print("User wurde erfolgreich eingeloggt.")
                self.delegate?.loadUser()
                self.dismiss(animated: true, completion: nil)
            }
        }
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
    
    let nextButton: DesignableButton = {
       let button = DesignableButton()
        button.layer.cornerRadius = 5
        button.backgroundColor = UIColor(red:0.19, green:0.82, blue:1.00, alpha:1.0)
        button.tag = 0
        button.setTitle("Weiter", for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 22)
        button.alpha = 0
        button.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        return button
    }()
    
    func setUpUI() {
        
        let newStackView = UIStackView(arrangedSubviews: [questionLabel,answerTextfield,nextButton])
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
        
    }
    
    
    @IBAction func logInTouched(_ sender: Any) {
        if signUp { // Wenn die Button sich geändert haben
            UIView.animate(withDuration: 2, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.initialStackView.alpha = 0
                self.attentionLabel.alpha = 0
                self.peaceSignView.alpha = 0.3
                
                if let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as? UIView{
                    statusBar.alpha = 0
                }
                
            }, completion: { (_) in
                self.initialStackView.isHidden = true
                self.attentionLabel.isHidden = true
                self.setUpUI()
                self.startSignUpSession()
            })
        } else {
            //Start Log-In
            
            UIView.animate(withDuration: 2, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.initialStackView.alpha = 0
                self.peaceSignView.alpha = 0.3
                
                if let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as? UIView{
                    statusBar.alpha = 0
                }
                
            }, completion: { (_) in
                self.initialStackView.isHidden = true
                self.setUpUI()
                self.startLogIn()
            })
        }
    }
    
    
    @IBAction func signUpTouched(_ sender: Any) {
        
        if signUp { // Wenn der Button sich geändert haben
            
            UIView.animate(withDuration: 2, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.initialStackView.alpha = 0
                self.attentionLabel.alpha = 0
                
                
            }, completion: { (_) in
                self.dismiss(animated: true, completion: nil)
            })
        } else {
            // Erster Schritt
            UIView.animate(withDuration: 3, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
                self.initialStackView.alpha = 0
                self.peaceSignView.alpha = 0.5
                self.signUp = true  // Button verändern sich
                
            }, completion: { (_) in
                self.initialButton2.backgroundColor = UIColor(red:1.00, green:0.54, blue:0.52, alpha:1.0)
                self.initialLabel.text = "Das ist Imagine. Erweise dich als würdig und wir nehmen dich gerne bei uns auf! Nimm dir Zeit dafür. Sei ehrlich und du selbst!"
                self.initialButton1.setTitle("Ich bin bereit!", for: .normal)
                self.initialButton2.setTitle("Lieber Später!", for: .normal)
                self.initialButton2.backgroundColor = UIColor(red:1.00, green:0.54, blue:0.52, alpha:1.0)
                //  Achtung Label
                self.view.addSubview(self.attentionLabel)
                self.attentionLabel.alpha = 0
                self.attentionLabel.translatesAutoresizingMaskIntoConstraints = false
                self.attentionLabel.centerXAnchor.constraint(equalTo: self.initialStackView.centerXAnchor, constant: 0).isActive = true
                self.attentionLabel.topAnchor.constraint(equalTo: self.initialStackView.topAnchor, constant: -55).isActive = true
                self.attentionLabel.text = "Achtung!"
                self.attentionLabel.font = UIFont(name: "IBMPlexSans", size: 30)
                self.attentionLabel.shadowColor = UIColor.white
                self.attentionLabel.shadowOffset = CGSize(width: 3, height: -1)
                
                self.initialLabelConstraint.constant = 150
                
                // Zweiter Schritt
                UIView.animate(withDuration: 1.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    self.attentionLabel.alpha = 1
                    self.view.layoutIfNeeded()
                }, completion: { (_) in
                    //Dritter Schritt
                    UIView.animate(withDuration: 1.3, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
                        self.initialStackView.alpha = 1
                    })
                })
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as? UIView{
            statusBar.alpha = 1
        }
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
