//
//  MemeView.swift
//  Imagine
//
//  Created by Malte Schoppe on 13.01.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

protocol MemeViewDelegate {
    func selectImageForMemeTouched()
    func memeViewDismissed(meme: UIImage?)
    func showAlert(alert: MemeViewAlert)
}

enum MemeViewAlert {
    case needMoreInfo
    case error
    case successfullyStored
}

class MemeInputView: UIView {
    
    @IBOutlet weak var headerTitle: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var memeLabel: UILabel!
    @IBOutlet weak var memeView: UIView!
    @IBOutlet weak var memeTitleLabel: UILabel!
    @IBOutlet weak var memeImageView: UIImageView!
    @IBOutlet weak var selectMemeImageButton: UIButton!
    @IBOutlet weak var memeInputTextView: UITextView!
    @IBOutlet weak var memeModeBackgroundImage: UIImageView!
    @IBOutlet weak var dismissButton: DesignableButton!
    @IBOutlet weak var doneButton: DesignableButton!
    @IBOutlet weak var downloadMemeButton: DesignableButton!
    @IBOutlet weak var memeTextViewTopToMemeTopConstraint: NSLayoutConstraint!
    
    
    let radius: CGFloat = 10
    var delegate: MemeViewDelegate?
    var memeImage: UIImage?
    
    override func awakeFromNib() {
        //Input TextField
        memeInputTextView.delegate = self
        memeInputTextView.textContainer.maximumNumberOfLines = 4
        memeInputTextView.textContainer.lineBreakMode = .byTruncatingTail
        
        let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        memeModeBackgroundImage.isUserInteractionEnabled = true
        memeModeBackgroundImage.addGestureRecognizer(tapRecogniser)
        
        //UI
        memeModeBackgroundImage.layer.cornerRadius = radius
        memeView.layer.cornerRadius = radius
        self.layer.cornerRadius = radius
        memeImageView.layer.cornerRadius = 5
        
    }
    
    override func layoutSubviews() {
        
        //to display the text in the right scale to the meme in the end
        let width = self.frame.width
        let textViewTopToMemeTop = width/14.8
        memeTextViewTopToMemeTopConstraint.constant = textViewTopToMemeTop
        
        //the meme is 1200*1110 with font size 60 in the end -> 1200/60 = 20
        let fontSize = width/20
        memeTitleLabel.font = UIFont(name: "Helvetica Neue Medium", size: fontSize)
    }
    
    @objc func dismissKeyboard() {
        memeInputTextView.resignFirstResponder()
    }
    
    func imageSelected(image: UIImage) {
        memeImageView.image = image
        self.memeImage = image
        
        selectMemeImageButton.setTitle("", for: .normal)    //Otherwise the text overlays the selected image
    }
    
    func createMeme(text: String, image: UIImage) -> UIImage? {
        
        //White image with imagine logo in the corner
        let backgroundImage = UIImage(named: "whiteBackgroundMemeImage")!

        let memewidth: CGFloat = 1200
        let memeHeight: CGFloat = 1110
        let innerMemeContentWidth: CGFloat = 1160
        let innerMemeContentHeightForRatio16To9: CGFloat = 652
        let memeTextHeight: CGFloat = 330
        let topSpaceToText: CGFloat = 75
        let leadingSpaceToMemeContent: CGFloat = 20
        let memeSize = CGSize(width: memewidth, height: memeHeight)
        
        let textColor = UIColor.black
        let textFont = UIFont(name: "Helvetica Neue Medium", size: 60)!
        
        // Setup the font attributes that will be later used to dictate how the text should be drawn
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
        ]
        
        UIGraphicsBeginImageContextWithOptions(memeSize, false, 0.0)

        //Add Image
        backgroundImage.draw(in: CGRect(origin: CGPoint.zero, size: memeSize))
        
        let imageYValue = topSpaceToText+memeTextHeight+30
        image.draw(in: CGRect(origin: CGPoint(x: leadingSpaceToMemeContent, y: imageYValue), size: CGSize(width: innerMemeContentWidth, height: innerMemeContentHeightForRatio16To9)))
        
