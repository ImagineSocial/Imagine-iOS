//
//  NewPostVC+MemeMode.swift
//  Imagine
//
//  Created by Don Malte on 14.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

extension NewPostVC: MemeViewDelegate {
        
    func memeModeTapped() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        showMemeMode()
    }
    
    
    func showMemeMode() {
        
        guard let window = UIApplication.keyWindow() else { return }
        
        let memeView: MemeInputView = MemeInputView.fromNib()
        memeView.delegate = self
        
        window.addSubview(memeView)
        memeView.fillSuperview()
        self.memeView = memeView
        
        view.layoutSubviews()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.letItRezzle()
        }
    }
    
    
    func letItRezzle() {    /// A little distorted effect for the meme view
        if let memeView = memeView {
            memeView.alpha = 0.98
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                
                if self.howManyFlickersIndex <= 3 {
                    
                    memeView.alpha = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.flickerInterval) {
                        self.letItRezzle()
                        self.generator.impactOccurred()
                    }
                    
                    self.flickerInterval-=0.1
                    self.howManyFlickersIndex+=1
                } else {
                    let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
                    heavyImpact.impactOccurred()
                    
                    memeView.startUpMemeMode()
                    
                    if self.selectedOption != .picture || self.selectedOption != .multiPicture {
                        //Switch to picture mode so the meme can be shown
                        // TODO: Switch to Picture Mode
                    }
                }
            }
        }
    }
    
    func showPictureAlert() {
        
        DispatchQueue.main.async {
            
            if let _ = self.memeView {  //Select image for meme, no multi picture possible
                self.showImagePicker()
            } else {
                let alert = UIAlertController(title: NSLocalizedString("how_many_pics_alert_header", comment: "How many pics do you want to post?"), message: NSLocalizedString("how_many_pics_alert_message", comment: "How many pics do you want to post?"), preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: NSLocalizedString("how_many_just_one", comment: "just one"), style: .default, handler: { (_) in
                    self.showImagePicker()
                }))
                
                
                alert.addAction(UIAlertAction(title: NSLocalizedString("how_many_three", comment: "two or three pics"), style: .default, handler: { (_) in
                    
                    //toDo: remove the selection
                    self.selectedOption = .multiPicture
                    self.openMultiPictureImagePicker()
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "cancel"), style: .destructive, handler: { (_) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func showAlert(alert: MemeViewAlert) {
        
        switch alert {
        case .error:
            self.alert(message: "Something went wrong, we're sorry! I don't know what it could be, to ask that you should try again is a bit annoying I know. Maybe flame the developers a bit, so they know where they should put more work in!", title: "Error")
        case .needMoreInfo:
            self.alert(message: "Please enter some text and add a picture.", title: "Not enough input")
        case .successfullyStored:
            self.alert(message: "Your meme has been saved!", title: "All done!")
        }
    }
    
    func selectImageForMemeTouched() {
        self.openPhotoLibrary()
    }
    
    func memeViewDismissed(meme: UIImage?) {
        if let meme = meme {
            setImagesAndShowPreview(images: [meme])
            
            let alert = UIAlertController(title: "Save your meme?", message: "Do you want to save your meme to your phone?", preferredStyle: .actionSheet)
            let yesAlert = UIAlertAction(title: "Yes", style: .default) { (_) in
                UIImageWriteToSavedPhotosAlbum(meme, nil, nil, nil)
            }
            let cancelAlert = UIAlertAction(title: "No thanks", style: .cancel) { (_) in
                alert.dismiss(animated: true)
            }
            alert.addAction(yesAlert)
            alert.addAction(cancelAlert)
            present(alert, animated: true)
        }
        
        self.memeView = nil
    }
}
