//
//  Extensions.swift
//  Imagine
//
//  Created by Malte Schoppe on 26.08.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Date
extension Date {
    
    func formatRelativeString() -> String {
        let dateFormatter = DateFormatter()
        
        let calendar = Calendar(identifier: .gregorian)
        dateFormatter.doesRelativeDateFormatting = true
        
        if calendar.isDateInToday(self) {
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
        } else if calendar.isDateInYesterday(self){
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .medium
        } else if calendar.compare(Date(), to: self, toGranularity: .weekOfYear) == .orderedSame {
            let weekday = calendar.dateComponents([.weekday], from: self).weekday ?? 0
            return dateFormatter.weekdaySymbols[weekday-1]
        } else {
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .short
        }
        
        return dateFormatter.string(from: self)
    }
    
    func formatForFeed() -> String {
        let dateFormatter = DateFormatter()
        
        let calendar = Calendar(identifier: .gregorian)
        dateFormatter.doesRelativeDateFormatting = true
        
        var feedString = ""
        let date = Date()
        
        // To-do: the date variable is not in the correct time zone??
        
        if calendar.isDateInToday(self) {
            
            if date.hoursLater(than: self) == 0 {
                feedString = "Vor ein paar Minuten"
            } else {
                let hoursAgoString = NSLocalizedString("%d hours ago", comment: "How many hours is the post old")
                
                feedString = String.localizedStringWithFormat(hoursAgoString, date.hoursLater(than: self))
            }
            
        } else if calendar.isDateInYesterday(self){
            feedString = NSLocalizedString("yesterday", comment: "yesterday")
        } else {
            if self.daysAgo == 1 {
                feedString = NSLocalizedString("yesterday", comment: "yesterday")
            } else {
                let daysAgoString = NSLocalizedString("%d days ago", comment: "How many days is the post old")
                
                feedString = String.localizedStringWithFormat(daysAgoString, self.daysAgo)
            }
        }
        
        return feedString
    }
}

// MARK: - TextView

extension UITextView{

    func numberOfLines() -> Int{
        if let fontUnwrapped = self.font{
            return Int(self.contentSize.height / fontUnwrapped.lineHeight)
        }
        return 0
    }

}

// MARK: - UIView

extension UIView {
    func fadeTransition(_ duration:CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
    
    func activityStartAnimating() {
        let backgroundView = UIView()
        backgroundView.frame = CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        backgroundView.backgroundColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:0.2)
        backgroundView.tag = 475647
        
        let loadingView: UIView = UIView()
        loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = self.center
        loadingView.backgroundColor = UIColor(red:0.27, green:0.27, blue:0.27, alpha:0.6)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
        activityIndicator = UIActivityIndicatorView(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50))
        activityIndicator.center = CGPoint(x: loadingView.frame.size.width / 2,
                                           y: loadingView.frame.size.height / 2)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .whiteLarge
        activityIndicator.color = .white
        activityIndicator.startAnimating()
        self.isUserInteractionEnabled = false
        
        loadingView.addSubview(activityIndicator)
        backgroundView.addSubview(loadingView)
        
        self.addSubview(backgroundView)
        activityIndicator.startAnimating()
    }
    
    func activityStopAnimating() {
        if let background = viewWithTag(475647){
            background.removeFromSuperview()
        }
        self.isUserInteractionEnabled = true
    }
    
    class func fromNib<T: UIView>() -> T {
        return Bundle(for: T.self).loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
    
    func showNoInternetConnectionView() {
        let infoView = UIView()
        infoView.translatesAutoresizingMaskIntoConstraints = false
        infoView.clipsToBounds = true
        infoView.layer.cornerRadius = 5
        infoView.backgroundColor = .imagineColor
        infoView.tag = 2580
        
        let imageView = UIImageView(image: UIImage(named: "noConnectionWhite"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 16)
        label.numberOfLines = 0
        label.minimumScaleFactor = 0.5
        label.textColor = .white
        label.textAlignment = .left
        label.text = "Hmmm, Imagine can't connect to the internet."
        
        let dismissButton = DesignableButton()
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.setImage(UIImage(named: "DismissWhite"), for: .normal)
        dismissButton.addTarget(self, action: #selector(removeNoConncectionView), for: .touchUpInside)
        
        infoView.addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 5).isActive = true
        imageView.centerYAnchor.constraint(equalTo: infoView.centerYAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 45).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 45).isActive = true
        
        infoView.addSubview(label)
        label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10).isActive = true
        label.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: 10).isActive = true
        label.topAnchor.constraint(equalTo: infoView.topAnchor, constant: -5).isActive = true
        label.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: 10).isActive = true
        
        infoView.addSubview(dismissButton)
        dismissButton.widthAnchor.constraint(equalToConstant: 15).isActive = true
        dismissButton.heightAnchor.constraint(equalToConstant: 15).isActive = true
        dismissButton.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -5).isActive = true
        dismissButton.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 5).isActive = true
        
        
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(infoView)
            infoView.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 10).isActive = true
            infoView.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -10).isActive = true
            infoView.heightAnchor.constraint(equalToConstant: 75).isActive = true
            let bottomConstraint = infoView.bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: 100)
            bottomConstraint.isActive = true
            
            window.layoutIfNeeded()
            infoView.layoutIfNeeded()
            
            bottomConstraint.constant = -55
            
            UIView.animate(withDuration: 1) {
                infoView.layoutIfNeeded()
                window.layoutIfNeeded()
            }
        }
    }
    
    @objc func removeNoConncectionView() {
        
        if let window = UIApplication.shared.keyWindow {
            if let infoView = window.viewWithTag(2580){
                UIView.animate(withDuration: 0.5, animations: {
                    infoView.alpha = 0
                }) { (_) in
                    infoView.removeFromSuperview()
                    print("Remove the view")
                }
            }
        }
    }

}

