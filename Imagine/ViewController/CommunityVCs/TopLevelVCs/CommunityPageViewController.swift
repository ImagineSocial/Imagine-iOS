//
//  ArgumentPageViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

protocol PageViewHeaderDelegate {
    func childScrollViewScrolled(offset: CGFloat)
}

/*
 Throughout this file, there are a few UI tweaks that are not properly implemented. When Coming to this view from the navigation controller of the main feed, the header behaves wrong.
 The boolean "headerNeedsAdjustment" is set if comming from said controller and changes a few variables in viewdidload and and when "childScrollViewScrolled" is called. If you dont use a iPhone 7 or iPhone 11 you can see slight gaps between header and navigation bar. I havent found a solution for this problem.
 
 */

class ArgumentPageViewController: UIPageViewController {
    
    var argumentVCs = [UIViewController]()
    var fact: Community?
    
    var recentTopicDelegate: RecentTopicDelegate?
    
    var settingButton = DesignableButton()
    var newPostButton = DesignableButton()
    var headerView = CommunityHeaderView()
    
    var firstViewOffset: CGFloat = 260
    var secondViewOffset: CGFloat = 260
    var thirdViewOffset: CGFloat = 260//156
    
    
    var headerNeedsAdjustment = false //If this view is opened from the main feed or postvc it has a different navigation height and therefore is on the wrong place
    var showNavigationTitle = true  //No navigation title when coming from main feed navigation controller because the font would be wrong
    
