//
//  Constants.swift
//  Imagine
//
//  Created by Malte Schoppe on 18.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

struct Constants {
    
    
    static let thanksColor = UIColor(red:0.95, green:0.63, blue:0.34, alpha:1)
    static let wowColor = UIColor(red:0.95, green:0.76, blue:0.40, alpha:1)
    static let haColor = UIColor(red:0.95, green:0.87, blue:0.50, alpha:1)
    static let niceColor = UIColor(red:0.98, green:0.71, blue:0.58, alpha:1)
    static let green = UIColor(red:0.36, green:0.70, blue:0.37, alpha:1.0)      //#5DB25E
    static let red = UIColor(red:1.00, green:0.54, blue:0.52, alpha:1.0)
    static let backgroundColorForTableViews = UIColor(red:0.33, green:0.47, blue:0.65, alpha:0.5)
    
    struct strings {
        static let anonymPosterName = NSLocalizedString("constants_anonymousPosterName", comment: "an anonymous user")
        static let textOfTheWeek = "Tauscht euch aus, seid nett und lernt neue Menschen kennen!"
    }
    
    struct Numbers {
        static let feedCornerRadius: CGFloat = 12
        static let communityHeaderHeight: CGFloat = 260
        static let feedShadowRadius: CGFloat = 4
    }
    
    struct characterLimits {
        static let factTitleCharacterLimit = 30
        static let factDescriptionCharacterLimit = 120
        
        static let argumentTitleCharacterLimit = 85
        
        static let sourceTitleCharacterLimit = 50
        
        static let addOnTitleCharacterLimit = 50
        static let addOnDescriptionCharacterLimit = 400
        
        static let addOnHeaderTitleCharacterLimit = 50
        static let addOnHeaderDescriptionCharacterLimit = 400
        
        static let userStatusTextCharacterLimit = 150
    }
    
    struct userIDs {
        static let uidYvonne = "Im8IaMXjQxOP19vdCDjiQfJkQOO2"
        static let uidSophie = "22PWMQjhxzP4KuHcpDUfrDylJTj1"
        static let uidMalte = "CZOcL3VIwMemWwEfutKXGAfdlLy1"
        
        static let AnnaNeuhausID = "cKTJEDn6RFcZweV9t7En8zkXlnQ2"
        static let FrankMeindlID = "ltQP45PeIFMjWN2uCb8ilTwoXb02"
        static let MarkusRiesID = "4K0EgUqJXhXYttQABWyj39IVugu2"
        static let LaraVoglerID = "eICxbpDmwCWo3ixpCo1L4pXL97G3"
        static let LenaMasgarID = "mBySFkec8EZ2FWLUVyn5d8X38QF3"
    }
    struct userDefaultsStrings {
        static let hideSurveyString = "hiddenSurveysArray"
    }
    
    struct texts {
        static let voteCampaignText = NSLocalizedString("constants_voteCampaignText", comment: "whats that about? (infoText)")
        
        static let postCampaignText = NSLocalizedString("constants_postCampaignText", comment: "whats that about? (infoText)")
        
        static let campaignDetailText = NSLocalizedString("constants_campaignDetailText", comment: "whats that about? (infoText)")
        
        static let voteDetailText = NSLocalizedString("constants_voteDetailText", comment: "whats that about? (infoText)")
        
        static let jobOfferText = NSLocalizedString("constants_jobOfferText", comment: "whats that about? (infoText)")
        
        static let createRepostText = NSLocalizedString("constants_createRepostText", comment: "whats that about? (infoText)")
        
        static let factOverviewText = NSLocalizedString("constants_factOverviewText", comment: "whats that about? (infoText)")
        
        static let argumentOverviewText = NSLocalizedString("constants_argumentOverviewText", comment: "whats that about? (infoText)")
        
        static let argumentDetailText = NSLocalizedString("constants_argumentDetailText", comment: "whats that about? (infoText)")
        

        static let addArgumentText = NSLocalizedString("constants_addArgumentText", comment: "whats that about? (infoText)")
        
        static let markPostText = NSLocalizedString("constants_markPostText", comment: "whats that about? (infoText)")
        
        static let postAnonymousText = NSLocalizedString("constants_postAnonymousText", comment: "whats that about? (infoText)")
        
        static let reportBugText = NSLocalizedString("constants_reportBugText", comment: "whats that about? (infoText)")
        
        static let principleText = "”Give Peace a Chance” war der Wunsch von vielen jungen Menschen der 60er Jahre. Die Aussichten waren düster und die Hoffnung gering, doch die Menschen sind für ihre Überzeugungen eingestanden.\nHeute haben wir diesen Frieden, sowie weitreichenden Wohlstand in vielen Ländern.\nNur kommt dieser Wohlstand mit einer untragbaren Last, welche der Natur und den unteren Schichten aufgelegt ist.\nNun sind unsere Aussichten düster, die Zeit scheint abzulaufen und vielen fehlt die Hoffnung. Lasst uns organisieren und nutzen wir das Medium unserer Zeit einmal nachhaltig und verbinden Unterhaltung und Nutzen!\n\nKommunikation, Transparenz und soziale Verantwortung sind für uns die wichtigsten Merkmale für ein faires Miteinander zwischen User/Kunde und Unternehmen.  Wir hoffen, dass in Zukunft Unternehmen eine offene Atmosphäre zu ihren Kunden aufbauen und pflegen. Ihr gegenseitliches Handeln sollte verständlich dargelegt und nicht in langen Datenschutz- und Nutzungsrichtlinien verschlüsselt werden.  Firmen suchen trotz hoher Einnahmen, Steuer- und Gesetzeslücken um ihren Profit zu maximieren, während die User und Allgemeinheit nicht berücksichtigt werden.   Das Umdenken der Unternehmen muss eingefordert werden. Im Informationszeitalter haben Konsumenten die Möglichkeit sich zu vernetzen, ihre Rechte einzufordern und die derzeitige Profitgier anzuprangern. "
        
        static let postOfFactText = "Hier werden alle Beiträge zu dem ausgewählten Thema angezeigt.\n\nSpäter wird man diese unterteilen können in allgemeine Statements zum Thema, hilfreichen Tips zur Bekämpfung/Unterstützung etc.\n\nSiehst du das Potential?"
        
        static let introText = "Willkommen bei Imagine, Freund!\n\n\nIn unserem Netzwerk wollen wir das Medium unserer Zeit endlich nachhaltig verwenden und Unterhaltung mit einem Nutzen verbinden.\n\nSchau dich um, tausch dich aus, lass dich unterhalten und starte die nächste Generation der sozialen Netzwerke mit uns!"
        
        static let communityText = NSLocalizedString("constants_communityText", comment: "whats that about? (infoText)")
        
        struct AddOns {
            static let singleTopicText = NSLocalizedString("constants_addOns_singleTopicText", comment: "whats that about? (infoText)")
            
            static let collectionText = NSLocalizedString("constants_addOns_normalText", comment: "whats that about? (infoText)")
            
            
        }
    }
    
}
