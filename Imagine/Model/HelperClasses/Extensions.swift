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
                feedString = NSLocalizedString("few_moments_ago", comment: "few_moments_ago")
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

//MARK:-LayoutConstraint
extension NSLayoutConstraint {
    /**
     Change multiplier constraint

     - parameter multiplier: CGFloat
     - returns: NSLayoutConstraint
    */
    func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {

        guard let firstItem = firstItem else { return self }
        
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


//MARK: -UIColor

extension UIColor {
    
    static let imagineColor = UIColor(red:0.33, green:0.47, blue:0.65, alpha:1.0)   //#5377A6
    static let ios12secondarySystemBackground = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1.0) ////Light Mode Secondary System Background Color for older than ios13
    //#f2f2f7ff
    static let darkRed = UIColor(red: 0.69, green: 0.00, blue: 0.00, alpha: 1.00)
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
    
    
    /**
     *  Height of status bar + navigation bar (if navigation bar exist)
     */
    var topbarHeight: CGFloat {
        (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
        (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
}

//MARK:- UIImage

extension UIImage {

  func getThumbnail() -> UIImage? {

    guard let imageData = self.pngData() else { return nil }

    let options = [
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: 300] as CFDictionary

    guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
    guard let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }

    return UIImage(cgImage: imageReference)

  }
}

//MARK:- URL
extension URL {
    
    func loadImage() -> UIImage? {
        
        guard let imageData = try? Data(contentsOf: self) else {
            return nil
        }
        
        let image = UIImage(data: imageData)
        return image
    }
}