    var presentedVC: Int = 0
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self
        
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = .systemBackground
        } else {
            self.view.backgroundColor = .white
        }
        setUpHeader()
        addViewController()
        setBarButton()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.headerNeedsAdjustment = false
        }
        
        if headerNeedsAdjustment {
            showNavigationTitle = false
            let addedHeight: CGFloat!
            let bounds = UIScreen.main.bounds
            //FML I just dont get it
            if bounds == CGRect(x: 0, y: 0, width: 375, height: 667) {  //iPhone 7
                addedHeight = 64
            } else {
                addedHeight = 92
            }
            firstViewOffset = 260+addedHeight   //Hard coded doesnt work when coming from feed
            secondViewOffset = 260+addedHeight
            thirdViewOffset = 260+addedHeight
        }
        
        let commHeaderShown = defaults.bool(forKey: "communityHeaderInfo")
        if !commHeaderShown {
            showInfoView()
        }
    }
    
    func showInfoView() {
        let upperHeight = UIApplication.shared.statusBarFrame.height +
              self.navigationController!.navigationBar.frame.height
        let height = upperHeight+40
        
        let frame = CGRect(x: 20, y: 20, width: self.view.frame.width-40, height: self.view.frame.height-height)
        let popUpView = PopUpInfoView(frame: frame)
        popUpView.alpha = 0
        popUpView.type = .communityHeader
        
        self.view.addSubview(popUpView)
        
        UIView.animate(withDuration: 0.5) {
            popUpView.alpha = 1
        }
    }
    
    func setUpHeader() {
        let view = CommunityHeaderView.loadViewFromNib()
        view.delegate = self
        let height = Constants.Numbers.communityHeaderHeight
        view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: height)
        
        if let fact = self.fact {
            view.community = fact
        } else {
            print("Error: ArgumentPageViewController")
            self.navigationController?.popViewController(animated: true)
        }
        
        self.headerView = view
        self.view.addSubview(view)
    }
    
    func setBarButton() {
        let newPostButton = DesignableButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        newPostButton.clipsToBounds = true
        newPostButton.imageView?.contentMode = .scaleAspectFit
        newPostButton.addTarget(self, action: #selector(self.newPostButtonTapped), for: .touchUpInside)
        newPostButton.translatesAutoresizingMaskIntoConstraints = false
        newPostButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        newPostButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        newPostButton.isHidden = true
        
        if #available(iOS 13.0, *) {
            newPostButton.tintColor = UIColor.label
            newPostButton.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        } else {
            newPostButton.tintColor = UIColor.black
            newPostButton.setImage(UIImage(named: "newPostIcon"), for: .normal)
        }
        
        guard let fact = fact else {
            return
        }
        
        self.newPostButton = newPostButton
        let postBarButton = UIBarButtonItem(customView: self.newPostButton)
        let shareButton = getShareTopicButton()
        let shareBarButton = UIBarButtonItem(customView: shareButton)
        
        if let user = Auth.auth().currentUser {
            for mod in fact.moderators {
                if mod == user.uid {
                    self.settingButton = getSettingButton()
                    let settingBarButton = UIBarButtonItem(customView: self.settingButton)
                    self.navigationItem.rightBarButtonItems = [settingBarButton, shareBarButton, postBarButton]
                    
                    return
                }
            }
        }
        
        self.navigationItem.rightBarButtonItems = [shareBarButton, postBarButton]
    }
    
    func getShareTopicButton() -> DesignableButton {
        let shareTopicButton = DesignableButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        shareTopicButton.clipsToBounds = true
        shareTopicButton.imageView?.contentMode = .scaleAspectFit
        shareTopicButton.addTarget(self, action: #selector(self.shareTopicButtonTapped), for: .touchUpInside)
        shareTopicButton.translatesAutoresizingMaskIntoConstraints = false
        shareTopicButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        shareTopicButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        shareTopicButton.setImage(UIImage(named: "openLinkButton"), for: .normal)
        
        if #available(iOS 13.0, *) {
            shareTopicButton.tintColor = UIColor.label
        } else {
            shareTopicButton.tintColor = UIColor.black
        }
        
        return shareTopicButton
    }
    
    func getSettingButton() -> DesignableButton {
        let settingButton = DesignableButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        settingButton.clipsToBounds = true
        settingButton.imageView?.contentMode = .scaleAspectFit
        settingButton.addTarget(self, action: #selector(self.settingButtonTapped), for: .touchUpInside)
        settingButton.translatesAutoresizingMaskIntoConstraints = false
        settingButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        settingButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        settingButton.setImage(UIImage(named: "settings"), for: .normal)
        
        if #available(iOS 13.0, *) {
            settingButton.tintColor = UIColor.label
        } else {
            settingButton.tintColor = UIColor.black
        }
        
        return settingButton
    }
    
    @objc func shareTopicButtonTapped() {
        if let community = fact {
            performSegue(withIdentifier: "shareTopicSegue", sender: community)
        }
    }
    
    @objc func newPostButtonTapped() {
        if let community = self.fact {
            performSegue(withIdentifier: "goToNewPost", sender: community)
        }
    }
    
    @objc func settingButtonTapped() {
        if let community = self.fact {
            performSegue(withIdentifier: "toSettingSegue", sender: community)
        }
    }
    
    //MARK:-Prepare For Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToNewPost" {
            if let fact = sender as? Community {
                if let navCon = segue.destination as? UINavigationController {
                    if let newPostVC = navCon.topViewController as? NewPostViewController {
                        newPostVC.selectedFact(fact: fact, isViewAlreadyLoaded: false)
                        newPostVC.comingFromPostsOfFact = true
                        newPostVC.postOnlyInTopic = true
                        newPostVC.newInstanceDelegate = self
                    }
                }
            }
        }
        
        if segue.identifier == "shareTopicSegue" {
            if let fact = sender as? Community {
                if let navVC = segue.destination as? UINavigationController {
                    if let vc = navVC.topViewController as? NewCommunityItemTableViewController {
                        vc.fact = fact
                        vc.delegate = self
                        vc.new = .shareTopic
                    }
                }
            }
        }
        
        if segue.identifier == "toSettingSegue" {
            if let fact = sender as? Community {
                if let vc = segue.destination as? SettingTableViewController {
                    vc.topic = fact
                    vc.settingFor = .community
                }
            }
        }
    }
    
    func addViewController() {
        guard let fact = fact else {
            return
        }
        
        //Add The VCs
        if let addOnCollectionVC = storyboard?.instantiateViewController(withIdentifier: "addOnCollectionVC") as? AddOnCollectionViewController {
            
            addOnCollectionVC.pageViewHeaderDelegate = self
            addOnCollectionVC.fact = fact
            argumentVCs.append(addOnCollectionVC)
        }
        
        if fact.displayOption == .fact {
        
            if let factParentVC = storyboard?.instantiateViewController(withIdentifier: "factParentVC") as? CommunityParentContainerViewController {
                
                
                
                factParentVC.pageViewHeaderDelegate = self
                factParentVC.fact = fact
                argumentVCs.append(factParentVC)
            }
        }
        
        if let postOfFactVC = storyboard?.instantiateViewController(withIdentifier: "postsOfFactVC") as? PostsOfFactTableViewController {
            
            postOfFactVC.pageViewHeaderDelegate = self
            postOfFactVC.fact = fact
            argumentVCs.append(postOfFactVC)
            
        }
        
        if fact.displayOption == .fact {
            self.headerView.headerSegmentedControl.setTitle(NSLocalizedString("topics", comment: "topics"), forSegmentAt: 0)
            self.headerView.headerSegmentedControl.insertSegment(withTitle: NSLocalizedString("discussion", comment: "discussion"), at: 1, animated: false)
            self.headerView.headerSegmentedControl.setTitle("Feed", forSegmentAt: 2)
        } else {
            self.headerView.headerSegmentedControl.setTitle(NSLocalizedString("topics", comment: "topics"), forSegmentAt: 0)
            self.headerView.headerSegmentedControl.setTitle("Feed", forSegmentAt: 1)
        }
        
        // Set the VCs and declare the firstVC
        
        if fact.isAddOnFirstView {
            self.presentedVC = 0
            self.headerView.segmentedControlChanged(self)
            
            if let firstVC = argumentVCs[0] as? AddOnCollectionViewController {
                setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
            }
        } else {
            self.presentedVC = 1
            self.headerView.headerSegmentedControl.selectedSegmentIndex = 1
            self.headerView.segmentedControlChanged(self)
            
            if fact.displayOption == .fact {
                Analytics.logEvent("DiscussionOpened", parameters: [
                    AnalyticsParameterTerm: ""
                ])
                if let secondVC = argumentVCs[1] as? CommunityParentContainerViewController {
                    setViewControllers([secondVC], direction: .forward, animated: true, completion: nil)
                }
            } else {
                if let secondVC = argumentVCs[1] as? PostsOfFactTableViewController {
                    setViewControllers([secondVC], direction: .forward, animated: true, completion: nil)
                }
            }
        }
        
        
        
    }
    
