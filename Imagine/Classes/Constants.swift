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
        static let anonymPosterName = "Ein anonymer Nutzer"
        static let textOfTheWeek = "Tauscht euch aus, seid nett und lernt neue Menschen kennen!"
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
        static let voteCampaignText = "Gestaltet Imagine \n\nBei den Kampagnen könnt ihr eure eigene Idee einreichen, oder die besten Ideen eurer Mit-User unterstützen. Erreicht eine Kampagne genügend Unterstützer, wird das Anliegen vom Team überprüft. \n\nBei den Abstimmungen werden die Kampagnen aufgeführt, welche nach verschiedene Kriterien überprüft wurden und nun zur Abstimmung freigegeben sind.\n\nPro Kampagne und Abstimmung habt ihr nur eine Stimme."
        
        static let postCampaignText = "Reiche deine eigene Idee für Imagine ein.\n\nVeränderungen des Aussehens oder der Haptik, Absicherungen der Demokratie, neue vielversprechende Features, neue Arten der Zusammenarbeit oder eine Überarbeitung der Vision sind stets willkommen. \n\nDie Idee sollte natürlich im Sinne von Vielen sein und nicht gegen unsere Grundsätze verstoßen."
        
        static let campaignDetailText = "Diese Kampagne stammt von einem Mitglied von Imagine.\n\nBevor du diese Abstimmung unterstützt oder herunter wählst, versuche bitte die Auswirkungen für das Netzwerk und seiner Nutze zu bedenken. Die Idee sollte der Großzahl der User einen Nutzen bieten und keine Einzelperson hervorheben. \nAuch die Kosten und Folgekosten sollten bedacht werden. \n\nDie Kommentarfunktion für diesen Bereich folgt demnächst."
        
        static let voteDetailText = "Die Zukunft von Imagine.\n\nDiese Kampagne wurde auf mögliche Auswirkungen auf Imagine und seine User, die Kosten und Folgenkosten sowie die Dauer der Umsetzung überprüft. Wähle jetzt ob die Idee umgesetzt werden soll, oder nicht.\n\nDie Einschätzungen sind vom Imagine Team getroffen wurden und sind daher ohne Gewähr."
        
        static let jobOfferText = "Wir brauchen eure Hilfe in vielen Bereichen.\n\nWir wollen nicht auf Investoren angewiesen sein und möchten unser Netzwerk unabhängig aufbauen. Glaubst du an unsere Vision und entdeckst einen Bereich der dir oder einem Freund liegt, schreib uns gerne an, indem du den Bereich auswählst und den grünen Button am Ende drückst.\n\nWir würden uns freuen."
        
        static let createRepostText = "Repost mit zwei Möglichkeiten.\n\n1. Repost: Du möchtest  einen Post, der deiner Meinung nach zu wenig Aufmerksamkeit bekommen hat, erneut in den Umlauf bringen.\n\n2. Übersetzung: Übersetze einen Beitrag und stelle diesen so auch für eine andere Sprache bereit. Gedacht für einen Austausch über Länder- und Sprachgrenzen hinaus.\n\nDie Auswahl von Sprachen für seinen Feed folgt."
        
        static let factOverviewText = "Communities sollen bei Imagine dazu dienen, dass sich die User über verschiedene Themen, Hobbies und Interessen austauschen können. In einer Community werden alle verlinkten Beiträge und Unterthemen dargestellt. Die Communities, ihre Inhalte und Unterthemen sind alle von Usern erstellt.\n\nZusätzlich gibt es eine Diskussions-Darstellung, welche Argumente für und gegen eine Tatsache übersichtlich darstellt, inklusive Quellen und Gegenargumenten. So kann man neutral diskutieren und sich übersichtlich eine Meinung bilden."
        
        static let argumentOverviewText = "Darstellung aller bisher eingereichten Argumente für und gegen den ausgewählten Fakt.\n\nArgumente werden ausschließlich von Usern erstellt und bewertet. Fehlt hier ein Argument, füge es doch einfach am Ende der Liste hinzu. \n\nDie Bewertung der Quellen folgt in Kürze"
        
        static let argumentDetailText = "Hier werden die Quellen und Gegenargument für das ausgewählte Argument, sowie dessen Beschreibung dargestellt.\n\nAm unteren Ende findest du die Möglichkeit das Argument zu bewerten. \n\nDie Bewertung ist noch nicht abgesichert, wird aber der jetzigen Art ähneln."
        

        static let addArgumentText = "Füge eine Quelle, ein Argument oder Gegenargument hinzu.\n\nDenke bitte daran, die Inhalte neutral wiederzugeben und ausführlich, auch für außenstehende zu erklären."
        
        static let markPostText = "Markiere einen Post, wenn du ihn mit Absicht provokant schreibst oder den Inhalt bearbeitet hast. Damit wollen wir Populismus, falschen Vorstellungen und Missverständnissen vorbeugen.\n\n'Meinung': Meinung, kein Fakt. Kann schnell von den Lesern verwechselt werden.\n\n'Sensation': Sensationalistisch gegschrieben\nEine übertriebene Darstellung der beschriebenen Ereignisse.\n\n'Bearbeitet': Inhalt eines Bildes oder Videos nachträglich verschönert."
        
        static let postAnonymousText = "Wähle diese Option aus, um deinen Beitrag anonym zu teilen. \n\nFür andere wird es nicht möglich sein, diesen Post zu dir zurückzuverfolg\nSollte dieser Beitrag jedoch gegen unsere Regeln verstoßen und zum Beispiel Hassreden beinhalten, ist es für die Administatoren von Imagine möglich, die Konsequenzen deinem Profil zuzuordnen."
        
        static let reportBugText = "Sag uns, was wir für Fehler beheben sollen.\n\nSchließt sich die App abrupt, wird ein Bereich des Bildschirms falsch dargestellt oder eine Funktion funktioniert nicht, so sag uns bitte Bescheid.\n\nSelbst wenn es ein offensichtlicher Fehler ist, so wissen wir was die User am Meisten stört, je mehr Reporte zu diesem Thema bei uns eintreffen."
        
        static let principleText = "”Give Peace a Chance” war der Wunsch von vielen jungen Menschen der 60er Jahre. Die Aussichten waren düster und die Hoffnung gering, doch die Menschen sind für ihre Überzeugungen eingestanden.\nHeute haben wir diesen Frieden, sowie weitreichenden Wohlstand in vielen Ländern.\nNur kommt dieser Wohlstand mit einer untragbaren Last, welche der Natur und den unteren Schichten aufgelegt ist.\nNun sind unsere Aussichten düster, die Zeit scheint abzulaufen und vielen fehlt die Hoffnung. Lasst uns organisieren und nutzen wir das Medium unserer Zeit einmal nachhaltig und verbinden Unterhaltung und Nutzen!\n\nKommunikation, Transparenz und soziale Verantwortung sind für uns die wichtigsten Merkmale für ein faires Miteinander zwischen User/Kunde und Unternehmen.  Wir hoffen, dass in Zukunft Unternehmen eine offene Atmosphäre zu ihren Kunden aufbauen und pflegen. Ihr gegenseitliches Handeln sollte verständlich dargelegt und nicht in langen Datenschutz- und Nutzungsrichtlinien verschlüsselt werden.  Firmen suchen trotz hoher Einnahmen, Steuer- und Gesetzeslücken um ihren Profit zu maximieren, während die User und Allgemeinheit nicht berücksichtigt werden.   Das Umdenken der Unternehmen muss eingefordert werden. Im Informationszeitalter haben Konsumenten die Möglichkeit sich zu vernetzen, ihre Rechte einzufordern und die derzeitige Profitgier anzuprangern. "
        
        static let postOfFactText = "Hier werden alle Beiträge zu dem ausgewählten Thema angezeigt.\n\nSpäter wird man diese unterteilen können in allgemeine Statements zum Thema, hilfreichen Tips zur Bekämpfung/Unterstützung etc.\n\nSiehst du das Potential?"
        
        static let introText = "Willkommen bei Imagine, Freund!\n\n\nIn unserem Netzwerk wollen wir das Medium unserer Zeit endlich nachhaltig verwenden und Unterhaltung mit einem Nutzen verbinden.\n\nSchau dich um, tausch dich aus, lass dich unterhalten und starte die nächste Generation der sozialen Netzwerke mit uns!"
        
        struct AddOns {
            static let headerText = "Der Header wird den Usern als erstes in den AddOns angezeigt. Hier kannst du den Besuchern zu einem groben Überblick verhelfen und wenn nötig durch einen Link zu weiterführenden Informationen schicken."
            
            static let singleTopicText = "Möchtest du ein passendes Thema verlinken, bist du bei diesem AddOn richtig. Die Darstellung enthält auch bis zu sechs Bilder-Beiträgen des Themas als Vorschau."
            
            static let collectionText = "In diesem AddOn kann man nach belieben vorhandene oder neue Beiträge posten um ein Unterthema deiner Wahl besser zu beleuchten.\nAuch Themen kannst du hier verlinken. Möchtest du jedoch nur ein Thema hervorheben, nutze bitte das AddOn für einzelne Themen."
        }
    }
    
}
