//
//  SettingTextCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class SettingTextCell: UITableViewCell, UITextViewDelegate {
    
    //MARK:- IBOutlets
    @IBOutlet weak var settingTitleLabel: UILabel!
    @IBOutlet weak var settingTextView: UITextView!
    @IBOutlet weak var characterLimitLabel: UILabel!
    
    //MARK:- Variables
    var delegate: SettingCellDelegate?
    
    var config: TableViewSettingCell? {
        didSet {
            if let setting = config {
                settingTitleLabel.text = setting.titleText
                if let maxCharacter = setting.characterLimit {
                    if let value = setting.value as? String {
                        let characterLeft = maxCharacter-value.count
                        characterLimitLabel.text = String(characterLeft)
                    }
                } else {
                    characterLimitLabel.isHidden = true
                }
                if let value = setting.value as? String {
                    settingTextView.text = value
                }
            }
        }
    }
    
    //MARK:- Cell Lifecycle
    override func awakeFromNib() {
        settingTextView.delegate = self
    }
    
    //MARK:
    func newTextReady(text: String) {
        if let setting = config {
            delegate?.gotChanged(type: setting.settingChange, value: text)
        }
    }
    
    //MARK:- TextViewDelegate
    func textViewDidEndEditing(_ textView: UITextView) {
        if let text = textView.text {
            if text != "" {
                newTextReady(text: text)
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {       // If you hit return
            textView.resignFirstResponder()
            return false
        }
        if let setting = config {
            if let maxCharacter = setting.characterLimit {
                
                return textView.text.count + (text.count - range.length) <= maxCharacter  // Text no longer than x characters
            }
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if let setting = config {
            if let maxCharacter = setting.characterLimit {
                let characterLeft = maxCharacter-textView.text.count
                self.characterLimitLabel.text = String(characterLeft)
            }
        }
    }
}
