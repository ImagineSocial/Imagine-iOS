//
//  CobraViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 03.06.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class CobraViewController: UIViewController {

    @IBOutlet weak var outterStackView: UIStackView!
    @IBOutlet weak var outterProgress: KDCircularProgress!
    @IBOutlet weak var middleProgress: KDCircularProgress!
    @IBOutlet weak var innerProgress: KDCircularProgress!
    @IBOutlet weak var clickCountLabel: UILabel!
    @IBOutlet weak var showMeButton: DesignableButton!
    @IBOutlet weak var oneMillionColorLabel: UILabel!
    @IBOutlet weak var fiftyMillionColorLabel: UILabel!
    @IBOutlet weak var hundredMillionColorLabel: UILabel!
    
    let db = Firestore.firestore()
    
    var clickCount:Double = 0
    let trackThickness: CGFloat = 0.4
    let progressThickness: CGFloat = 0.3
    var colorLabelCornerRadius:CGFloat = 15
    var actualTapCount = 0
    var showLockedInAlert = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpView()
        getCobraCount()
    }
    
    func getCobraCount() {
        let ref = db.collection("Feedback").document("cobra")
        
        ref.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    if let data = snap.data() {
                        
                        if let cobraCount = data["cobraCount"] as? Double {
                            self.clickCount = cobraCount
                            self.setNumber(clickCount: cobraCount)
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let _ = Auth.auth().currentUser {
            if actualTapCount != 0 {
                let ref = db.collection("Feedback").document("cobra")
                print("Update count")
                ref.updateData([
                    "cobraCount": FirebaseFirestore.FieldValue.increment(Int64(actualTapCount))
                ]) { (err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        print("Successfully updated cobracount")
                    }
                }
            }
        }
    }
    
    func setUpView() {
        
        outterProgress.progressThickness = progressThickness
        middleProgress.progressThickness = progressThickness
        innerProgress.progressThickness = progressThickness
        
        outterProgress.trackThickness = trackThickness
        middleProgress.trackThickness = trackThickness
        innerProgress.trackThickness = trackThickness
        
        outterProgress.roundedCorners = true
        middleProgress.roundedCorners = true
        innerProgress.roundedCorners = true
        
        outterProgress.glowMode = .noGlow
        middleProgress.glowMode = .noGlow
        innerProgress.glowMode = .noGlow
        
        outterProgress.set(colors: .white)
        middleProgress.set(colors: .white)
        innerProgress.set(colors: .white)
        
        let outterProgressNumber:Double = 360/(100000000/clickCount)
        let middleProgressNumber:Double = 360/(50000000/clickCount)
        let innerProgressNumber:Double = 360/(1000000/clickCount)
        
        outterProgress.angle = outterProgressNumber
        middleProgress.angle = middleProgressNumber
        innerProgress.angle = innerProgressNumber
        
        oneMillionColorLabel.layer.cornerRadius = colorLabelCornerRadius
        fiftyMillionColorLabel.layer.cornerRadius = colorLabelCornerRadius
        hundredMillionColorLabel.layer.cornerRadius = colorLabelCornerRadius
        
    }
    
    func setNumber(clickCount: Double) {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = "."
        formatter.numberStyle = .decimal
        let nsnumber = NSNumber(value: clickCount)
        let stringNumber = formatter.string(from: nsnumber)
        
        if let stringNumber = stringNumber {
            clickCountLabel.text = stringNumber
        }
    }
    
    @IBAction func showMeTapped(_ sender: Any) {
        let user = Auth.auth().currentUser
        if user == nil {
            self.notLoggedInAlert()
        }
        
        clickCount = clickCount+1
        actualTapCount = actualTapCount+1
        
        setNumber(clickCount: clickCount)
        
        let outterProgressNumber:Double = 360/(100000000/clickCount)
        let middleProgressNumber:Double = 360/(50000000/clickCount)
        let innerProgressNumber:Double = 360/(1000000/clickCount)
        
        outterProgress.angle = outterProgressNumber
        middleProgress.angle = middleProgressNumber
        innerProgress.angle = innerProgressNumber
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
