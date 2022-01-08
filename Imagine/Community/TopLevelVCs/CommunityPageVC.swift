//
//  ArgumentPageViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAnalytics

protocol PageViewHeaderDelegate: class {
    func childScrollViewScrolled(offset: CGFloat)
}

/*
 Throughout this file, there are a few UI tweaks that are not properly implemented. When Coming to this view from the navigation controller of the main feed, the header behaves wrong.
 The boolean "headerNeedsAdjustment" is set if comming from said controller and changes a few variables in viewdidload and and when "childScrollViewScrolled" is called. If you dont use a iPhone 7 or iPhone 11 you can see slight gaps between header and navigation bar. I havent found a solution for this problem.
 
 */

class CommunityPageVC: UIPageViewController {
    
    var argumentVCs = [UIViewController]()
    var community: Community?
    
    weak var recentTopicDelegate: RecentTopicDelegate?
    
    var settingButton = DesignableButton()
    var newPostButton = DesignableButton()
    var headerView = CommunityHeaderView()
    
    var firstViewOffset: CGFloat = Constants.Numbers.communityHeaderHeight
    var secondViewOffset: CGFloat = Constants.Numbers.communityHeaderHeight
    var thirdViewOffset: CGFloat = Constants.Numbers.communityHeaderHeight
        
    var presentedVC: Int = 0
    
    let defaults = UserDefaults.standard
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self
        
        self.view.backgroundColor = .systemBackground
        