//    override func viewDidLayoutSubviews() {
//        barButtonPageControl.subviews.forEach {
//            $0.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
//        }
//    }
}

//MARK:- PageVC
extension ArgumentPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        if let nextVC = pendingViewControllers.first
        ,let index = argumentVCs.index(of: nextVC){

            headerView.headerSegmentedControl.selectedSegmentIndex = index
            headerView.segmentedControlChanged(self)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        Analytics.logEvent("SwipedThroughCommunity", parameters: [
            AnalyticsParameterTerm: ""
        ])
        
        if let currentViewController = pageViewController.viewControllers?.first
            ,let index = argumentVCs.index(of: currentViewController){

            
            self.presentedVC = index
            
            switch index {
            case 0:
                
                self.animateToRightSizeOfHeader(offset: firstViewOffset)
            case 1:
                self.animateToRightSizeOfHeader(offset: secondViewOffset)
            case 2:
                self.animateToRightSizeOfHeader(offset: thirdViewOffset)
            default:
                print("Wrong index")
            }
        }
    }
    
    func animateToRightSizeOfHeader(offset: CGFloat) {
        print("#animateToSize: \(offset)")
        let per:CGFloat = 100 //percentage of required view to move on while moving collection view
        let deductValue = CGFloat(per / 100 * headerView.frame.size.height)
        let value = offset - deductValue
        let rect = headerView.frame
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.presentNavigationTitle(rectOriginY: value)
            self.headerView.frame = CGRect(x: rect.origin.x, y: value, width: rect.size.width, height: rect.size.height)
            self.view.layoutIfNeeded()
        }) { (_) in
            print("Done")
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
}


