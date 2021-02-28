//
//  PageViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 16.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class PageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    var pages = [UIViewController]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        
        self.delegate = self
        self.dataSource = self
        
        let page1:UIViewController! = storyboard?.instantiateViewController(withIdentifier: "communityVC")
//        let page2:UIViewController! = storyboard?.instantiateViewController(withIdentifier: "visionVC")
        let page2:UICollectionViewController! = storyboard?.instantiateViewController(withIdentifier: "visionSwipingVC") as? UICollectionViewController
        
        pages.append(page1)
        pages.append(page2)
//        pages.append(page3)
        
        setViewControllers([page1], direction: UIPageViewController.NavigationDirection.forward, animated: false, completion: nil)
        
        changeBarButtonItem(index: 0)
    }
    
    
    
    // Alles kopiert -> Keine Ahnung!
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let index = pages.firstIndex(of: viewController) {
            if index > 0 {
                return pages[index - 1]
            } else {
                return nil
            }
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = pages.firstIndex(of: viewController) {
            if index < pages.count - 1 {
                return pages[index + 1]
            } else {
                return nil
            }
        }
        
        return nil
    }
    
    override func viewDidLayoutSubviews() {
        for view in self.view.subviews {
            if view.isKind(of:UIScrollView.self) {
                view.frame = UIScreen.main.bounds
            } else if view.isKind(of:UIPageControl.self) {
                view.backgroundColor = UIColor.clear
            }
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if let currentViewController = pageViewController.viewControllers?.first
            ,let index = pages.index(of: currentViewController){
                changeBarButtonItem(index: index)
            }
        }
    }
    
    let barButtonForVisionVC : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(goToCommunity), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 115).isActive = true
        button.heightAnchor.constraint(equalToConstant: 25).isActive = true
        button.layer.cornerRadius = 4
        button.setTitle("< Community", for: .normal)
        button.backgroundColor = UIColor(red:0.00, green:0.60, blue:1.00, alpha:1.0)
        
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        
        return button
    }()
    
    let barButtonForCommunityVC : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 75).isActive = true
        button.heightAnchor.constraint(equalToConstant: 25).isActive = true
        button.layer.cornerRadius = 4
        button.setTitle("Vision >", for: .normal)
        button.backgroundColor = UIColor(red:0.00, green:0.60, blue:1.00, alpha:1.0)
        
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        
        return button
    }()
    
    @objc func goToVision() {
        
        changeBarButtonItem(index: 1)
        self.setViewControllers([pages[1]], direction: .forward, animated: true, completion: nil)
    }
    
    @objc func goToCommunity() {
        
        changeBarButtonItem(index: 0)
        self.setViewControllers([pages[0]], direction: .reverse, animated: true, completion: nil)
    }
    
    func changeBarButtonItem(index: Int) {
        if index == 0 { // CommunityViewController is shown
            //show Vision bar button
            
            self.navigationItem.setLeftBarButton(nil, animated: true)
            
            barButtonForCommunityVC.addTarget(self, action: #selector(goToVision), for: .touchUpInside)
            let rightBarButton = UIBarButtonItem(customView: barButtonForCommunityVC)
            rightBarButton.tintColor = .black
            self.navigationItem.setRightBarButton(rightBarButton, animated: true)
            
        } else if index == 1 {  // VisionViewController is shown
            // "Back to Community" Bar button
            
            self.navigationItem.setRightBarButton(nil, animated: true)
            
            self.tabBarController?.tabBar.isTranslucent = true
            
            barButtonForVisionVC.addTarget(self, action: #selector(goToCommunity), for: .touchUpInside)
            let leftBarButton = UIBarButtonItem(customView: barButtonForVisionVC)
            leftBarButton.tintColor = .black
            self.navigationItem.leftBarButtonItem?.tintColor = .black
            self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        }
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        
        return pages.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }

    


}
