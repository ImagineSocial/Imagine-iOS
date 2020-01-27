//
//  CreativeExampleViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.01.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

enum CreativeType {
    case programmer
    case artist
    case revolution
}

class CreativeExampleViewController: UIViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var firstImageView: UIImageView!
    @IBOutlet weak var firstDescriptionLabel: UILabel!
    @IBOutlet weak var secondImageView: UIImageView!
    @IBOutlet weak var secondDescriptionLabel: UILabel!
    @IBOutlet weak var thirdImageView: UIImageView!
    @IBOutlet weak var thirdDescriptionLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var toVoteButton: DesignableButton!
    
    var typeOfCreative: CreativeType = .programmer
    var examples = [VisionExample]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let layer = toVoteButton.layer
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 8
        
        switch typeOfCreative {
        case .revolution:
            headerLabel.font = UIFont(name: "American Typewriter", size: 20)
            firstDescriptionLabel.font = UIFont(name: "American Typewriter", size: 15)
            secondDescriptionLabel.font = UIFont(name: "American Typewriter", size: 15)
            thirdDescriptionLabel.font = UIFont(name: "American Typewriter", size: 15)
            summaryLabel.font = UIFont(name: "American Typewriter", size: 17)
            
            headerLabel.text = "Power to the People!"
            summaryLabel.text = "Je mehr Menschen sich für eine Sache einsetzen, desto größer wird ihr Einfluss. Suchen wir uns zuerst die Probleme, bei der sich alle einig sind und setzen uns effektiv für eine Veränderung ein. Lassen wir das Internet endlich für uns arbeiten!"
            
        case .artist:
            
            headerLabel.font = UIFont(name: "Noteworthy", size: 20)
            firstDescriptionLabel.font = UIFont(name: "Noteworthy", size: 15)
            secondDescriptionLabel.font = UIFont(name: "Noteworthy", size: 15)
            thirdDescriptionLabel.font = UIFont(name: "Noteworthy", size: 15)
            summaryLabel.font = UIFont(name: "Noteworthy", size: 17)
            
            headerLabel.text = "Gestalten wir die Zukunft & die App wie es uns beliebt"
            summaryLabel.text = "Der Einfluss der User ist fest in unserer Idee verankert. Wir wollen kreatives Denken unterstützen und freuen uns auch über kleine Gimmicks, die nicht zwangsläufig notwendig sind, aber das Erlebnis verbessern. Wir wollen anders sein und Menschen die anders denken und handeln anziehen!"
            
        default:
            
            headerLabel.font = UIFont(name: "DIN Alternate", size: 21)
            firstDescriptionLabel.font = UIFont(name: "DIN Alternate", size: 15)
            secondDescriptionLabel.font = UIFont(name: "DIN Alternate", size: 15)
            thirdDescriptionLabel.font = UIFont(name: "DIN Alternate", size: 15)
            summaryLabel.font = UIFont(name: "DIN Alternate", size: 17)
            
            headerLabel.text = "Wir entscheiden wie sich die App anfühlt!"
            summaryLabel.text = "Imagine ist ein Open Source Projekt. Wir können die kreativen Ideen von Vielen ausprobieren, testen und als Features etablieren. Die Möglichkeiten sind endlos, wir sind keinen Aktionären oder Investoren Rechenschaft schuldig, kreieren wir also etwas großes und außergewöhnliches!"
        }
        
        setView()
    }
    
    func setView() {
        print("Setting the examples: \(self.examples)")
        
        let firstExample = self.examples[0]
        
        if let url = URL(string: firstExample.imageURL) {
            firstImageView.sd_setImage(with: url, completed: nil)
        }
        firstDescriptionLabel.text = firstExample.description
        
        let secondExample = self.examples[1]
        
        if let url = URL(string: secondExample.imageURL) {
            secondImageView.sd_setImage(with: url, completed: nil)
        }
        secondDescriptionLabel.text = secondExample.description
        
        let thirdExample = self.examples[2]
        
        if let url = URL(string: thirdExample.imageURL) {
            thirdImageView.sd_setImage(with: url, completed: nil)
        }
        thirdDescriptionLabel.text = thirdExample.description
    }

    @IBAction func toVoteButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "toVoteSegue", sender: nil)
    }
}
