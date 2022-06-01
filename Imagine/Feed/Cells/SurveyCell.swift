//
//  SurveyCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.05.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

enum SurveyType {
    case pickOne
    case pickOrder
    case comment
}

protocol SurveyCellDelegate {
    func surveyCompleted(surveyID: String, indexPath: IndexPath, data: [Any], comment: String?)
    func dontShowAgain(surveyID: String, indexPath: IndexPath)
}

class SurveyCell: UITableViewCell {
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var firstAnswerLabel: UILabel!
    @IBOutlet weak var firstAnswerButton: UIButton!
    @IBOutlet var firstAnswerSmallTikLabel: UILabel!
    @IBOutlet weak var secondAnswerLabel: UILabel!
    @IBOutlet weak var secondAnswerButton: UIButton!
    @IBOutlet var secondAnswerSmallTikLabel: UILabel!
    @IBOutlet weak var thirdAnswerLabel: UILabel!
    @IBOutlet weak var thirdAnswerButton: UIButton!
    @IBOutlet var thirdAnswerSmallTikLabel: UILabel!
    @IBOutlet weak var fourthAnswerButton: UIButton!
    @IBOutlet weak var fourthAnswerLabel: UILabel!
    @IBOutlet var fourthAnswerSmallTikLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var answerTextView: UITextView!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    var surveyType: SurveyType?
    var orderIndex = 1
    var pickOneSelectedAnswer: Int?
    var pickOrderArray = [Int]()
    
    var indexPath: IndexPath?
    var delegate: SurveyCellDelegate?
    
    var post: Post? {
        didSet {
            if let survey = post!.survey {
                surveyType = survey.type
                
                questionLabel.text = survey.question
                
                if let firstAnswer = survey.firstAnswer, let secondAnswer = survey.secondAnswer, let thirdAnswer = survey.thirdAnswer, let fourthAnswer = survey.fourthAnswer {
                    firstAnswerLabel.text = firstAnswer
                    secondAnswerLabel.text = secondAnswer
                    thirdAnswerLabel.text = thirdAnswer
                    fourthAnswerLabel.text = fourthAnswer
                }
                
                switch survey.type {
                case .pickOne:
                    explanationLabel.text = NSLocalizedString("surveyCell_pickOne_label", comment: "pick one")
                case .pickOrder:
                    explanationLabel.text = NSLocalizedString("surveyCell_pickOrder_label", comment: "pick order")
                case .comment:
                    explanationLabel.text = NSLocalizedString("surveyCell_writeComment_label", comment: "write comment")
                }
            }
        }
    }
    
    override func awakeFromNib() {
        answerTextView.delegate = self
        
        doneButton.isEnabled = false
        doneButton.alpha = 0.5
        
        backgroundColor = .clear
        contentView.layer.cornerRadius = 8
    }
    
    override func prepareForReuse() {
        doneButton.isEnabled = false
        doneButton.alpha = 0.5
        pickOrderArray.removeAll()
        pickOneSelectedAnswer = nil
        orderIndex = 1
        
        answerTextView.text = ""
        
        firstAnswerSmallTikLabel.text = ""
        secondAnswerSmallTikLabel.text = ""
        thirdAnswerSmallTikLabel.text = ""
        fourthAnswerSmallTikLabel.text = ""
        
        firstAnswerButton.isEnabled = true
        secondAnswerButton.isEnabled = true
        thirdAnswerButton.isEnabled = true
        fourthAnswerButton.isEnabled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.clipsToBounds = false
        clipsToBounds = false
        
        let layer = containerView.layer
        layer.createStandardShadow(with: CGSize(width: contentView.frame.width - 24, height: contentView.frame.height - 24), cornerRadius: Constants.Numbers.feedCornerRadius)
    }
    
