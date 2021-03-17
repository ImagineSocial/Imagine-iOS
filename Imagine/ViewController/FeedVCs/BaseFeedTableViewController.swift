//
//  BaseFeedTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 19.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseAnalytics
import SDWebImage
import AVKit

enum PostSortOptions {
    case dateDecreasing
    case dateIncreasing
    case thanksCount
    case wowCount
    case haCount
    case niceCount
}


class BaseFeedTableViewController: UITableViewController, ReachabilityObserverDelegate {
    
    var posts = [Post]()
    let handyHelper = HandyHelper()
    lazy var firestoreRequest = FirestoreRequest()  // Lazy or it calls Firestore before AppDelegate.swift
    let db = Firestore.firestore()
    
    var sortOptionsShown = false
    var sortBy: PostSortOptions = .dateDecreasing
    
    let imageCache = NSCache<NSString, UIImage>()
    
    var fetchesPosts = true
    var noPostsType: BlankCellType = .savedPicture
    
    var fetchRequested = false
    
    let surveyCellIdentifier = "SurveyCell"
    let musicCellIdentifier = "MusicCell"
    let singleTopicCellIdentifier = "FeedSingleTopicCell"
    
    var isOwnProfile = false    //to change the button like count visibility
    
    var isFactSegueEnabled = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.extendedLayoutIncludesOpaqueBars = true
        tableViewSetup()
        
