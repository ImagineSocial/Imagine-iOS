//
//  InfoTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 08.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class InfoTableViewController: UITableViewController {

    var infos = [Info]()
    let EULAString = "Nutzungsbedingungen"
    let contactString = "Kontakt"
    let introString = "Mini App Tutorial"
    let roadMapString = "Roadmap"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        infos.append(contentsOf: [betterThanOthers, helper, giveToCharity, vcsAreBad, voiceOfTeam, networkEffect, motivation,copyright,Info(title: introString, image: nil, description: ""), Info(title: EULAString, image: nil, description: ""), Info(title: contactString, image: nil, description: ""), Info(title: roadMapString, image: nil, description: "")])    // Beschreibung warum Bots kacke sind
        
        tableView.separatorStyle = .none
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return infos.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let info = infos[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell") as? InfoCell {
            cell.titleLabel.text = info.title
            
            return cell
        }
    
        return UITableViewCell()
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let info = infos[indexPath.row]
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if info.title == EULAString || info.title == contactString {
            performSegue(withIdentifier: "toEulaSegue", sender: nil)
        } else if info.title == introString{
            performSegue(withIdentifier: "toIntroView", sender: nil)
        } else if info.title == roadMapString {
            if let url = URL(string: "https://d0e3617f-d0eb-46fd-abc4-50964f793967.filesusr.com/ugd/6cdc9c_7772ec185cba4e138fdc7343ff362a59.pdf") {
                UIApplication.shared.open(url)
            }
        } else {
            performSegue(withIdentifier: "toTopicsSegue", sender: info)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toTopicsSegue" {
            if let vc = segue.destination as? BlogPostViewController {
                if let info = sender as? Info {
                    vc.info = info
                }
            }
        } else if segue.identifier == "toIntroView" {
            if let vc = segue.destination as? SwipeCollectionViewController {
                vc.diashow = .intro
            }
        }
    }
    
    
    let copyright = Info(title: "Copyright", image: nil, description: "Design and Illustrations by Malte Schoppe\n\nDesign Advice by Valentin Leiber check out his site: https://valentinleiber.com\n\nCopyright Feed-Buttons:   Thanks Button: thank you by Adrien Coquet from the theNounProject.com  Wow Button: Smiley by NAS from theNounProject.com  Nice Button: Ok by HeadsOfBirds from theNounProject.com  HA Button: Hausa by Jonathan Coutiño from theNounProject.com\n\nIntro Tap Graphic: One Finger Tap by Jeff Portaro from theNounProject.com\n\n Chat Icon: discussion by Milky - Digital innovation from the Noun Project\n\n New Post Icon: add by shashank singh from the Noun Project\n\nFeed Icon: news by Milky - Digital innovation from the Noun Project\n\nThemen Icon: add collection by stzuana from the Noun Project\n\nPeaceSign: Peace by Anthony Ledoux from the Noun Project\n\nFriends Sign in side Menu: friends by Flatart from the Noun Project\n\n SavedPosts Sign: Save by Adrien Coquet from the Noun Project\n\nTranslation Image Globe: Translation by IconMark from the Noun Project\n\nDelete Image: Trash Can by IconMark from the Noun Project\n\nRepostButton: repost by LAFS from the Noun Project\n\nMegaphoneIcon: Megaphone by Atif Arshad from the Noun Project\n\nCamera Icon: Camera by Serhii Smirnov from the Noun Project\n\nSingle Message Bubble Icon: message by vectlab from the Noun Project\n\nFolder Icon: Folder by Syaidy from the Noun Project\n\nUpvote Sign: Arrow Up by Bluetip Design from the Noun Project\n\nCaution Sign in Facts: Caution by P Thanga Vignesh from the Noun Project\n\nTopicIcon: Social by Adrien Coquet from the Noun Project")
    
    let trustScore = Info(title: "Trust Score", image: nil, description: "Das einordnen von Themen, melden von unangebrachten Inhalten und das korrekte Entscheiden in der Demokratie-Schleife bringt dem User einen höheren Trust Score ein. Auch das regelmäßige posten und kommentieren, also die Unterstützung des Netzwerkes wird mit einem höheren Score gewürdigt.  \nWird man jedoch mehrmals mit angebrachten Vorwürfen gemeldet verringert sich der Score. Bei einem zu geringen Score, also bei anhaltend schädlichen Inhalten werden einem die Einsende-Rechte vorübergehend entzogen.\n Je höher der Trust Score, desto größer ist die Entscheidungsmacht. Die Wertungen in der Demokratie-Schleife und Meldungen werden höher gewertet und man kann über die Wochen/Tages/Ereignisthemen entscheiden.\n Ab einem gewissen Score erhält man als Belohnung einen Premium-Account und kann als Dank Imagine werbefrei genießen. \nDie Umsetzung des Trust-Scores ist in Planung(siehe Roadmap)")
    let helper = Info(title: NSLocalizedString("helper_title", comment: ""), image: nil, description: NSLocalizedString("helper_description", comment: "") )
    let principle = Info(title: NSLocalizedString("principle_title", comment: ""), image: UIImage(named: "ImagineSign"), description: NSLocalizedString("principle_descriprion", comment: ""))
    
    let vcsAreBad = Info(title: NSLocalizedString("vcs_are_bad_title", comment: ""), image: nil, description: NSLocalizedString("vcs_are_bad_description", comment: ""))
    
    let voiceOfTeam = Info(title: NSLocalizedString("voice_of_team_title", comment: ""), image: nil, description: NSLocalizedString("voice_of_team_description", comment: ""))
    
    let networkEffect = Info(title: NSLocalizedString("network_effect_title", comment: ""), image: nil, description: NSLocalizedString("network_effect_description", comment: ""))
    let motivation = Info(title: NSLocalizedString("our_motivation_title", comment: ""), image: nil, description: NSLocalizedString("our_motivation_description", comment: ""))
    
    let giveToCharity = Info(title: NSLocalizedString("give_to_charity_title", comment: ""), image: nil, description: NSLocalizedString("give_to_charity_description", comment: ""))
    
    let betterThanOthers = Info(title: NSLocalizedString("better_than_others_title", comment: ""), image: nil, description: NSLocalizedString("better_than_others_description", comment: ""))
}

class Info {
    var title:String
    var image:UIImage?
    var description:String
    
    init(title: String, image: UIImage?, description: String) {
        self.title = title
        self.image = image
        self.description = description
    }
}

class InfoCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // add corner radius on `contentView`
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        backgroundColor =  .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //set the values for top,left,bottom,right margins
        let margins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        contentView.frame = contentView.frame.inset(by: margins)
    }
}

