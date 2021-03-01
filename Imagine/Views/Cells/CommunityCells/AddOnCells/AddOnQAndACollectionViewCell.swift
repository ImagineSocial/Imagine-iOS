//
//  AddOnQAndACollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 17.09.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class QandAQuestion {
    var question: String
    var documentID: String
    var answers = [String]()
    
    init(question: String, documentID: String) {
        self.question = question
        self.documentID = documentID
    }
}

class AddOnQAndACollectionViewCell: BaseAddOnCollectionViewCell {
    
    @IBOutlet weak var currentQuestionLabel: UILabel!
    @IBOutlet weak var commentTableView: UITableView!
    @IBOutlet weak var questionsTableView: UITableView!
    @IBOutlet weak var commentTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var questionsTableViewHeightConstraint: NSLayoutConstraint!
    
    let answerTextfieldCellIdentifier = "AddOnQAndATextfieldCell"
    let questionCellIdentifier = "AddOnQAndAQuestionCell"
    let db = Firestore.firestore()
    
    var questions = [QandAQuestion]()
    
    var info: AddOn? {
        didSet {
            if let info = info {
                if self.questions.count == 0 {
                    getQuestions(info: info)
                }
            }
        }
    }
    
    var commentView: CommentAnswerView?
    var isViewTransforming = false
    var selectedQuestionIndex = 0
    
    var activeTextFields = [UITextField]()
    
    override func awakeFromNib() {
        
        questionsTableView.dataSource = self
        questionsTableView.delegate = self
        questionsTableView.tableFooterView = UIView(frame: .zero)
        questionsTableView.layer.cornerRadius = cornerRadius
        questionsTableView.register(UINib(nibName: "AddOnQAndATextfieldCell", bundle: nil), forCellReuseIdentifier: answerTextfieldCellIdentifier)
        questionsTableView.register(UINib(nibName: "AddOnQAndAQuestionCell", bundle: nil), forCellReuseIdentifier: questionCellIdentifier)
        
        commentTableView.dataSource = self
        commentTableView.delegate = self
        commentTableView.register(UINib(nibName: "AddOnQAndATextfieldCell", bundle: nil), forCellReuseIdentifier: answerTextfieldCellIdentifier)
        
        contentView.layer.cornerRadius = cornerRadius
        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cancelTextFieldFirstResponder))
//        self.addGestureRecognizer(tapGesture)
    }
    
    
    @objc func cancelTextFieldFirstResponder() {
        for tf in activeTextFields {
            tf.resignFirstResponder()
        }
    }
    
    func getQuestions(info: AddOn) {
        
        var collectionRef: CollectionReference!
        if info.fact.language == .english {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        
        let ref = collectionRef.document(info.fact.documentID).collection("addOns").document(info.documentID).collection("questions")
        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    for document in snap.documents {
                        let data = document.data()
                        
                        if let question = data["question"] as? String {
                            let question = QandAQuestion(question: question, documentID: document.documentID)
                            if let answers = data["answers"] as? [String] {
                                question.answers = answers
                            }
                            
                            self.questions.append(question)
                        }
                    }
                    if self.questions.count != 0 {
                        self.currentQuestionLabel.text = self.questions[0].question
                        self.commentTableView.reloadData()
                    } else {
                        self.currentQuestionLabel.text = NSLocalizedString("qanda_first_question", comment: "aska first question")
                    }
                    self.questionsTableView.reloadData()
                }
            }
        }
    }
    
    func hightLightQuestionTableView() {
        guard let questionsTableViewHeightConstraint = questionsTableViewHeightConstraint else { return }
        
        if questionsTableViewHeightConstraint.multiplier <= 0.45 && !isViewTransforming {
            self.isViewTransforming = true
            self.questionsTableViewHeightConstraint = self.questionsTableViewHeightConstraint.setMultiplier(multiplier: 0.55)
            self.commentTableViewHeightConstraint = self.commentTableViewHeightConstraint.setMultiplier(multiplier: 0.2)
            
            UIView.animate(withDuration: 0.5) {
                self.layoutIfNeeded()
            } completion: { (_) in
                self.isViewTransforming = false
            }
        }
    }
    
    func hightLightCommentTableView() {
        guard let commentTableViewHeightConstraint = commentTableViewHeightConstraint else { return }
        
        if commentTableViewHeightConstraint.multiplier <= 0.25 && !isViewTransforming {
            self.isViewTransforming = true
            self.questionsTableViewHeightConstraint = self.questionsTableViewHeightConstraint.setMultiplier(multiplier: 0.35)
            self.commentTableViewHeightConstraint = self.commentTableViewHeightConstraint.setMultiplier(multiplier: 0.4)
            UIView.animate(withDuration: 0.5) {
                self.layoutIfNeeded()
            } completion: { (_) in
                self.isViewTransforming = false
            }
        }
    }
}