        tableView.register(UINib(nibName: "MultiPictureCell", bundle: nil), forCellReuseIdentifier: "MultiPictureCell")
        tableView.register(UINib(nibName: "RePostTableViewCell", bundle: nil), forCellReuseIdentifier: "NibRepostCell")
        tableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "NibPostCell")
        tableView.register(UINib(nibName: "LinkCell", bundle: nil), forCellReuseIdentifier: "NibLinkCell")
        tableView.register(UINib(nibName: "ThoughtPostCell", bundle: nil), forCellReuseIdentifier: "NibThoughtCell")
        tableView.register(UINib(nibName: "YouTubeCell", bundle: nil), forCellReuseIdentifier: "NibYouTubeCell")
        tableView.register(UINib(nibName: "BlankContentCell", bundle: nil), forCellReuseIdentifier: "NibBlankCell")
        tableView.register(UINib(nibName: "GifCell", bundle: nil), forCellReuseIdentifier: "GIFCell")
        tableView.register(UINib(nibName: "TopicCell", bundle: nil), forCellReuseIdentifier: "TopicCell")
        tableView.register(UINib(nibName: "SurveyCell", bundle: nil), forCellReuseIdentifier: surveyCellIdentifier)
        tableView.register(UINib(nibName: "MusicCell", bundle: nil), forCellReuseIdentifier: musicCellIdentifier)
        tableView.register(UINib(nibName: "FeedSingleTopicCell", bundle: nil), forCellReuseIdentifier: singleTopicCellIdentifier)
        
        tableView.register(UINib(nibName: "AdvertisingCell", bundle: nil), forCellReuseIdentifier: "AdvertisingCell")
    }
    
    
    
    func tableViewSetup() {
        let refreshControl = UIRefreshControl()
        tableView.separatorStyle = .none
        tableView.refreshControl = refreshControl
        
        refreshControl.addTarget(self, action: #selector(getPosts(getMore:)), for: .valueChanged)   // getMore is false in this instance
        refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString("one_moment_placeholder", comment: "one moment..."))
        
        self.tableView.addSubview(refreshControl)
    }
    
    @objc func getPosts(getMore:Bool) {
        
        
    }
    
    
    //InfoView
    
    func presentInfoView() {
        
    }
    
    //MARK:- GetName
    
    var index = 0
    func getName(row: Int) {
        if index < 20 {
            if posts.count != 0 {
                if self.posts[row].user.displayName == "" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.getName(row: row)
                        self.index+=1
                    }
                } else {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return posts.count
    }
    
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 6 {
            self.presentInfoView()
        }
        
        let post = posts[indexPath.row]
        if post.title == "ad" {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "AdvertisingCell", for: indexPath) as? AdvertisingCell {
                cell.title = "Unser neues Mittagsangebot: Hol dir einen Cafe mit unserem Bircher Müsli, #FakeAd Edition!  Löse den Imagine Gutschein-Code ein und spare 10% auf deinen Cafe!"
                return cell
            }
        }
        if let _ = post.survey {
            if let cell = tableView.dequeueReusableCell(withIdentifier: surveyCellIdentifier, for: indexPath) as? SurveyCell {
                
                cell.post = post
                cell.indexPath = indexPath
                cell.delegate = self
                
                return cell
            }
        }
        if indexPath.row % 20 == 0 {
            SDImageCache.shared.clearMemory()
        }
        
        switch post.type {
        case .multiPicture:
            let identifier = "MultiPictureCell"
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? MultiPictureCell {
                
                cell.ownProfile = isOwnProfile
                cell.delegate = self
                cell.post = post
                
                let imageHeight = post.mediaHeight
                let imageWidth = post.mediaWidth
                
                let ratio = imageWidth / imageHeight
                let width = self.view.frame.width-20  // 5+5 from contentView and 5+5 from inset
                var newHeight = width / ratio
                
                if newHeight >= 500 {
                    newHeight = 500
                }
                
                if imageHeight == 0 {
                    newHeight = 300
                }
                
                cell.multiPictureCollectionViewHeightConstraint.constant = newHeight
                
                return cell
            }
        case .panorama:
            let identifier = "MultiPictureCell"
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? MultiPictureCell {
                
                cell.ownProfile = isOwnProfile
                cell.delegate = self
                cell.post = post
                
                //TODO: Custom height or 300 if too big
                let newHeight:CGFloat = 300
                
                cell.multiPictureCollectionViewHeightConstraint.constant = newHeight
                
                return cell
            }
        case .topTopicCell:
            let identifier = "TopicCell"
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? TopicCell {
                
                cell.delegate = self
                
                return cell
            }
        case .repost:
            let identifier = "NibRepostCell"
            
            if let repostCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? RePostCell {
                
                repostCell.ownProfile = isOwnProfile
                repostCell.delegate = self
                repostCell.post = post
                
                return repostCell
            }
        case .translation:
            let identifier = "NibRepostCell"
            
            if let repostCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? RePostCell {
                
                repostCell.ownProfile = isOwnProfile
                repostCell.delegate = self
                repostCell.post = post
                
                return repostCell
            }
        case .picture:
            let identifier = "NibPostCell"
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? PostCell {
                
                cell.ownProfile = isOwnProfile
                cell.delegate = self
                cell.post = post
                
                let imageHeight = post.mediaHeight
                let imageWidth = post.mediaWidth
                
                let ratio = imageWidth / imageHeight
                let width = self.view.frame.width-20  // 5+5 from contentView and 5+5 from inset
                var newHeight = width / ratio
                
                if imageHeight == 0 {
                    newHeight = 300
                }
                
                if newHeight >= 500 {
                    newHeight = 500
                } else if newHeight <= 300 {    // Absichern, dass es auch wirklich breiter ist als der View
                    newHeight = 300
                }
                cell.cellImageViewHeightConstraint.constant = newHeight
                
                return cell
            }
        case .thought:
            let identifier = "NibThoughtCell"
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ThoughtCell {
                
                cell.ownProfile = isOwnProfile
                cell.delegate = self
                cell.post = post
                
                return cell
            }
        case .GIF:
            let identifier = "GIFCell"
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? GifCell {
                
                cell.ownProfile = isOwnProfile
                cell.post = post
                cell.delegate = self
                
                let imageHeight = post.mediaHeight
                let imageWidth = post.mediaWidth
                
                let ratio = imageWidth / imageHeight
                let width = self.view.frame.width-20  // 5+5 from contentView and 5+5 from inset
                var newHeight = width / ratio
                
                if newHeight >= 500 {
                    newHeight = 500
                }
                
                cell.GIFViewHeightConstraint.constant = newHeight
                
                if let url = URL(string: post.linkURL) {
                    cell.videoPlayerItem = AVPlayerItem.init(url: url)
                    cell.startPlayback()
                }
                
                return cell
            }
        case .link:
            if post.music != nil {
                if let cell = tableView.dequeueReusableCell(withIdentifier: musicCellIdentifier, for: indexPath) as? MusicCell {
                    
                    cell.ownProfile = isOwnProfile
                    cell.post = post
                    cell.delegate = self
                    cell.musicPostDelegate = self
                    
                    return cell
                }
            } else {
                let identifier = "NibLinkCell"
                
                if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? LinkCell {
                    
                    cell.ownProfile = isOwnProfile
                    cell.delegate = self
                    cell.post = post
                    
                    return cell
                }
            }
        case .youTubeVideo:
            let identifier = "NibYouTubeCell"
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? YouTubeCell {
                
                cell.ownProfile = isOwnProfile
                cell.delegate = self
                cell.post = post
                
                return cell
            }
        case .nothingPostedYet:
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "NibBlankCell", for: indexPath) as? BlankContentCell {
                
                cell.type = noPostsType
                cell.contentView.backgroundColor = self.tableView.backgroundColor
                
                return cell
            }
        case .singleTopic:
            if let cell = tableView.dequeueReusableCell(withIdentifier: singleTopicCellIdentifier, for: indexPath) as? FeedSingleTopicCell {
                
                cell.post = post
                cell.delegate = self
                
                return cell
            }
        }
        
        
        return UITableViewCell()
    }
    
    
    
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        
        if distanceFromBottom < height {
            
            if fetchesPosts == false {
                print("Ende erreicht!")
                
                fetchesPosts = true
                self.getPosts(getMore: true)
            }
            
            // If I am at the total end of posts to fetch i got no solution for the feedtableview yet
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let post = posts[indexPath.row]
        
        switch post.type {
        case .picture:
            return 450
        case .thought:
            return 200
        case .link:
            return 210
        case .youTubeVideo:
            return 365
        case .repost:
            return 485
        case .translation:
            return 485
        case .GIF:
            return 500
        case .singleTopic:
            return 500
        default:
            return 250
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        // Check to see which table view cell was selected. Needed for searchController
        
//        var extraHeightForReportView:CGFloat = 0
//        var heightForRow:CGFloat = 150
        
        let post = posts[indexPath.row]
        let postType = post.type
        
        if post.title == "ad" {
            return UITableView.automaticDimension
        }
        
        if let _ = post.survey {
            return UITableView.automaticDimension
        }
        
//        switch post.report {
//        case .normal:
//            extraHeightForReportView = 0
//        default:
//            extraHeightForReportView = 30
//        }
        
        switch postType {
        case .topTopicCell:
            return 190
            
        case .nothingPostedYet:
            return self.view.frame.height-150
        default:
            return UITableView.automaticDimension
        }
        
    }
    
    private func resolutionForLocalVideo(url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        let cgSize = CGSize(width: abs(size.width), height: abs(size.height))
        print("Das ist die size: \(cgSize)")
        return cgSize
    }
    
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.layoutIfNeeded()
    }