    func buttonTapped(button: Int) {
        if let type = surveyType {
            switch type {
            case .pickOne:
                
                pickOneSelectedAnswer = button
                doneButton.isEnabled = true
                doneButton.alpha = 1
                
                switch button {
                case 1:
                    firstAnswerSmallTikLabel.text = "x"
                    secondAnswerSmallTikLabel.text = ""
                    thirdAnswerSmallTikLabel.text = ""
                    fourthAnswerSmallTikLabel.text = ""
                case 2:
                    firstAnswerSmallTikLabel.text = ""
                    secondAnswerSmallTikLabel.text = "x"
                    thirdAnswerSmallTikLabel.text = ""
                    fourthAnswerSmallTikLabel.text = ""
                case 3:
                    firstAnswerSmallTikLabel.text = ""
                    secondAnswerSmallTikLabel.text = ""
                    thirdAnswerSmallTikLabel.text = "x"
                    fourthAnswerSmallTikLabel.text = ""
                case 4:
                    firstAnswerSmallTikLabel.text = ""
                    secondAnswerSmallTikLabel.text = ""
                    thirdAnswerSmallTikLabel.text = ""
                    fourthAnswerSmallTikLabel.text = "x"
                default:
                    print("Cant happen")
                }
            case .pickOrder:
                
                pickOrderArray.append(button)
                
                if pickOrderArray.count <= 4 {
                    
                    if pickOrderArray.count == 4 {
                        
                        doneButton.isEnabled = true
                        doneButton.alpha = 1
                    }
                    
                    switch button {
                    case 1:
                        firstAnswerSmallTikLabel.text = String(orderIndex)
                        orderIndex = orderIndex+1
                        firstAnswerButton.isEnabled = false
                    case 2:
                        secondAnswerSmallTikLabel.text = String(orderIndex)
                        orderIndex = orderIndex+1
                        secondAnswerButton.isEnabled = false
                    case 3:
                        thirdAnswerSmallTikLabel.text = String(orderIndex)
                        orderIndex = orderIndex+1
                        thirdAnswerButton.isEnabled = false
                    case 4:
                        fourthAnswerSmallTikLabel.text = String(orderIndex)
                        orderIndex = orderIndex+1
                        fourthAnswerButton.isEnabled = false
                    default:
                        print("Cant happen")
                    }
                }
            case .comment:
                print("Cant")
            }
        }
    }
    
    @IBAction func resetButtonTapped(_ sender: Any) {
        pickOrderArray.removeAll()
        orderIndex = 1
        pickOneSelectedAnswer = nil
        
        doneButton.isEnabled = false
        doneButton.alpha = 0.5
        
        firstAnswerSmallTikLabel.text = ""
        secondAnswerSmallTikLabel.text = ""
        thirdAnswerSmallTikLabel.text = ""
        fourthAnswerSmallTikLabel.text = ""
        
        firstAnswerButton.isEnabled = true
        secondAnswerButton.isEnabled = true
        thirdAnswerButton.isEnabled = true
        fourthAnswerButton.isEnabled = true
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        if let post = post, let indexPath = indexPath {
            var data: [Any] = [""]
            
            if let survey = post.survey {
                switch survey.type {
                case .pickOrder:
                    data = pickOrderArray
                default:
                    if let selectedAnswer = pickOneSelectedAnswer {
                        data = [selectedAnswer]
                    }
                }
                var answerText: String?
                if answerTextView.text != "" {
                    answerText = answerTextView.text
                }
                
                delegate?.surveyCompleted(surveyID: post.documentID, indexPath: indexPath, data: data, comment: answerText)
            } else {
                print("Got no survey")
            }
        }
        
    }
    @IBAction func dontShowAgainTapped(_ sender: Any) {
        if let post = post, let indexPath = indexPath {
            delegate?.dontShowAgain(surveyID: post.documentID, indexPath: indexPath)
        }
    }
    
    @IBAction func firstAnswerButtonTapped(_ sender: Any) {
        buttonTapped(button: 1)
    }
    @IBAction func secondAnswerButtonTapped(_ sender: Any) {
        buttonTapped(button: 2)
    }
    @IBAction func thirdAnswerButtonTapped(_ sender: Any) {
        buttonTapped(button: 3)
    }
    @IBAction func fourthAnswerButtonTapped(_ sender: Any) {
        buttonTapped(button: 4)
    }
    
}

extension SurveyCell: UITextViewDelegate {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        answerTextView.resignFirstResponder()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text.rangeOfCharacter(from: CharacterSet.newlines) == nil else {
            answerTextView.resignFirstResponder()
            return false
        }
        return true
    }
}

class Survey {
    var type: SurveyType
    var question: String
    
    var firstAnswer: String?
    var secondAnswer: String?
    var thirdAnswer: String?
    var fourthAnswer: String?
    
    var surveyID: String?
    
    init(type: SurveyType, question: String) {
        self.type = type
        self.question = question
    }
}