extension AddOnQAndACollectionViewCell: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == questionsTableView {   //0.45
            hightLightQuestionTableView()
        } else if scrollView == commentTableView {  //0.25
            hightLightCommentTableView()
        }
    }
}

extension AddOnQAndACollectionViewCell: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == questionsTableView {
            return questions.count+1
        } else {
            if questions.count != 0 {
                return questions[selectedQuestionIndex].answers.count+1
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == questionsTableView {
            if indexPath.row < questions.count {
                
                if let cell = tableView.dequeueReusableCell(withIdentifier: questionCellIdentifier, for: indexPath) as? AddOnQAndAQuestionCell {
                    let question = questions[indexPath.row]
                    cell.answerLabel.text = question.question
                    let count = question.answers.count
                    if count != 0 {
                        cell.answerCountLabel.text = String(count)
                    } else {
                        cell.answerCountLabel.text = ""
                    }
                    
                    return cell
                }
                
                let cell: UITableViewCell = {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {
                        
                        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
                        if #available(iOS 13.0, *) {
                            cell.backgroundColor = .secondarySystemBackground
                        } else {
                            cell.backgroundColor = .lightGray
                        }
                        return cell
                        
                    }
                    return cell
                }()
                
                let question = questions[indexPath.row]
                cell.textLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
                cell.textLabel?.text = question.question
                cell.textLabel?.numberOfLines = 0
                
                return cell
            } else {
                if let cell = tableView.dequeueReusableCell(withIdentifier: answerTextfieldCellIdentifier, for: indexPath) as? AddOnQAndATextfieldCell {
                    
                    if #available(iOS 13.0, *) {
                        cell.backgroundColor = .secondarySystemBackground
                    } else {
                        cell.backgroundColor = .ios12secondarySystemBackground
                    }
                    let textField = cell.answerTextField!
                    self.activeTextFields.append(textField)
                    
                    cell.type = .question
                    cell.info = info
                    cell.delegate = self
                    
                    return cell
                }
            }
        } else {    //AnswerTableView
            if questions.count != 0 {
                if indexPath.row < questions[selectedQuestionIndex].answers.count {
                    let cell: UITableViewCell = {
                        guard let cell = tableView.dequeueReusableCell(withIdentifier: "answerCell") else {
                            
                            let cell = UITableViewCell(style: .default, reuseIdentifier: "answerCell")
                            return cell
                            
                        }
                        return cell
                    }()
                    
                    let answer = questions[selectedQuestionIndex].answers[indexPath.row]
                    cell.textLabel?.font = UIFont(name: "IBMPlexSans", size: 14)
                    cell.textLabel?.text = answer
                    cell.textLabel?.numberOfLines = 0
                    
                    return cell
                } else {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: answerTextfieldCellIdentifier, for: indexPath) as? AddOnQAndATextfieldCell {

                        cell.type = .answer
                        cell.info = info
                        cell.delegate = self
                        cell.questionID = questions[selectedQuestionIndex].documentID
                        
                        let textField = cell.answerTextField!
                        self.activeTextFields.append(textField)
                        
                        return cell
                    }
                }
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == questionsTableView {
            let question = questions[indexPath.row]
            
            self.currentQuestionLabel.text = question.question
            self.hightLightCommentTableView()
            selectedQuestionIndex = indexPath.row
            commentTableView.reloadData()
        } else {
            print("answerTapped")
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == questionsTableView {
            if indexPath.row < questions.count {
                return UITableView.automaticDimension
            } else {
                return 50
            }
        } else {    //AnswerTableView
            if questions.count != 0 {
                if indexPath.row < questions[selectedQuestionIndex].answers.count {
                    return UITableView.automaticDimension
                } else {
                    return 50
                }
            } else {
                return UITableView.automaticDimension
            }
        }
    }
}

