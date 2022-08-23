//
//  MeldeTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 04.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

protocol tableViewToContainerParentProtocol:class { // Um die Auswahl zum ParentVC zu schicken
    func passReportOption(option: ReportOption)
}

enum reportOption {
    case notListed
    
    case satire
    case spoiler
    case personalOpinion
    case sensationalism
    case editedContent
    
    case hateSpeech
    case mobbing
    case insult
    case racism
    case homophobia
    case violanceGlorification
    case suicideTrivialization
    case religiousFreedom
    
    case spam
    case misinformation
    case pornography
    case pedophilia
    case violence
    case crime
    case animalCruelty
}

class ReportOption {
    var reportOption: reportOption
    var text: String
    
    init(reportOption: reportOption, text: String) {
        self.reportOption = reportOption
        self.text = text
    }
    
    // Optical change
    // not now: "Circlejerk",NSLocalizedString("Pretentious", comment: "When the poster is just posting to sell themself"),, NSLocalizedString("Ignorant Thinking", comment: "If the poster is just looking at one side of the matter or problem")
}

class ReportTableViewController: UITableViewController {
    
    var reportCategory: reportCategory?
    var choosenOption: ReportOption?
    var optionArray = [ReportOption]()
    var post: Post?
    
    let opticOptionArray: [ReportOption] = [ReportOption(reportOption: .satire, text: "Satire"), ReportOption(reportOption: .spoiler, text: "Spoiler"), ReportOption(reportOption: .personalOpinion, text: NSLocalizedString("Opinion, not a fact", comment: "When it seems like the post is presenting a fact, but is just an opinion")), ReportOption(reportOption: .sensationalism, text: NSLocalizedString("Sensationalism", comment: "When the given facts are presented more important, than they are in reality")), ReportOption(reportOption: .editedContent, text: NSLocalizedString("Edited Content", comment: "If the person shares something that is corrected or changed with photoshop or whatever")), ReportOption(reportOption: .notListed, text: NSLocalizedString("Not listed", comment: "Something besides the given options"))]
        
    
    let ruleViolationArray: [ReportOption] = [ReportOption(reportOption: .hateSpeech, text: NSLocalizedString("reportOption_hateSpeech", comment: "hate speech")), ReportOption(reportOption: .mobbing, text: "Mobbing"), ReportOption(reportOption: .insult, text: NSLocalizedString("reportOption_insult", comment: "insult")), ReportOption(reportOption: .racism, text: NSLocalizedString("reportOption_racism", comment: "racism")), ReportOption(reportOption: .homophobia, text: NSLocalizedString("reportOption_homophobia", comment: "homophobia")), ReportOption(reportOption: .violanceGlorification, text: NSLocalizedString("reportOption_violanceGlorification", comment: "violance glorification")),ReportOption(reportOption: .suicideTrivialization, text: NSLocalizedString("reportOption_suicideTrivialization", comment: "trvialization of suicide")), ReportOption(reportOption: .religiousFreedom, text: NSLocalizedString("reportOption_religiousFreedom", comment: "freedom of religion")), ReportOption(reportOption: .notListed, text: NSLocalizedString("Not listed", comment: "Something besides the given options"))]
        
    
    let contentArray: [ReportOption] = [ReportOption(reportOption: .misinformation, text: "Misinformation"), ReportOption(reportOption: .spam, text: "Spam"), ReportOption(reportOption: .pornography, text: NSLocalizedString("Pornography", comment: "You know what it means")), ReportOption(reportOption: .pedophilia, text: NSLocalizedString("Pedophilia", comment: "sexual display of minors")) , ReportOption(reportOption: .violence, text: NSLocalizedString("Presentation of violance", comment: "Presentation of violance")), ReportOption(reportOption: .crime, text: NSLocalizedString("crime", comment: "crime")), ReportOption(reportOption: .animalCruelty, text: NSLocalizedString("animal_cruelty", comment: "animal cruelty")),  ReportOption(reportOption: .notListed, text: NSLocalizedString("Not listed", comment: "Something besides the given options"))]
    
    weak var delegate:tableViewToContainerParentProtocol? = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.visibleCells.forEach { (cell) in
            if let cell = cell as? ReportCell {
                cell.ReportReasonLabel.text = ""
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reportOptions()
    }
    
    

    func reportOptions () {
        guard let category = reportCategory else {
            dismiss(animated: true, completion: nil)
            return
        }
        switch category {
        case .markVisually:
            optionArray = opticOptionArray
        case .violationOfRules:
            optionArray = ruleViolationArray
        case .content:
            optionArray = contentArray
        }
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return optionArray.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ReportCell", for: indexPath) as? ReportCell {
            
            cell.ReportOptionLabel.text = optionArray[indexPath.row].text
            
            return cell
        }
        return UITableViewCell()
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.visibleCells.forEach { (cell) in      // Jede andere Auswahl zurücksetzen
            if let cell = cell as? ReportCell {
                cell.ReportReasonLabel.text = ""
            }
        }
        if let cell = tableView.cellForRow(at: indexPath) as? ReportCell {      // Ausgewählter Grund markieren
            cell.ReportReasonLabel.text = "X"
            self.choosenOption = optionArray[indexPath.row]
            
            delegate?.passReportOption(option: choosenOption!)
        }
        
        
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    

}

class ReportCell : UITableViewCell {
    
    @IBOutlet weak var ReportReasonLabel: UILabel!
    @IBOutlet weak var ReportOptionLabel: UILabel!
}
