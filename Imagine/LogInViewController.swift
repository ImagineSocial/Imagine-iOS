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

class LogInViewController: UIViewController {
    
    @IBOutlet weak var LogInNavigationBar: UINavigationBar!
    @IBOutlet weak var initialStackView: UIStackView!
    @IBOutlet weak var initialLabel: UILabel!
    @IBOutlet weak var initialLabelConstraint: NSLayoutConstraint!
    @IBOutlet weak var initialButton1: DesignableButton!
    @IBOutlet weak var initialButton2: DesignableButton!
    @IBOutlet weak var peaceSignView: UIImageView!
    @IBOutlet weak var topDismissButton: DesignableButton!
    
    let attentionLabel = UILabel()
    let questionLabel = UILabel()
    let answerTextfield = UITextField()
    let nextButton = DesignableButton()
    
    var signUp = false
    var name = ""
    var surname = ""
    var signUpFrame = 0
    var logInFrame = 0
    var signUpAnswers:[String:String] = ["":""]
    var email = ""
    var password = ""
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topDismissButton.alpha = 0
        topDismissButton.isHidden = true
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        answerTextfield.resignFirstResponder()
    }
    
    
    func startSignUpSession() {
        answerTextfield.text = ""
        nextButton.isEnabled = true
        answerTextfield.addTarget(self, action: #selector(textGetsWritten), for: .editingChanged)
        
        switch signUpFrame {
        case 0:
            questionLabel.text = "Kind der Erde, welcher Name wurde dir zugewiesen?"
            nextButton.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        case 1:
            questionLabel.text = "Freut mich dich kennenzulernen \(name). Welchen Namen führt deine Familie?"
            nextButton.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        case 2:
            questionLabel.text = "Wie ist deine Email-Adresse?"
            nextButton.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        case 3:
            if password != "" { // Also schon versucht
                questionLabel.text = "Dein Passwort muss mindestens 6 Buchstaben haben!"
            } else {
                questionLabel.text = "Wie soll dein Passwort sein?"
            }
            nextButton.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        case 4:
            questionLabel.text = "Nun... Stelle dir eine kleine friedliche Stadt vor, direkt am Meer, schöne Architektur... Dort leben einsam ein junger Fischer und ein junger Bänker und gehen ihren Geschäften nach... OK?"
            nextButton.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        case 5:
            questionLabel.text = "Gut... Der Fischer hat viel Zeit in seinem ärmlichen Haus. Der Bänker wenig in seinem Reichen. Wer wärst du lieber?"
            nextButton.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        case 6:
            questionLabel.text = "Der Bänker kann sich jederzeit die modernsten und edelsten Kleider kaufen. Glaubst du er schaut auf den Fischer herab?"
            nextButton.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        case 7:
            questionLabel.text = "Der Fischer näht seine Kleidung selber. Glaubst du er ist eifersüchtig auf den Bänker?"
            nextButton.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        case 8:
            questionLabel.text = "Nehmen wir an vor 75 Jahren hat das Volk des Fischers, das Volk des Bänkers verraten und hintergangen. Nimmst du es dem Fischer übel?"
            nextButton.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        case 9:
            questionLabel.text = "Wirst du den Glauben, jeden Glauben deiner Mit-User akzeptieren?"
            nextButton.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        default:
            questionLabel.text = "Hier ist was schiefgegangen!"
        }
        
        UIView.animate(withDuration: 2, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
            self.answerTextfield.alpha = 1
            self.questionLabel.alpha = 1
        })
        
    }
    
    func startLogIn() {
        answerTextfield.text = ""
        nextButton.isEnabled = true
        answerTextfield.addTarget(self, action: #selector(textGetsWritten), for: .editingChanged)
        
        switch logInFrame {
        case 0:
            questionLabel.text = "Kind der Erde, wie lautet deine Email-Adresse?"
            nextButton.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        case 1:
            questionLabel.text = "Alles klar, dann gib nun bitte dein Kennwort ein und wir können loslegen!"
            nextButton.addTarget(self, action: #selector(nextButtonPushed), for: .touchUpInside)
        default:
            questionLabel.text = "Hier ist was schiefgegangen!"
        }
        
        UIView.animate(withDuration: 2, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
            self.answerTextfield.alpha = 1
            self.questionLabel.alpha = 1
        })
        
    }
    
    @objc func textGetsWritten() {
        UIView.animate(withDuration: 1.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
            self.nextButton.alpha = 1
        })
    }
    
    @objc func nextButtonPushed(sender: DesignableButton!) {
        let nextButtonSender: UIButton = sender
        nextButton.isEnabled = false
        answerTextfield.resignFirstResponder()
        
        if signUp {
            if let answer = answerTextfield.text {
                switch nextButtonSender.tag {
                case 0:
                    name = answer
                    signUpFrame = signUpFrame+1
                    nextButton.tag = 1
                case 1:
                    surname = answer
                    signUpFrame = signUpFrame+1
                    nextButton.tag = 2
                    
                case 2:
                    email = answer
                    signUpFrame = signUpFrame+1
                    nextButton.tag = 3
                    
                case 3:
                    password = answer
                    
                    if password.count >= 6 {
                        nextButton.tag = 4
                        signUpFrame = signUpFrame+1
                        tryToSignUp()
                    }
                    
                    
                case 4:
                    signUpAnswers["Herangehensweise Besser"] = answer
                    signUpFrame = signUpFrame+1
                    nextButton.tag = 5
                    
                case 5:
                    signUpAnswers["Herangehensweise Besser"] = answer
                    signUpFrame = signUpFrame+1
                    nextButton.tag = 6
                    
                case 6:
                    signUpAnswers["Herangehensweise Besser"] = answer
                    signUpFrame = signUpFrame+1
                    nextButton.tag = 7
                    
                case 7:
                    signUpAnswers["Herangehensweise Besser"] = answer
                    signUpFrame = signUpFrame+1
                    nextButton.tag = 8
                case 8:
                    signUpAnswers["Herangehensweise Besser"] = answer
                    signUpFrame = signUpFrame+1
                    nextButton.tag = 9
                case 9:
                    signUpAnswers["Herangehensweise Besser"] = answer
                    signUpFrame = signUpFrame+1
                    nextButton.tag = 10
                    
                default:
                    questionLabel.text = "Irgendwas ist hier falsch!"
                }
                
                UIView.animate(withDuration: 2, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
                    self.answerTextfield.alpha = 0
                    self.nextButton.alpha = 0
                    self.questionLabel.alpha = 0
                }, completion: { (_) in
                    self.startSignUpSession()
                })
                
            }
        } else {    // Wenn es Log-In ist
            print("else")
            
            if let answer = answerTextfield.text {
                print(answer)
                switch nextButtonSender.tag {
                case 0:
                    
                    email = answer
                    logInFrame = logInFrame+1
                    nextButton.tag = 1
                case 1:
                    
                    password = answer
                    
                    tryToLogIn()
                    
                default:
                    questionLabel.text = "Irgendwas ist hier falsch!"
                }
            }
            
            UIView.animate(withDuration: 2, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
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
        print("// Hier zum registrieren")
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if (error != nil) {
                print("Wir haben einen error: \(String(describing: error?.localizedDescription))")
            } else {
                print("User wurde erfolgreich erstellt.")
                let user = Auth.auth().currentUser
                if let user = user {
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
                    userRef.setData(["name": self.name, "surname": self.surname, "full_name": fullName])
                }
                // Erstmal
                self.dismiss(animated: true, completion: nil)
            }
        }
        
    }
    
    func tryToLogIn() {
        print(")// Hier zum einloggen")
        // Passwort= MalteS
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if (error != nil) {
                print("Wir haben einen error: \(String(describing: error?.localizedDescription))")
            } else {
                print("User wurde erfolgreich eingeloggt.")
                
                // Erstmal
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
    func setUpUI() {
        questionLabel.font = UIFont(name: "Kalam", size: 27)
        questionLabel.adjustsFontSizeToFitWidth = true
        questionLabel.minimumScaleFactor = 0.5
        questionLabel.numberOfLines = 0
        questionLabel.lineBreakMode = .byClipping
        questionLabel.textAlignment = .center
        questionLabel.alpha = 0     // Erstmal unsichtbar
        
        nextButton.layer.cornerRadius = 5
        nextButton.backgroundColor = UIColor(red:0.19, green:0.82, blue:1.00, alpha:1.0)
        nextButton.tag = 0
        nextButton.setTitle("Weiter", for: .normal)
        nextButton.titleLabel?.font = UIFont(name: "Kalam", size: 22)
        nextButton.alpha = 0
        
        answerTextfield.textAlignment = .center
        answerTextfield.font = UIFont(name: "Kalam", size: 18)
        answerTextfield.placeholder = "..."
        answerTextfield.autocorrectionType = .no
        answerTextfield.alpha = 0
        
        
        let newStackView = UIStackView(arrangedSubviews: [questionLabel,answerTextfield,nextButton])
        newStackView.axis = .vertical
        newStackView.distribution = .fillProportionally
        newStackView.spacing = 20
        
        view.addSubview(newStackView)
        newStackView.translatesAutoresizingMaskIntoConstraints = false  // Enables AutoLayout
        newStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        newStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -75).isActive = true
        newStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -75).isActive = true
        //nextButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        questionLabel.heightAnchor.constraint(equalToConstant: 250).isActive = true
        
    }
    
    
    @IBAction func logInTouched(_ sender: Any) {
        if signUp { // Wenn die Button sich geändert haben
            UIView.animate(withDuration: 2, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.initialStackView.alpha = 0
                self.attentionLabel.alpha = 0
                self.peaceSignView.alpha = 0
                
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
            topDismissButton.isHidden = false
            
            UIView.animate(withDuration: 2, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.initialStackView.alpha = 0
                self.peaceSignView.alpha = 0.3
                self.topDismissButton.alpha = 1
                self.LogInNavigationBar.alpha = 0
                
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
                self.LogInNavigationBar.alpha = 0
                self.initialStackView.alpha = 0
                self.peaceSignView.alpha = 0.5
                self.signUp = true  // Button verändern sich
                
            }, completion: { (_) in
                self.initialButton2.backgroundColor = UIColor(red:1.00, green:0.54, blue:0.52, alpha:1.0)
                self.LogInNavigationBar.isHidden = true
                self.initialLabel.text = "Das ist nicht irgendein Service! Du wirst in unsere Mitte aufgenommen, wenn du dich als würdig erweist! Nimm dir Zeit dafür. Sei ehrlich und du selbst!"
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
                self.attentionLabel.font = UIFont(name: "Kalam", size: 30)
                self.attentionLabel.shadowColor = UIColor.white
                self.attentionLabel.shadowOffset = CGSize(width: 3, height: -1)
                
                self.initialLabelConstraint.constant = 150
                
                // Zweiter Schritt
                UIView.animate(withDuration: 2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    self.attentionLabel.alpha = 1
                    self.view.layoutIfNeeded()
                }, completion: { (_) in
                    //Dritter Schritt
                    UIView.animate(withDuration: 2, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
                        self.initialStackView.alpha = 1
                    })
                })
            })
        }
    }
    
    
    @IBAction func backTouched(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.alpha = 1
    }
    
    @IBAction func topDismissButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