//    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        cell.contentView.layer.masksToBounds = true
//        
//        let radius = cell.contentView.layer.cornerRadius
//        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: radius).cgPath
//    }
    
    
    //MARK:- Others
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goToLink" {
            if let post = sender as? Post {
                if let webVC = segue.destination as? WebViewController {
                    webVC.post = post
                }
            }
        }
    }
    
    // Not in the extension because i could not override it and dont want performSegue in Usertableview
    func userTapped(post: Post) {
        //        performSegue(withIdentifier: "toUserSegue", sender: post.user)
    }
    
    func reachabilityChanged(_ isReachable: Bool) {
        print("changed! Connection reachable: ", isReachable, "fetch requested: ", fetchRequested)
        
        if isReachable {
            if fetchRequested { // To automatically redo the requested task
                self.getPosts(getMore: true)
            }
        } else {
            // Just in the FeedTableVC
        }
    }
    
    //MARK: - TOP Sorting View
    
    let sortingStackView: UIStackView = {
    let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 3
        stack.alpha = 0
        
        let dateDecreasingButton = SortButton()
        dateDecreasingButton.setTitle(NSLocalizedString("date_descending", comment: "date with downwards arrow"), for: .normal)
        dateDecreasingButton.addTarget(self, action: #selector(sortDateDec), for: .touchUpInside)
        
        let dateIncreasingButton = SortButton()
        dateIncreasingButton.setTitle(NSLocalizedString("date_ascending", comment: "date with upwards arrow"), for: .normal)
        dateIncreasingButton.addTarget(self, action: #selector(sortDateAsc), for: .touchUpInside)
        
        let thanksCountButton = SortButton()
        thanksCountButton.setTitle(NSLocalizedString("thanks_descending", comment: "thanks with downwards arrow"), for: .normal)
        thanksCountButton.addTarget(self, action: #selector(sortThanks), for: .touchUpInside)
        
        let wowCountButton = SortButton()
        wowCountButton.setTitle("Wow ↓", for: .normal)
        wowCountButton.addTarget(self, action: #selector(sortWow), for: .touchUpInside)
        
        let haCountButton = SortButton()
        haCountButton.setTitle("Ha ↓", for: .normal)
        haCountButton.addTarget(self, action: #selector(sortHa), for: .touchUpInside)
        
        let niceCountButton = SortButton()
        niceCountButton.setTitle("Nice ↓", for: .normal)
        niceCountButton.addTarget(self, action: #selector(sortNice), for: .touchUpInside)
        
        stack.addArrangedSubview(dateDecreasingButton)
        stack.addArrangedSubview(dateIncreasingButton)
        stack.addArrangedSubview(thanksCountButton)
        stack.addArrangedSubview(wowCountButton)
        stack.addArrangedSubview(haCountButton)
        stack.addArrangedSubview(niceCountButton)
    
        return stack
    }()
    
    let dismissSortButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(decreaseTopView), for: .touchUpInside)
        
        return button
    }()
    
    @objc func sortDateDec() {
        if sortBy == .dateDecreasing {
            decreaseTopView()
        } else {
            sortBy = .dateDecreasing
            getPosts(getMore: false)
            decreaseTopView()
        }
    }
    
    @objc func sortDateAsc() {
        if sortBy == .dateIncreasing {
            decreaseTopView()
        } else {
            sortBy = .dateIncreasing
            getPosts(getMore: false)
            decreaseTopView()
        }
    }
    
    @objc func sortThanks() {
        
        if sortBy == .thanksCount {
            decreaseTopView()
        } else {
            sortBy = .thanksCount
            getPosts(getMore: false)
            decreaseTopView()
        }
    }
    
    @objc func sortWow() {
        if sortBy == .wowCount {
            decreaseTopView()
        } else {
            sortBy = .wowCount
            getPosts(getMore: false)
            decreaseTopView()
        }
    }
    
    @objc func sortHa() {
        if sortBy == .haCount {
            decreaseTopView()
        } else {
            sortBy = .haCount
            getPosts(getMore: false)
            decreaseTopView()
        }
    }
    
    @objc func sortNice() {
        if sortBy == .niceCount {
            decreaseTopView()
        } else {
            sortBy = .niceCount
            getPosts(getMore: false)
            decreaseTopView()
        }
    }
    
    @objc func decreaseTopView() {
        guard let headerView = tableView.tableHeaderView else {
          return
        }
        
        let size = CGSize(width: self.view.frame.width, height: 30)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.sortingStackView.alpha = 0
        }) { (_) in
            self.sortingStackView.isHidden = true
        }
        
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
        }
        
        self.tableView.tableHeaderView = headerView
        
        UIView.animate(withDuration: 0.7) {
            self.view.layoutIfNeeded()
        }
    }
    
    func increaseTopView() {    // For sorting purpose
        
        guard let headerView = tableView.tableHeaderView else {
          return
        }
        
        let size = CGSize(width: self.view.frame.width, height: 150)
        
        headerView.addSubview(sortingStackView)
        sortingStackView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10).isActive = true
        sortingStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10).isActive = true
        sortingStackView.widthAnchor.constraint(equalToConstant: 65).isActive = true
        sortingStackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10).isActive = true
        sortingStackView.isHidden = false
        
        headerView.addSubview(dismissSortButton)
        dismissSortButton.leadingAnchor.constraint(equalTo: sortingStackView.trailingAnchor).isActive = true
        dismissSortButton.topAnchor.constraint(equalTo: headerView.topAnchor).isActive = true
        dismissSortButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        dismissSortButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor).isActive = true
        
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
        }
        self.tableView.tableHeaderView = headerView
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }) { (_) in
            
            UIView.animate(withDuration: 0.3) {
                self.sortingStackView.alpha = 1
            }
        }
    }
}

