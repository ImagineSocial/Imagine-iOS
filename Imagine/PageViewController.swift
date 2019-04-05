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
        
        self.delegate = self
        self.dataSource = self
        
        let page1:UIViewController! = storyboard?.instantiateViewController(withIdentifier: "visionVC")
        let page2:UIViewController! = storyboard?.instantiateViewController(withIdentifier: "infoVC")
        
        pages.append(page1)
        pages.append(page2)
        
        setViewControllers([page1], direction: UIPageViewController.NavigationDirection.forward, animated: false, completion: nil)
        
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
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        
        return pages.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }

    


}
