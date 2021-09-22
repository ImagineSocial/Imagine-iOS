//
//  UIViewExtensions.swift
//  Imagine
//
//  Created by Malte Schoppe on 12.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

// MARK: - UIView

extension UIView {
    
    func setDefaultShadow() {
        let cornerRadius: CGFloat = Constants.cellCornerRadius
        
        let layer = self.layer
        layer.cornerRadius = cornerRadius
        
        layer.shadowColor = UIColor.label.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.5
        
        let rect = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        layer.shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath
    }
    
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
        backgroundView.backgroundColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:0)
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
        activityIndicator.style = .large
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