//MARK:-SurveyCell

extension BaseFeedTableViewController: SurveyCellDelegate {
    
    func surveyCompleted(surveyID: String, indexPath: IndexPath, data: [Any], comment: String?) {
        saveSurveyDataInDatabase(surveyID: surveyID, data: data, comment: comment)
        removeSurveyCell(at: indexPath)
    }
    
    func dontShowAgain(surveyID: String, indexPath: IndexPath) {
        hideSurveyFromUser(surveyID: surveyID)
        removeSurveyCell(at: indexPath)
    }
    
    func removeSurveyCell(at indexPath: IndexPath) {
        tableView.beginUpdates()
        self.posts.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
    
    func saveSurveyDataInDatabase(surveyID: String, data: [Any], comment: String?) {
        let ref = db.collection("Feedback").document("surveys").collection("surveys").document(surveyID)
        
        let stringData = data.map({"\($0)"}).joined(separator: ",")
        
        if let comment = comment {
            ref.updateData([
                "comments" : FieldValue.arrayUnion([comment])
            ]) { (err) in
                if let error = err {
                    print("We have an error with the comment: \(error.localizedDescription)")
                } else {
                    self.hideSurveyFromUser(surveyID: surveyID)
                }
            }
        }
        
        ref.updateData([
            stringData : FieldValue.increment(Int64(1))
        ]) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
                self.createSurveyDocument(surveyID: surveyID, comment: comment, data: [stringData:1])
            } else {
                print("SUccessfully added Feedback")
                self.hideSurveyFromUser(surveyID: surveyID)
            }
        }
    }
    
    func createSurveyDocument(surveyID: String, comment: String?, data: [String:Any]) {
        let ref = db.collection("Feedback").document("surveys").collection("surveys").document(surveyID)
        
        var data = data
        if let comment = comment {
            data["comments"] = comment
        }
        
        ref.setData(data) { (err) in
            if let error = err {
                print("We really have an error!: \(error.localizedDescription)")
            } else {
                self.hideSurveyFromUser(surveyID: surveyID)
            }
        }
    }
    
    func hideSurveyFromUser(surveyID: String) {
        let defaults = UserDefaults.standard
        let hiddenSurveyArrayString = Constants.userDefaultsStrings.hideSurveyString
        var surveyStrings = defaults.stringArray(forKey: hiddenSurveyArrayString) ?? [String]()
        
        surveyStrings.append(surveyID)
        defaults.set(surveyStrings, forKey: hiddenSurveyArrayString)
    }
}