extension ArgumentPageViewController: PageViewHeaderDelegate, CommunityFeedHeaderDelegate, NewFactDelegate {
    func notLoggedIn() {
        self.notLoggedInAlert()
    }

    func finishedCreatingNewInstance(item: Any?) {
        if let _ = item as? Post {
            self.alert(message: "Kehre zum Hauptfeed zurück und aktualisiere diesen, um deinen Beitrag zu sehen.", title: "Die Community wurde erfolgreich geteilt!")
        } else {
            if let vc = self.argumentVCs[1] as? PostsOfFactTableViewController {
                vc.posts.removeAll()
                vc.tableView.reloadData()
                vc.getPosts(getMore: false)
            } else if let vc = self.argumentVCs[2] as? PostsOfFactTableViewController {
                vc.posts.removeAll()
                vc.tableView.reloadData()
                vc.getPosts(getMore: false)
            }
        }
    }
    
    func newPostTapped() {
        if let community = self.fact {
            performSegue(withIdentifier: "goToNewPost", sender: community)
        }
    }
    
    func segmentedControlTapped(index: Int, direction: UIPageViewController.NavigationDirection) {
        
        let viewVC = self.argumentVCs[index]
        self.setViewControllers([viewVC], direction: direction, animated: true) { (_) in
            
        }
    }
    
    func presentNavigationTitle(rectOriginY: CGFloat) {

        if rectOriginY <= -250 {
            if let community = fact {
                self.navigationItem.title = community.title
                self.newPostButton.isHidden = false
            }
        } else {
            self.navigationItem.title = ""
            self.newPostButton.isHidden = true
        }
    }
    
    func childScrollViewScrolled(offset: CGFloat) {
        //Called from the different childvc's of this PageViewController
//        print("#")
//        print("#")
//        print("#")
//        print("#ChildViewScrolled First Offset: \(offset)")
        let per:CGFloat = 100 //percentage of required view to move on while moving collection view
        let deductValue = CGFloat(per / 100 * headerView.frame.size.height)
        let offset = (-(per/100)) * (offset)    //turn minus into plus
        var value = offset - deductValue
        let rect = headerView.frame
//        print("#let deductValue: \(deductValue)")
//        print("#let offset: \(offset)")
//        print("#let value: \(value)")
//        print("#let rect.size.height: \(rect.size.height)")
//
//        let screenSize: CGRect = UIScreen.main.bounds
//        print("#ScreenSize: \(screenSize)")
        
        if let fact = fact {
            if headerNeedsAdjustment && !fact.isAddOnFirstView {
                let addedHeight: CGFloat!
                let bounds = UIScreen.main.bounds
                //FML I just dont get it
                if bounds == CGRect(x: 0, y: 0, width: 375, height: 667) {  //iPhone 7
                    addedHeight = 64
                } else {
                    addedHeight = 92
                }
                value = value+addedHeight
            }
        }
            
        //childScrollViewScrolled(offset: -352)
        self.headerView.frame = CGRect(x: rect.origin.x, y: value, width: rect.size.width, height: rect.size.height)
        
        switch presentedVC {
        case 0:
            let difference = self.firstViewOffset-offset
            
            if difference > 40 || difference < -40 {
                return
            }
            self.firstViewOffset = offset
        case 1:
            self.secondViewOffset = offset
        case 2:
            self.thirdViewOffset = offset
        default:
            self.firstViewOffset = 0
        }
        
        if showNavigationTitle { //Weird big font looks bad
            presentNavigationTitle(rectOriginY: rect.origin.y)
        }
    }
}


