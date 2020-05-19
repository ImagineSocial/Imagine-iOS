//
//  ArgumentPageViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class ArgumentPageViewController: UIPageViewController {
    
    @IBOutlet weak var factInfoBarButtonItemView: DesignablePopUp!
    @IBOutlet weak var factInfoImageView: DesignableImage!
    @IBOutlet weak var factInfoTopicLabel: UILabel!
    @IBOutlet weak var factInfoSectionLabel: UILabel!

    var argumentVCs = [UIViewController]()
    var fact: Fact?
    var displayMode: DisplayOption = .fact
    
    var recentTopicDelegate: RecentTopicDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self
        
        let pageControl = UIPageControl.appearance()
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = .systemBackground
            pageControl.pageIndicatorTintColor = .tertiaryLabel
            pageControl.currentPageIndicatorTintColor = .label
        } else {
           self.view.backgroundColor = .white
            pageControl.pageIndicatorTintColor = .lightGray
            pageControl.currentPageIndicatorTintColor = .black
        }
        
        addViewController()
        
        setBarButton()
    }
    
    func setBarButton() {
        if let fact = fact {
            recentTopicDelegate?.topicSelected(fact: fact)
            if let url = URL(string: fact.imageURL) {
                factInfoImageView.sd_setImage(with: url, completed: nil)
            }
            factInfoTopicLabel.text = fact.title
            
        }
        factInfoBarButtonItemView.alpha = 0
    }
    
    func addViewController() {
        guard let fact = fact else {
            return
        }
        
        if let optionalInformationVC = storyboard?.instantiateViewController(withIdentifier: "optionalInformationVC") as? OptionalInformationForArgumentTableViewController {
            
            optionalInformationVC.fact = fact
            argumentVCs.append(optionalInformationVC)
        }
        
        if displayMode == .fact {
        
            if let factParentVC = storyboard?.instantiateViewController(withIdentifier: "factParentVC") as? FactParentContainerViewController {
                
                factParentVC.fact = fact
                argumentVCs.append(factParentVC)
            }
        }
        
        if let postOfFactVC = storyboard?.instantiateViewController(withIdentifier: "postsOfFactVC") as? PostsOfFactTableViewController {
            
            postOfFactVC.fact = fact
            argumentVCs.append(postOfFactVC)
            
            if displayMode == .fact {
                postOfFactVC.isMainViewController = false
            }
        }
        
        if displayMode == .fact {
            if let secondVC = argumentVCs[1] as? FactParentContainerViewController {
                setViewControllers([secondVC], direction: .forward, animated: true, completion: nil)
            }
        } else {
            if let secondVC = argumentVCs[1] as? PostsOfFactTableViewController {
                setViewControllers([secondVC], direction: .forward, animated: true, completion: nil)
            }
        }
    }
}

extension ArgumentPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        for view in self.view.subviews {
            if view.isKind(of:UIScrollView.self) {
                view.frame = UIScreen.main.bounds
            } else if view.isKind(of:UIPageControl.self) {
                view.backgroundColor = UIColor.white.withAlphaComponent(0.4)
                let y = view.frame.origin.y
                let x = view.frame.width/2
                view.frame = CGRect(x: x-25, y: y, width: 50, height: 20)
                view.layer.cornerRadius = 5
                
            }
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if let currentViewController = pageViewController.viewControllers?.first
            ,let index = argumentVCs.index(of: currentViewController){
            changeBarButtonItem(index: index)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
        UIView.animate(withDuration: 0.3) {
            self.factInfoBarButtonItemView.alpha = 0
        }
        
    }
    
    func changeBarButtonItem(index: Int) {
        if index == 0 { // CommunityViewController is shown
            //show Vision bar button
            self.factInfoSectionLabel.text = "Themen"
            
            UIView.animate(withDuration: 0.2) {
                self.factInfoBarButtonItemView.alpha = 1
            }
        } else if index == 1 {  // VisionViewController is shown
            // "Back to Community" Bar button
            
            UIView.animate(withDuration: 0.2) {
                self.factInfoBarButtonItemView.alpha = 0
            }
            
        } else if index == 2 {
            self.factInfoSectionLabel.text = "Beiträge"
            
            UIView.animate(withDuration: 0.2) {
                self.factInfoBarButtonItemView.alpha = 1
            }
            
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        
        if let index = argumentVCs.firstIndex(of: viewController) {
            if index > 0 {
                return argumentVCs[index - 1]
            } else {
                return nil
            }
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        
        if let index = argumentVCs.firstIndex(of: viewController) {
            if index < argumentVCs.count - 1 {
                return argumentVCs[index + 1]
            } else {
                return nil
            }
        }
        
        return nil
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return argumentVCs.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 1
    }
    
    
}