extension BaseFeedTableViewController: TopTopicCellDelegate {
    func owenTapped() {
        performSegue(withIdentifier: "toCreativeSpace", sender: nil)
    }
    
    func factOfTheWeekTapped(fact:Community) {
        performSegue(withIdentifier: "toFactSegue", sender: fact)
    }
}

extension BaseFeedTableViewController: PostCellDelegate {
    
    func collectionViewTapped(post: Post) {
        performSegue(withIdentifier: "showPost", sender: post)
    }
    
    // MARK: Cell Button Tapped
    
    func reportTapped(post: Post) {
        performSegue(withIdentifier: "meldenSegue", sender: post)
    }
    
    func thanksTapped(post: Post) {
        if let _ = Auth.auth().currentUser {
            handyHelper.updatePost(button: .thanks, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func wowTapped(post: Post) {
        if let _ = Auth.auth().currentUser {
        handyHelper.updatePost(button: .wow, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func haTapped(post: Post) {
        if let _ = Auth.auth().currentUser {
        handyHelper.updatePost(button: .ha, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func niceTapped(post: Post) {
        if let _ = Auth.auth().currentUser {
            handyHelper.updatePost(button: .nice, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func linkTapped(post: Post) {
        performSegue(withIdentifier: "goToLink", sender: post)
    }
    
    func factTapped(fact: Community) {
        if isFactSegueEnabled {
            if let user = Auth.auth().currentUser {
                if user.uid == "CZOcL3VIwMemWwEfutKXGAfdlLy1" {
                    print("Nicht bei Malte loggen")
                } else {
                    Analytics.logEvent("FactTappedInFeed", parameters: [
                        AnalyticsParameterTerm: fact.title
                    ])
                }
            } else {
                Analytics.logEvent("FactTappedInFeed", parameters: [
                    AnalyticsParameterTerm: fact.title
                ])
            }
            
            
            performSegue(withIdentifier: "toFactSegue", sender: fact)
        }
    }
    
    
    
}

extension BaseFeedTableViewController: MusicPostDelegate {
    func expandView() {
        tableView.beginUpdates()
        tableView.endUpdates()
        print("TableViewUpdate")
    }
}

class SortButton: DesignableButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .clear
        self.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 13)
        self.contentHorizontalAlignment = .left
        self.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0);
        
        if #available(iOS 13.0, *) {
            self.setTitleColor(.label, for: .normal)
        } else {
            self.setTitleColor(.black, for: .normal)
        }
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
