//
//  UIViewController.swift
//  Imagine
//
//  Created by Don Malte on 01.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func alert(message: String, title: String = "") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func notLoggedInAlert() {
        let alertController = UIAlertController(title: Strings.notLoggedInTitle, message: Strings.notLoggedInMessage, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func deleteAlert(title: String, message: String, delete: @escaping (Bool) -> Void) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: Strings.delete, style: .destructive) { (_) in
            delete(true)
        }
        let abortAction = UIAlertAction(title: Strings.cancel, style: .cancel) { (_) in
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