        //Add Text
        let rect = CGRect(origin: CGPoint(x: leadingSpaceToMemeContent, y: topSpaceToText), size: CGSize(width: innerMemeContentWidth, height: memeTextHeight))
        text.draw(in: rect, withAttributes: textFontAttributes)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    //MARK:- Button Interactions
    @IBAction func doneButtonTapped(_ sender: Any) {
        let text = memeInputTextView.text
        
        if let text = text, text != "", let image = memeImage {
            if let meme = createMeme(text: text, image: image) {
                
                //send it back to the newPostVC
                delegate?.memeViewDismissed(meme: meme)
                
                dismissMemeView()
            } else {
                delegate?.showAlert(alert: .error)
            }
        } else {
            delegate?.showAlert(alert: .needMoreInfo)
        }
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        //TODO: Alert if dismiss when selected something already
        dismissMemeView()
    }
    
    func dismissMemeView() {
        UIView.animate(withDuration: 0.5) {
            self.alpha = 0
        } completion: { (_) in
            self.removeFromSuperview()
        }
    }
    
    @IBAction func selectImageButton(_ sender: Any) {
        delegate?.selectImageForMemeTouched()
    }
    
    @IBAction func memeTextTapped(_ sender: Any) {
        memeInputTextView.becomeFirstResponder()
    }
    
    @IBAction func downloadMemeTapped(_ sender: Any) {
        let text = memeInputTextView.text
        
        if let text = text, text != "", let image = memeImage {
            if let meme = createMeme(text: text, image: image) {
                
                //save the image
                UIImageWriteToSavedPhotosAlbum(meme, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
                    
            } else {
                delegate?.showAlert(alert: .error)
            }
        } else {
            delegate?.showAlert(alert: .needMoreInfo)
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {

        if error == nil {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            delegate?.showAlert(alert: .successfullyStored)
        } else {
            delegate?.showAlert(alert: .error)
        }
    }
    
    
    
    //MARK:- Special Intro Stuff
    
    func startUpMemeMode() {    ///Load everything one after one so it seems that it is starting up in a retro fashion
        
        let dispatch = DispatchQueue.main
        
        dispatch.asyncAfter(deadline: .now() + .milliseconds(200)) {
            self.headerTitle.alpha = 1
            self.rezzleOnce()
            
            dispatch.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.memeLabel.alpha = 1
                self.textLabel.alpha = 1
                self.rezzleOnce()
                
                dispatch.asyncAfter(deadline: .now() + .milliseconds(125)) {
                    self.dismissButton.alpha = 1
                    self.downloadMemeButton.alpha = 1
                    self.rezzleOnce()
                    
                    dispatch.asyncAfter(deadline: .now() + .milliseconds(125)) {
                        self.memeModeBackgroundImage.alpha = 1
                        self.rezzleOnce()
                        
                        dispatch.asyncAfter(deadline: .now() + .milliseconds(75)) {
                            self.memeView.alpha = 1
                            self.rezzleOnce()
                            
                            dispatch.asyncAfter(deadline: .now() + .milliseconds(100)) {
                                self.setShadowToView()
                                self.rezzleOnce()
                                
                                dispatch.asyncAfter(deadline: .now() + .milliseconds(150)) {
                                    self.doneButton.alpha = 1
                                    self.selectMemeImageButton.alpha = 1
                                    self.rezzleOnce()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setShadowToView() {    /// Set Shadow to Meme View
        
        let layer = self.memeView.layer
        layer.cornerRadius = radius
        layer.shadowColor = UIColor(red: 0.05, green: 0.97, blue: 0.97, alpha: 1.00).cgColor
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.9
        
        let frame = self.memeView.frame
        let rect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        layer.shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
    }
    
    func rezzleOnce() { ///Vibrate Once
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
}

extension MemeInputView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if let text = textView.text {
            memeTitleLabel.text = text
        }
    }
    
    
}
