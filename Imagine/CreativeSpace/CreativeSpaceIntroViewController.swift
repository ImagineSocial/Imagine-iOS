//
//  CreativeSpaceIntroViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 12.01.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class VisionExample {
    var description = ""
    var imageURL = ""
    var creativeType: CreativeType = .programmer
}

class CreativeSpaceIntroViewController: UIViewController {

    @IBOutlet weak var artistButton: DesignableButton!
    @IBOutlet weak var ITArtistsButton: DesignableButton!
    @IBOutlet weak var revolutionistButton: DesignableButton!
    
    let db = Firestore.firestore()
    
    var programmExamples = [VisionExample]()
    var artistExamples = [VisionExample]()
    var revolutionExamples = [VisionExample]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.backgroundColor = .black
            
            self.navigationController?.navigationBar.standardAppearance = navBarAppearance
        } else {
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.barTintColor = .black
        }
        
        let buttons = [artistButton!, ITArtistsButton!, revolutionistButton!]
        
        for button in buttons {
            let lay = button.layer
            lay.cornerRadius = 8
            lay.borderColor = UIColor.imagineColor.cgColor
            lay.borderWidth = 1
        }
        getData()
    }
    
    
    func getData() {
        let ref = db.collection("TopTopicData").document("CurrentProjects").collection("Visions")
        
        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    for document in snap.documents {
                        let data = document.data()
                        
                        if let description = data["description"] as? String, let imageURL = data["imageURL"] as? String, let type = data["type"] as? String {
                            
                            let example = VisionExample()
                            example.description = description
                            example.imageURL = imageURL
                            
                            switch type {
                            case "artist":
                                example.creativeType = .artist
                                self.artistExamples.append(example)
                            case "revolution":
                                example.creativeType = .revolution
                                self.revolutionExamples.append(example)
                            default:
                                example.creativeType = .programmer
                                self.programmExamples.append(example)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func artistButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "toCreativeExamples", sender: artistExamples)
    }
    @IBAction func ITArtistButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "toCreativeExamples", sender: programmExamples)
    }
    @IBAction func revolutionButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "toCreativeExamples", sender: revolutionExamples)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCreativeExamples" {
            if let vc = segue.destination as? CreativeExampleViewController {
                if let examples = sender as? [VisionExample] {
                    
                    vc.examples = examples
                    vc.typeOfCreative = examples[0].creativeType
                }
            }
        }
    }
    
}
