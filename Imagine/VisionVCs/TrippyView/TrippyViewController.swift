//
//  TrippyViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 30.04.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class TrippyViewController: UIViewController {

   var waveView: AnimatedWaveView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .imagineColor
        self.navigationController?.navigationBar.backgroundColor = .imagineColor
        buildWaveView()
        setButtons()
        
        let slideDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissView(gesture:)))
        slideDown.direction = .down
        
        let slideRight = UISwipeGestureRecognizer(target: self, action: #selector(dismissView(gesture:)))
        slideRight.direction = .right
        
        view.addGestureRecognizer(slideDown)
        view.addGestureRecognizer(slideRight)
    }
    
    func setButtons() {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        button.setImage(UIImage(named: "Dismiss"), for: .normal)
        
        self.view.addSubview(button)
        button.heightAnchor.constraint(equalToConstant: 23).isActive = true
        button.widthAnchor.constraint(equalToConstant: 23).isActive = true
        button.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 10).isActive = true
        button.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        
        let owen = DesignableButton()
        owen.translatesAutoresizingMaskIntoConstraints = false
        owen.addTarget(self, action: #selector(owenTapped), for: .touchUpInside)
        owen.setImage(UIImage(named: "wow"), for: .normal)
        owen.imageView?.contentMode = .scaleAspectFit
        
        self.view.addSubview(owen)
        owen.heightAnchor.constraint(equalToConstant: 55).isActive = true
        owen.widthAnchor.constraint(equalToConstant: 55).isActive = true
        owen.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        owen.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -85).isActive = true
    }
    
    @objc func owenTapped() {
        let alert = UIAlertController(title: "Hint 2/3", message: "3 seconds...", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (_) in
//            self.performSegue(withIdentifier: "showProposalSegue", sender: nil)
        }
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func dismissTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func buildWaveView() {
        let animatedWaveView = AnimatedWaveView(frame: self.view.bounds)
        self.view.addSubview(animatedWaveView)
        waveView = animatedWaveView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        waveView?.makeWaves()
    }
        
    
    @objc func dismissView(gesture: UISwipeGestureRecognizer) {
        // Maybe different animation when you swipe to different directions
        
        UIView.animate(withDuration: 0.3, animations: {
            if let theWindow = UIApplication.shared.keyWindow {
                gesture.view?.frame = CGRect(x:theWindow.frame.width - 15 , y: theWindow.frame.height - 15, width: 10 , height: 10)
            }
        }) { (completed) in
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
}
