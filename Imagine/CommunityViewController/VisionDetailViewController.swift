//
//  VisionDetailViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 19.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class VisionDetailViewController: UIViewController {

    var visionText = ""
    var textForVision = ""
    var textForStep1 = ""
    var textForStep2 = ""
    var textForStep3 = ""
    var textForStep4 = ""
    var textForStep5 = ""
    
    
    let scrollView = UIScrollView()
    let contentView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupScrollView()
        setupViews()
        setupTexts()
        setVision()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        dismissButton.layer.cornerRadius = dismissButton.bounds.size.width / 2
    }
    
    func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
//        contentView.layoutIfNeeded()
    }
    
    func setupViews() {
        contentView.addSubview(dismissButton)
        dismissButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 25).isActive = true
        dismissButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        dismissButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        dismissButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        dismissButton.layoutIfNeeded() // Damit er auch rund wird
        
        contentView.addSubview(headerLabel)
        headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 50).isActive = true
        headerLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        headerLabel.heightAnchor.constraint(equalToConstant: 65).isActive = true
        
        contentView.addSubview(subHeaderLabel)
        subHeaderLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 10).isActive = true
        subHeaderLabel.centerXAnchor.constraint(equalTo: headerLabel.centerXAnchor).isActive = true
        subHeaderLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        contentView.addSubview(mainDescriptionLabel)
        mainDescriptionLabel.topAnchor.constraint(equalTo: subHeaderLabel.bottomAnchor, constant: 25).isActive = true
        mainDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        mainDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        mainDescriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15).isActive = true
    }
    
    let dismissButton : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .lightGray
        button.layer.masksToBounds = true
        button.setTitle("x", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        
        return button
    }()
    
    let headerLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "Kalam-Bold", size: 34.0)
        label.text = "Malte Schoppator"
        label.textColor = UIColor(red:0.22, green:0.45, blue:0.50, alpha:1.0)
        
        return label
    }()
    
    let subHeaderLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "Kalam-Bold", size: 24.0)
        label.text = "Ist der Mastor"
        label.textColor = UIColor.lightGray
        
        return label
    }()
    
    let mainDescriptionLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.italicSystemFont(ofSize: 20)
        label.text = "Hier steht eine ganz Ausführliche Beschreibung für die Vision"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.sizeToFit()
        
        return label
    }()
    
    

    func setVision() {
        switch visionText {
        case "vision":
            headerLabel.text = "Imagine..."
            subHeaderLabel.text = "Gegenseitig helfen und beistehen"
            mainDescriptionLabel.text = textForVision
            break
        case "step1":
            headerLabel.text = "Peace in Mind"
            subHeaderLabel.text = "Den Menschen einen neuen Nutzen bieten"
            mainDescriptionLabel.text = textForStep1
            break
        case "step2": visionText = "step2"
            break
        case "step3": visionText = "step3"
            break
        case "step4": visionText = "step4"
            break
        case "step5": visionText = "step5"
            break
        default:
            visionText = ""
        }
    }
    
    @objc func dismissTapped() {
        dismiss(animated: true, completion: nil)
    }

    
    func setupTexts() {
        textForVision = "Wer bist du? Was macht dich aus? Was war das Highlight der Woche für dich? Was sorgt dafür, dass deine Welt über dir zusammenzubrechen scheint? \n\n Jeder Mensch hat seine ganz eigenen Erfahrungen gemacht und einen Charakter gebildet der keinem zweiten gleicht. Brechen wir unseren Charakter jedoch in einzelne Bereiche, die Interessen, Geschmäcker oder Glücksmomente aber auch die Ängste, Scham oder Probleme dann sehen wir schnell, dass wir sie mit tausenden teilen! \n\n Lasst uns einen Ort schaffen an dem wir uns gegenseitig in unseren verschiedenen Lebenslagen helfen. Lasst uns austauschen über unsere Highlights, unsere Ängste und unsere Freuden.  \n\n Teilen wir unsere Gedanken mit anderen, unterstützen wir einander mit unseren Erfahrungen, können uns beistehen, die Glücksmomente teilen oder inspiriert werden den Blick zu ändern und Neues auszuprobieren.\n\nDie Weitergabe von Wissen ist der Samen unserer Gesellschaft und nun haben wir mithilfe des Internets eine Chance den nächsten Schritt einzuleiten!\n\nEs wird Zeit: Die Lage der Welt hat einen kritischen Punkt erreicht. Wir sehen nicht nur über Ländergrenzen mit Skepsis sondern auch im eigenen Land, in der eigenen Straße. Den Menschen fehlt die Hoffnung. Hoffnung auf Besserung und eine gerechte Zukunft. Politische Spannungen definieren unseren Umgang miteinander und Schuldzuweisungen sind unsere einzige Lösung.\n\nTauschen wir uns mit unseren Mitmenschen aus, können wir ihre Ansichten besser verstehen. Unsere Beweggründe sind häufig von Ängsten und Vorstellungen geprägt, die wir uns zeigen und verstehen müssen.\n\nWir sollten uns wieder unserer Mitmenschen bewusst werden, ein Pflichtbewusstsein für unsere Gesellschaft entwickeln und ein Gefühl von Gemeinschaft aufbauen. Geben wir den Menschen ihre Hoffnung zurück. Doch wie schaffen wir das?"
        
        textForStep1 = "Wir setzen uns das Ziel, ein globales soziales Netzwerk zu gründen. Von der Community für die Community. Einen Ort für jeden Glauben. Einen Ort für jede politische Ausrichtung. Einen Ort für alle Menschen!\n\nEin weiteres Social-Network? Man könnte meinen, die derzeitigen Angebote an sozialen Netzwerken sollten dafür sorgen, dass wir uns besser kennenlernen, uns gegenseitig in den verschiedenen Lebenslagen unterstützen und die Menschen aus der ganzen Welt vereinen. Dies ist nicht der Fall.\n\nVor ein paar Jahren haben wir unser Umfeld der realen Welt mit in die digitale genommen und es um ein paar flüchtige Bekanntschaften erweitert. Über die Jahre beschränkten wir uns auf das was wir bereits kennen, die großen Netzwerke unterstützen uns dabei erfolgreich.\n\nUnsere persönlichen Feeds bestehen aus unseren eigenen Interessen und Ansichten und bilden eine Echokammer unseres Charakters. Wie können wir so eine Gemeinschaft werden? \n\nWas wir dabei sehen macht uns nicht einmal glücklich. Wir schauen uns die gefilterte Welt von anderen an und werden unglücklich wenn wir sie auf unsere reflektieren. Die kleinen Fehler und Kratzer werden mit größter Mühe versteckt und die User bleiben mit falschen Vorstellungen zurück.\nAuch sind es nur wenige, die sich an das digitale Publikum wenden. Viele beobachten nur die Aktivitäten von Anderen und sind unsicher, da sie glauben ihr Beitrag sei nicht interessant genug oder er kriege nicht genügend ”likes”.\n\nWir wollen anders sein. Weg von einem Ideal von oberflächlichem Erfolg, Materialismus und Titeln. Unser Ideal ist das wahre private Glück und wir wollen jedem helfen es zu finden. Wir schätzen eine ehrliche Selbstdarstellung und einen offenen Verstand. Sind wir ehrlich zu uns selbst und stehen zu unseren Problemen, dann können wir leichter unser persönliches Glück finden.\n\nEs gibt drei Möglichkeiten seine Beiträge zu teilen: Der User kann seine persönlichen Momente mit seinen engen Freunden und Bekannten teilen. Fachlich spezifische Beiträge kann man in einer ausgewählten Interessengruppe posten, wenn diese für die Allgemeinheit zu speziell sind. \nDas teilen mit der gesamten Gemeinschaft ist die dritte Möglichkeit und der Kern von Imagine. Daher werden die User dazu aufgerufen ihre Beiträge mit dem gesamten Netzwerk zu teilen.\n\n• Menschen zusammenbringen: Unsere Post-Algorithmen sorgen dann für eine breite Verteilung der Posts, nicht nur an Freunde und Follower. Durch zusätzliche, zufällig ausgewählte User wird garantiert, dass die Einsendung von verschiedenen Personen gesehen wird. So versammeln sich viele Meinungen und Erfahrungen zu den unterschiedlichen Anliegen. Durch die relativ kleine Gruppe von Leuten, welche den Post zuerst sieht, wird zudem die Kommunikation im Kommentarbereich gefördert und so auch das kennenlernen von Gleichgesinnten. \n\nDer persönliche Feed der User wird also aus einer gesunden Mischung aus Sachen die dich Interessieren (d.h. Freunde und Personen bzw. Interessen denen du folgst), den beliebtesten Posts des Tages und Einsendungen von komplett Fremden. So gewähren wir jedem eine Stimme und sorgen für ein breites Meinungs- und Informationsfeld. \n\nDem Networking-Effekt wird durch unsere Post-Verteilung vorgebeugt. Während es bei anderen Netzwerken zu Beginn einsam ist, wenn Freunde und Bekannte noch nicht beigetreten sind, wird man bei Imagine direkt aufgenommen und erhält einen interessanten Feed den man schrittweise optimiert. \n\nDie Interaktion mit den Posts ist vielseitig (Namen werden noch geändert damit sie gut klingen): Mit dem ”Interessant-Button” zeigt man dem Verfasser, dass man die Information des Posts spannend und interessant fand. Vielleicht hilft es einem weiter im Leben, vielleicht hat man etwas wichtiges dazugelernt, vielleicht wurde man nur ein wenig überrascht. \nDer ”Funny-Button” ist logischerweise für die witzigen Einsendungen gedacht.   Wir wollen natürlich unterhalten werden bei Imagine, unser größtes Anliegen jedoch ist es, uns als Menschen zu unterstützen. Der wichtigste Button ist daher der ”Danke-Button”, da er die Essenz der Seite enthält.  \nDiese Funktion hält damit die höchste Wertung im Algorithmus. Sprechen wir also von den beliebtesten Posts des Tages, ist ein hilfreicher Post dort leichter zu finden als ein unterhaltsamer.\n\n• Grenzen Überwinden: Eine Grundfunktion ist das einfache übersetzen von Posts und Kommentaren in andere Sprachen. Jeder der eine zweite Sprache beherrscht wird dazu angehalten die Posts die sie für interessant und hilfreich halten über Ländergrenzen hinaus zu verbreiten. Die User sollen nicht nur ein besseres Bild von ihrem Nachbarn, sondern auch von Nachbarland und ferner Fremde haben. Wir müssen erkennen wie viel uns vereint und was wir gemein haben. Die Wirtschaft ist längst globalisiert, die Auswirkungen sind es leider auch.\nEs wird Zeit für die Menschen ebenfalls ein globales Bewusstsein aufzubauen! \n\nDamit wir uns wohl fühlen, wenn wir unsere Gedanken teilen, schaffen wir eine Umgebung, die uns versichert, dass mit unseren Ansichten und Gefühlen respektvoll umgegangen wird.\n\n• Klare Regeln:\n- Niemand muss Schimpfwörter benutzen um seine Meinung auszudrücken\n-Niemand muss beleidigen um eine Diskussion für sich zu entscheiden.\n-Es gibt nicht einen Grund um Gewalt zu rechtfertigen.\n-Bei uns wird ein Mensch aufgrund seiner selbst beurteilt und nicht nach seiner Herkunft, Hautfarbe oder Religion.\nEs gibt genügend Räume im Internet wo man sich nach belieben auslassen kann, unser Netzwerk wird keines davon sein.\n\n• Klare Konsequenzen: Wird ersichtlich, dass ein User eine negative Stimmungverbreiten möchte oder unseren einfachen Regeln bricht, folgen klar festgelegte Konsequenzen. Von Ermahnungen bis hin zu sperren von verschiedenen Längen wird auf Strenge aber auch auf weitere Chancen gesetzt. \n\n• Kontrolle: Um Missbrauch durch Moderatoren oder geschlossene Interessengemeinschaften zu umgehen, entscheiden willkürlich ausgesuchte User (Jury) durch Abstimmung über die einzelnen Fälle.\n\nFake-Profile und Bots, welche den Konsequenzen durch mehrere Profile entkommen, entstehen durch die Möglichkeit einen neuen Account mit einem unpersönlichen Konto wie zum Beispiel einer E-Mail Adresse zu erstellen.\nDamit dies nicht möglich ist, wird zu Beginn eine Telefonnummer für die Anmeldung benötigt und später ein KYC (Know-Your-Customer = Überprüfen ob es die Person gibt)."
    }
    
}