//MARK:-LayoutConstraint
extension NSLayoutConstraint {
    /**
     Change multiplier constraint

     - parameter multiplier: CGFloat
     - returns: NSLayoutConstraint
    */
    func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {

        NSLayoutConstraint.deactivate([self])

        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)

        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier

        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
}

//MARK:- UIScrollView
extension UIScrollView {
    
    var isAtTop: Bool {
        return contentOffset.y <= verticalOffsetForTop
    }
    
    var isAtBottom: Bool {
        return contentOffset.y >= verticalOffsetForBottom
    }
    
    var verticalOffsetForTop: CGFloat {
        let topInset = contentInset.top
        return -topInset
    }
    
    var verticalOffsetForBottom: CGFloat {
        let scrollViewHeight = bounds.height
        let scrollContentSizeHeight = contentSize.height
        let bottomInset = contentInset.bottom
        let scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight
        return scrollViewBottomOffset
    }
    
}


// MARK: - String

extension String {
    var youtubeID: String? {
        let pattern = "((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)"
        
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: count)
        
        guard let result = regex?.firstMatch(in: self, range: range) else {
            return nil
        }
        
        return (self as NSString).substring(with: result.range)
    }
    
    var imgurID: String? {
        // Better pattern possible, couldnt find solution for an "logical or" for "gallery/" und ".com/"
        
        if self.contains("imgur") {
            if self.contains("gallery") {
                print("Eine Galerie")
                
                let pattern = "(?<=gallery/)([\\w-]++)" //|(?<=.com/)
                
                let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(location: 0, length: count)
                
                guard let result = regex?.firstMatch(in: self, range: range) else {
                    return nil
                }
                //https://i.imgur.com/CmxSTlU.mp4
                print("Klappt: \((self as NSString).substring(with: result.range))")
                return (self as NSString).substring(with: result.range)
            } else {
                print("Keine Galerie")
                
                let pattern = "(?<=.com/)([\\w-]++)" //|(?<=.com/)
                
                let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(location: 0, length: count)
                
                guard let result = regex?.firstMatch(in: self, range: range) else {
                    return nil
                }
                //https://i.imgur.com/CmxSTlU.mp4
                print("Klappt: \((self as NSString).substring(with: result.range))")
                return (self as NSString).substring(with: result.range)
            }
        } else {
            print("Not an Imgur link")
            return nil
        }
    }
    
    static var quotes: (String, String) {
        guard
            let bQuote = Locale.current.quotationBeginDelimiter,
            let eQuote = Locale.current.quotationEndDelimiter
            else { return ("\"", "\"") }

        return (bQuote, eQuote)
    }

    var quoted: String {
        let (bQuote, eQuote) = String.quotes
        return bQuote + self + eQuote
    }
}

//MARK: -UIColor

extension UIColor {
    
    static let imagineColor = UIColor(red:0.33, green:0.47, blue:0.65, alpha:1.0)   //#5377A6
    static let ios12secondarySystemBackground = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1.0) ////Light Mode Secondary System Background Color for older than ios13
    //#f2f2f7ff
    
}

    
//MARK: -ViewController

extension UIViewController {
    
    func alert(message: String, title: String = "") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func notLoggedInAlert() {
        let alertController = UIAlertController(title: "Nicht Angemeldet", message: "Melde dich an um alle Funktionen bei Imagine zu nutzen!", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func deleteAlert(title: String, message: String, delete: @escaping (Bool) -> Void) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Löschen", style: .destructive) { (_) in
            delete(true)
        }
        let abortAction = UIAlertAction(title: "Abbrechen", style: .cancel) { (_) in
            delete(false)
        }
        alertController.addAction(deleteAction)
        alertController.addAction(abortAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
