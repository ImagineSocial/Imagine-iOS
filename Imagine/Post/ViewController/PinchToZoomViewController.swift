//
//  PinchToZoomViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 15.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class PinchToZoomViewController: UIViewController, UIScrollViewDelegate {
    
    var scrollView : UIScrollView!
    let imageView = UIImageView()
    var post:Post?
    var imageURL: String?
    
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
        
        let slideDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissView(gesture:)))
        slideDown.direction = .down
        
        let slideRight = UISwipeGestureRecognizer(target: self, action: #selector(dismissView(gesture:)))
        slideRight.direction = .right
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(slideDown)
        view.addGestureRecognizer(slideRight)
        
        imageView.contentMode = .scaleAspectFit
        
        showPicture()
        setUpScrollViewToZoom()
    }
    
    func setUpScrollViewToZoom() {
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4.0
        scrollView.isScrollEnabled = false
        scrollView.backgroundColor = UIColor.black
        scrollView.contentSize = imageView.bounds.size
        scrollView.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.flexibleWidth.rawValue | UIView.AutoresizingMask.flexibleHeight.rawValue)
        
        scrollView.addSubview(imageView)
        imageView.fillSuperview()
        view.addSubview(scrollView)
    }
    
    func showPicture() {
        
        if let post = post, let image = post.image {
            
            let imageWidth = image.width
            let imageHeight = image.height
            
            if let url = URL(string: image.url) {
                imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
            }
            
            let ratio = imageWidth / imageHeight
            let contentWidth = self.view.frame.width
            let newHeight = contentWidth / ratio
            let y = (self.view.frame.height-newHeight) / 2
            imageView.frame = CGRect(x: 0, y: y, width: contentWidth, height: newHeight)
        } else if let imageURL = imageURL {
            
            if let url = URL(string: imageURL) {
                imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
            }
            
            let contentWidth = self.view.frame.width
            imageView.frame.size = CGSize(width: contentWidth, height: self.view.frame.height)
        } else if let image = image {   // From Adventskalender
            imageView.image = image
            
            let contentWidth = self.view.frame.width
            imageView.frame.size = CGSize(width: contentWidth, height: self.view.frame.height)
        }
    }
    
    
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    @objc func doubleTapped() {
        if self.scrollView.zoomScale >= 2.0 {
            UIView.animate(withDuration: 0.3) {
                self.scrollView.zoomScale = 1.0
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.scrollView.zoomScale = 2.0
            }
        }
    }
    
    
    @objc func dismissView(gesture: UISwipeGestureRecognizer) {
        // Maybe different animation when you swipe to different directions
        
        UIView.animate(withDuration: 0.3, animations: {
            if let theWindow = UIApplication.keyWindow() {
                gesture.view?.frame = CGRect(x:theWindow.frame.width - 15 , y: theWindow.frame.height - 15, width: 10 , height: 10)
            }
        }) { (completed) in
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
}
