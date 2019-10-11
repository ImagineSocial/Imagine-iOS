//
//  ArgumentDetailViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class ArgumentDetailViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var sourceTextView: UITextView!
    @IBOutlet weak var sourceTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var showSourceButton: DesignableButton!
    
    var source: Source?
    var argument: Argument?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sourceTextView.delegate = self

        setUpView()
    }
    
    func setUpView() {
        if let source = source {
            
            let length = source.title.count
            
            let attributedString = NSMutableAttributedString(string: "Gehe zur Quelle: \(source.title)")
            attributedString.addAttribute(.link, value: source.source, range: NSRange(location: 16, length: length))
            
            sourceTextView.attributedText = attributedString
            
            self.titleLabel.text = source.title
            self.descriptionLabel.text = source.description
        } else if let argument = argument {
            self.sourceTextViewHeightConstraint.constant = 0
            self.showSourceButton.isHidden = true
            self.titleLabel.text = argument.title
            self.descriptionLabel.text = argument.description
        }
    }
    
    // To open the link
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        UIApplication.shared.open(URL)
        return false
    }
    @IBAction func showSourceButtonTapped(_ sender: Any) {
        if let source = source {
            performSegue(withIdentifier: "goToLink", sender: source.source)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToLink" {
            if let webVC = segue.destination as? WebViewController {
                if let link = sender as? String {
                    webVC.link = link
                }
            }
        }
    }
    

}
