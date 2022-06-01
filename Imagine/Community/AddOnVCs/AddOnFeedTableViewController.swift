//
//  AddOnFeedTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 25.08.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

class AddOnFeedTableViewController: BaseFeedTableViewController {
    
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerImageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var thanksButton: DesignableButton!
    
    var addOn: AddOn?
    var addOnPosts = [Post]()
    
    var Headerview : UIView!
    var NewHeaderLayer : CAShapeLayer!
    
    var dismissBarButton: UIBarButtonItem?
    
    private var Headerheight : CGFloat = 250
    private let Headercut : CGFloat = 0
    private var dismissHeight: CGFloat = 450
    
    var isTransparent = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setAddOn()
        setBarButtons()
        
        UpdateView()
        self.refreshControl?.attributedTitle = NSAttributedString(string: "")
        self.refreshControl?.removeTarget(self, action: #selector(getPosts(getMore:)), for: .touchUpInside)
        
        edgesForExtendedLayout = .top
        self.isFactSegueEnabled = false //DOnt go to the topic in said same topic
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
    }
    
    func setAddOn() {
        guard let info = addOn else { return }
        
        DispatchQueue.global(qos: .background).async {
            for item in info.items {
                if let post = item.item as? Post {
                    post.language = info.fact.language
                    self.addOnPosts.append(post)
                }
            }
            
            self.firestoreRequest.getPostsFromDocumentIDs(posts: self.addOnPosts) { posts in
                if let posts = posts {
                    if let orderList = info.itemOrder { // If an itemOrder exists (set in addOn-settings), order according to it
                        
                        DispatchQueue.global(qos: .default).async {
                            let sorted = posts.compactMap { object in
                                orderList.index(of: object.documentID).map { index in (object, index) }
                            }.sorted(by: { $0.1 < $1.1 } ).map { $0.0 }
                            
                            self.posts = sorted
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    } else {
                        
                        let sortedPosts = posts.sorted(by: { $0.createDate ?? Date() > $1.createDate ?? Date() })
                        self.posts = sortedPosts
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSettingSegue" {
            if let vc = segue.destination as? SettingTableViewController {
                if let addOn = sender as? AddOn {
                    vc.addOn = addOn
                    vc.settingFor = .addOn
                }
            }
        }
        if segue.identifier == "showPost" {
            if let chosenPost = sender as? Post {
                if let postVC = segue.destination as? PostViewController {
                    postVC.post = chosenPost
                }
            }
        }
    }
    
    @objc func settingButtonTapped() {
        guard let addOn = addOn else { return }
        
        performSegue(withIdentifier: "toSettingSegue", sender: addOn)
    }
    
    @objc func dismissTapped() {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func thanksButtonTapped(_ sender: Any) {
        thanksButton.titleLabel?.tintColor = .systemBackground
        thanksButton.isEnabled = false
    }
    
    func setBarButtons() {
        //create new Button for the profilePictureButton
        guard let addOn = addOn else { return }
        
        let dismissButton = DesignableButton(image: UIImage(named: "DismissTemplate"), tintColor: .white)
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        dismissButton.constrain(width: 23, height: 23)
        
        let dismissBarButton = UIBarButtonItem(customView: dismissButton)
        self.dismissBarButton = dismissBarButton
        
        if let user = AuthenticationManager.shared.user, user.uid == addOn.OP {
            let settingButton = DesignableButton(image: Icons.settings)
            settingButton.addTarget(self, action: #selector(self.settingButtonTapped), for: .touchUpInside)
            settingButton.constrain(width: 30, height: 30)
            
            let settingBarButton = UIBarButtonItem(customView: settingButton)
            self.navigationItem.rightBarButtonItems = [dismissBarButton, settingBarButton]
            
            return
        }
        
        self.navigationItem.rightBarButtonItem = dismissBarButton
    }
    
    
    //MARK:-Animations
    func UpdateView() {
        
        //got it from https://github.com/swifthublearning
        guard let info = addOn else { return }
        
        if let imageURL = info.imageURL {
            if let url = URL(string: imageURL) {
                headerImageView.sd_setImage(with: url, completed: nil)
            }
        } else {
            Headerheight = 90
            headerImageViewHeight.constant = 15
            dismissHeight = 300
            
            if let button = dismissBarButton {
                button.customView?.tintColor = .label
            }
        }
        
        if let title = info.headerTitle {
            titleLabel.text = title
        }
        descriptionLabel.text = info.description
        
        Headerview = tableView.tableHeaderView
        tableView.tableHeaderView = nil
        tableView.addSubview(Headerview)
        
        NewHeaderLayer = CAShapeLayer()
        NewHeaderLayer.fillColor = UIColor.black.cgColor
        Headerview.layer.mask = NewHeaderLayer
        
        let newheight = Headerheight - Headercut / 2
        tableView.contentInset = UIEdgeInsets(top: newheight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -newheight)
        
        self.Setupnewview()
    }
    
    func Setupnewview() {   //ScrollViewDidScroll

        let newheight = Headerheight - Headercut / 2
        var getheaderframe = CGRect(x: 0, y: -newheight, width: tableView.bounds.width, height: Headerheight)
        if tableView.contentOffset.y < newheight {
            getheaderframe.origin.y = tableView.contentOffset.y
            getheaderframe.size.height = -tableView.contentOffset.y + Headercut / 2
            
            
             if getheaderframe.size.height >= dismissHeight {
                dismiss(animated: true, completion: nil)
             }
             
            if getheaderframe.size.height <= 0 {
                if isTransparent {
                    self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default) //showBar
                    if let button = dismissBarButton {
                        button.customView?.tintColor = .label
                    }
                    isTransparent = false
                }
            } else {
                if !isTransparent {
                    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default) //hideBar
                    isTransparent = true
                    
                    if let button = dismissBarButton {
                        button.customView?.tintColor = .white
                    }
                    self.navigationItem.title = nil
                }
            }
        }
        
        Headerview.frame = getheaderframe
        let cutdirection = UIBezierPath()
        cutdirection.move(to: CGPoint(x: 0, y: 0))
        cutdirection.addLine(to: CGPoint(x: getheaderframe.width, y: 0))
        cutdirection.addLine(to: CGPoint(x: getheaderframe.width, y: getheaderframe.height))
        cutdirection.addLine(to: CGPoint(x: 0, y: getheaderframe.height - Headercut))
        NewHeaderLayer.path = cutdirection.cgPath
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.tableView.decelerationRate = UIScrollView.DecelerationRate.fast
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.Setupnewview()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        performSegue(withIdentifier: "showPost", sender: post)
    }
    
}