extension AddOnQAndACollectionViewCell: QandACellDelegate {
    
    func insertNewItem(type: QandAAnswerType, text: String, questionID: String) {
        switch type {
        case .answer:
            if let question = self.questions.first(where: {$0.documentID == questionID}) {
                question.answers.append(text)
                self.commentTableView.reloadData()
            }
        default:
            let question = QandAQuestion(question: text, documentID: questionID)
            self.questions.append(question)
            self.questionsTableView.reloadData()
        }
    }
}

enum QandAAnswerType {
    case answer
    case question
}

protocol QandACellDelegate {
    func insertNewItem(type: QandAAnswerType, text: String, questionID: String)
}

class AddOnQAndATextfieldCell: UITableViewCell {
    
    @IBOutlet weak var sendButton: DesignableButton!
    @IBOutlet weak var answerTextField: UITextField!
    
    let db = Firestore.firestore()
    let answerPlaceholder = "Antworte auf die Frage"
    let questionPlaceholder = "Stelle eine neue Frage"
    
    var type: QandAAnswerType? {
        didSet {
            if let type = type {
                switch type {
                case .answer:
                    answerTextField.placeholder = answerPlaceholder
                default:
                    answerTextField.placeholder = questionPlaceholder
                }
            }
        }
    }
    var info: AddOn?
    var questionID: String?
    
    var delegate: QandACellDelegate?
    
    override func awakeFromNib() {
        selectionStyle = .none
    }
    
    @IBAction func sendButtonTapped(_ sender: Any) {
        guard let type = type, let info = info, let text = answerTextField.text, text != "" else { return }
        
        if let user = Auth.auth().currentUser {
            storeInFirebase(info: info, type: type, text: text, user: user)
        }
    }
    
    func storeInFirebase(info: AddOn, type: QandAAnswerType, text: String, user: Firebase.User) {
        
        var collectionRef: CollectionReference!
        if info.fact.language == .english {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        
        if type == .question {
            if info.fact.documentID != "" {
                
                let ref = collectionRef.document(info.fact.documentID).collection("addOns").document(info.documentID).collection("questions").document()
                
                let data: [String: Any] = ["question": text, "OP": user.uid]
                
                ref.setData(data) { (err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        print("QUestion successfully created")
                        self.delegate?.insertNewItem(type: .question, text: text, questionID: ref.documentID)
                        self.resetTextField(type: type)
                    }
                }
            }
        } else {
            if let id = questionID {
                if info.fact.documentID != "" {
                    let ref = collectionRef.document(info.fact.documentID).collection("addOns").document(info.documentID).collection("questions").document(id)
                    
                    ref.updateData([
                        "answers" : FieldValue.arrayUnion([text])
                    ]) { (err) in
                        if let error = err {
                            print("We have an error: \(error.localizedDescription)")
                        } else {
                            print("answer successfully created")
                            self.delegate?.insertNewItem(type: .answer, text: text, questionID: id)
                            self.resetTextField(type: type)
                        }
                    }
                }
            }
        }
    }
    
    func resetTextField(type: QandAAnswerType) {
        self.answerTextField.resignFirstResponder()
        if type == .answer {
            self.answerTextField.placeholder = answerPlaceholder
        } else {
            self.answerTextField.placeholder = questionPlaceholder
        }
        self.answerTextField.text = ""
    }
}


class AddOnQAndAQuestionCell: UITableViewCell {
    
    @IBOutlet weak var answerLabel: UILabel!
    
    @IBOutlet weak var answerCountLabel: UILabel!
    
}