        setUpHeader()
        addViewController()
        setBarButton()
    }
    
    private func showInfoView() {
        let height = topbarHeight + 40
        
        let frame = CGRect(x: 20, y: 20, width: self.view.frame.width-40, height: self.view.frame.height-height)
        let popUpView = PopUpInfoView(frame: frame)
        popUpView.alpha = 0
        popUpView.type = .communityHeader
        
        self.view.addSubview(popUpView)
        
        UIView.animate(withDuration: 0.5) {
            popUpView.alpha = 1
        }
    }
    
    private func setUpHeader() {
        guard let community = community else {
            print("Error: Dont have a community in ArgumentPageViewController")
            self.navigationController?.popViewController(animated: true)
            return
        }

        let view = CommunityHeaderView(frame: .zero)
        view.delegate = self
        view.community = community
        
        view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: Constants.Numbers.communityHeaderHeight)
        
        self.headerView = view
        self.view.addSubview(view)
        
        if !defaults.bool(forKey: "communityHeaderInfo") {
            showInfoView()
        }
    }
    
    func addViewController() {
        guard let community = community else {
            return
        }
        
        //Add The VCs
        if let addOnCollectionVC = storyboard?.instantiateViewController(withIdentifier: "addOnCollectionVC") as? AddOnCollectionViewController {
            
            addOnCollectionVC.pageViewHeaderDelegate = self
            addOnCollectionVC.community = community
            argumentVCs.append(addOnCollectionVC)
        }
        
        if community.displayOption == .discussion {
            
            if let factParentVC = storyboard?.instantiateViewController(withIdentifier: "factParentVC") as? DiscussionParentVC {
                
                factParentVC.pageViewHeaderDelegate = self
                factParentVC.community = community
                argumentVCs.append(factParentVC)
            }
        }
        
        if let postOfFactVC = storyboard?.instantiateViewController(withIdentifier: "postsOfFactVC") as? CommunityPostTableVC {
            
            postOfFactVC.pageViewHeaderDelegate = self
            postOfFactVC.community = community
            argumentVCs.append(postOfFactVC)
        }
                
        if community.displayOption == .discussion {
            self.headerView.segmentedControlView.segmentedControl.insertSegment(withTitle: Strings.discussion, at: 1, animated: false)
        }
        
        // Set the VCs and declare the firstVC
        
        if community.isAddOnFirstView {
            self.presentedVC = 0
            self.headerView.segmentedControlView.segmentedControlChanged()
            
            if let firstVC = argumentVCs[0] as? AddOnCollectionViewController {
                setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
            }
        } else {
            self.presentedVC = 1
            self.headerView.segmentedControlView.segmentedControl.selectedSegmentIndex = 1
            self.headerView.segmentedControlView.segmentedControlChanged()
            
            if community.displayOption == .discussion {
                if let secondVC = argumentVCs[1] as? DiscussionParentVC {
                    setViewControllers([secondVC], direction: .forward, animated: true, completion: nil)
                }
            } else {
                if let secondVC = argumentVCs[1] as? CommunityPostTableVC {
                    setViewControllers([secondVC], direction: .forward, animated: true, completion: nil)
                }
            }
        }
    }
    
    private func setBarButton() {
        guard let community = community else {
            return
        }
        
        let newPostButton = DesignableButton(image: UIImage(systemName: "square.and.pencil"))
        newPostButton.addTarget(self, action: #selector(self.newPostButtonTapped), for: .touchUpInside)
        newPostButton.isHidden = true
        newPostButton.tintColor = UIColor.label
        newPostButton.constrain(width: 30, height: 30)
        
        self.newPostButton = newPostButton
        let postBarButton = UIBarButtonItem(customView: self.newPostButton)
        let shareButton = getShareTopicButton()
        let shareBarButton = UIBarButtonItem(customView: shareButton)
        
        if let user = Auth.auth().currentUser {
            for mod in community.moderators {
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
        let shareTopicButton = DesignableButton(image: UIImage(named: "openLinkButton"))
        shareTopicButton.addTarget(self, action: #selector(self.shareTopicButtonTapped), for: .touchUpInside)
        shareTopicButton.constrain(width: 20, height: 20)
        return shareTopicButton
    }
    
    func getSettingButton() -> DesignableButton {
        let settingButton = DesignableButton(image: Icons.settings)
        settingButton.addTarget(self, action: #selector(self.settingButtonTapped), for: .touchUpInside)
        settingButton.constrain(width: 25, height: 25)
        
        return settingButton
    }
    
    @objc func shareTopicButtonTapped() {
        if let community = community {
            performSegue(withIdentifier: "shareTopicSegue", sender: community)
        }
    }
    
    @objc func newPostButtonTapped() {
        if let community = self.community {
            performSegue(withIdentifier: "goToNewPost", sender: community)
        }
    }
    
    @objc func settingButtonTapped() {
        if let community = self.community {
            performSegue(withIdentifier: "toSettingSegue", sender: community)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let community = sender as? Community else {
            return
        }
        
        switch segue.identifier {
        case "goToNewPost":
            if let navCon = segue.destination as? UINavigationController, let newPostVC = navCon.topViewController as? NewPostViewController {
                newPostVC.selectedFact(fact: community, isViewAlreadyLoaded: false)
                newPostVC.comingFromPostsOfFact = true
                newPostVC.postOnlyInTopic = true
                newPostVC.newInstanceDelegate = self
            }
        case  "shareTopicSegue":
            if let navVC = segue.destination as? UINavigationController, let vc = navVC.topViewController as? NewCommunityItemTableVC {
                vc.fact = community
                vc.delegate = self
                vc.new = .shareTopic
            }
        case "toSettingSegue":
            if let vc = segue.destination as? SettingTableViewController {
                vc.topic = community
                vc.settingFor = .community
            }
        default:
            break
        }
    }
}

//MARK: - PageVC

extension CommunityPageVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if !completed { return }
        
        if let currentViewController = pageViewController.viewControllers?.first, let index = argumentVCs.index(of: currentViewController){
            
            self.presentedVC = index
            headerView.segmentedControlView.segmentedControl.selectedSegmentIndex = index
            headerView.segmentedControlView.segmentedControlChanged()
            
            switch index {
            case 0:
                self.correctHeaderViewPosition(with: firstViewOffset)
            case 1:
                self.correctHeaderViewPosition(with: secondViewOffset)
            case 2:
                self.correctHeaderViewPosition(with: thirdViewOffset)
            default:
                break
            }
        }
    }
    
    private func correctHeaderViewPosition(with offset: CGFloat) {
        
        let per:CGFloat = 100 //percentage of required view to move on while moving collection view
        let deductValue = CGFloat(per / 100 * headerView.frame.size.height)
        let value = offset - deductValue
        let rect = headerView.frame
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear) {
            self.headerView.frame = CGRect(x: rect.origin.x, y: value, width: rect.size.width, height: rect.size.height)
            self.view.layoutIfNeeded()
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        if let index = argumentVCs.firstIndex(of: viewController), index > 0 {
            return argumentVCs[index - 1]
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        if let index = argumentVCs.firstIndex(of: viewController), index < argumentVCs.count - 1 {
            return argumentVCs[index + 1]
        }
        
        return nil
    }
}


extension CommunityPageVC: PageViewHeaderDelegate, CommunityHeaderDelegate, NewFactDelegate {
    func notLoggedIn() {
        self.notLoggedInAlert()
    }
    
    func finishedCreatingNewInstance(item: Any?) {
        if let _ = item as? Post {
            self.alert(message: "Go back to the feed and reload to see your post.", title: "The community has been shared successfully!")
        } else {
            if let vc = self.argumentVCs[1] as? CommunityPostTableVC {
                vc.posts.removeAll()
                vc.tableView.reloadData()
                vc.getPosts(getMore: false)
            } else if let vc = self.argumentVCs[2] as? CommunityPostTableVC {
                vc.posts.removeAll()
                vc.tableView.reloadData()
                vc.getPosts(getMore: false)
            }
        }
    }
    
    func newPostTapped() {
        if let community = self.community {
            performSegue(withIdentifier: "goToNewPost", sender: community)
        }
    }
    
    func segmentedControlTapped(index: Int, direction: UIPageViewController.NavigationDirection) {
        
        let viewVC = self.argumentVCs[index]
        self.setViewControllers([viewVC], direction: direction, animated: true) { (_) in
            
        }
    }
    
    func childScrollViewScrolled(offset: CGFloat) {
        //Called from the different childvc's of this PageViewController
        let percent: CGFloat = 100 //percentage of required view to move on while moving collection view
        let deductValue = CGFloat(percent / 100 * headerView.frame.size.height)
        let offset = (-(percent / 100)) * (offset)    //turn minus into plus
        let value = offset - deductValue
        let rect = headerView.frame
        
        
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
    }
}


