//
//  NewPostViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import FirebaseAnalytics
import EasyTipView
import BSImagePicker
import Photos
import CropViewController
import SwiftLinkPreview

enum PostSelection {
    case picture
    case link
    case thought
    case multiPicture
}

enum EventType {
    case activity
    case project
    case event
}

protocol JustPostedDelegate: class {
    func posted()
}

//TODO: Outsource the network POST requests, functions of outsources buttons
class NewPostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
    
    // MARK: - Elements
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var headerView: UIView!
    
    let segmentedControlView = BaseSegmentedControlView(items: [Strings.text, Strings.picture, Strings.link], tintColor: .imagineColor, font: .standard(with: .medium, size: 15))
    
    
    // MARK: - Variables
    
    //image variables
    var imagePicker = UIImagePickerController()
    let pictureViewHeightConstant = Constants.NewPostConstants.pictureViewHeightConstant
    let increasedPictureViewHeightConstraint = Constants.NewPostConstants.increasedPictureViewHeightConstraint
    var imageURLs = [String]()
    var multiImageAssets = [PHAsset]()
    var previewPictures = [UIImage]()
    
    ///Data used to upload, only available after you start to post the images
    var selectedImagesFromPicker = [Data]()
    var selectedImageFromPicker:UIImage?
    
    var selectedImageHeight: CGFloat = 0.0
    var selectedImageWidth: CGFloat = 0.0
    var imageURL:String?
    var thumbnailImageURL: String?
    var camPic = false
    
    var reportType :ReportType = .normal
    var eventType: EventType = .activity
    
    var selectDate = false
    var selectedDate: Date?
    
    let identifier = "MultiPictureCell"
    let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
    
    var postAnonymous = false
    var anonymousName: String?
    var anonymousString = "anonym"
    
    var fakeProfileUserID: String?
    
    let db = Firestore.firestore()
    
    var selectedOption: PostSelection = .thought
    
    let labelFont = UIFont(name: "IBMPlexSans-Medium", size: 15)
    
    let characterLimitForTitle = Constants.characterLimits.postTitleCharacterLimit
    let defaultOptionViewHeight: CGFloat = 45
    
    let infoButtonSize: CGFloat = 22
    
    var cropViewController: CropViewController?
    
    //Link Fact With Post
    var linkedFact: Community?
    var linkedLocation: Location?
    
    let labelHeight = Constants.NewPostConstants.labelHeight
    
    var comingFromPostsOfFact = false
    var comingFromAddOnVC = false   // This will create a difference reference for the post to be stored, to show it just in the topic and not in the main feed - later it will show up for those who follow this topic
    weak var addItemDelegate: AddItemDelegate?
    var postOnlyInTopic = false
    var addOn: AddOn?
    
    // Constraints for the different animations
    var pictureViewHeight: NSLayoutConstraint?
    var linkViewHeight: NSLayoutConstraint?
    var eventViewHeight: NSLayoutConstraint?
    var locationViewHeight: NSLayoutConstraint?
    var optionViewHeight: NSLayoutConstraint?
    var stackViewHeight: NSLayoutConstraint?
    var descriptionViewTopAnchor: NSLayoutConstraint?
    var pictureViewTopAnchor: NSLayoutConstraint?
    
    /// Link the delegate from the main feed to switch to its view again and reload if somebody posts something
    weak var delegate: JustPostedDelegate?
    weak var newInstanceDelegate: NewFactDelegate?
    
    //MemeMode
    var memeView: MemeInputView?
    
    ///How many times did the MemeInputView flicker
    var howManyFlickersIndex = 0
    ///How fast will the next flicker happen
    var flickerInterval = 0.3
    let generator = UIImpactFeedbackGenerator(style: .light)
    
    //InfoViews
    var infoView: UIView?
    
    let slp = SwiftLinkPreview(session: URLSession.shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, cache: InMemoryCache())
    
    var markPostTipView: EasyTipView?
    var postLinkTipView: EasyTipView?
    var linkedFactTipView: EasyTipView?
    var postAnonymousTipView: EasyTipView?
    var linkFactExplanationTipView: EasyTipView?
    
    //MARK: Outsourced Views
    
    let titleView = TitleView()
    let descriptionView = DescriptionView()
    lazy var linkView = LinkView(newPostVC: self)
    lazy var optionView = OptionView(newPostVC: self)
    lazy var pictureView = PictureView(newPostVC: self)
    lazy var locationView = LocationView(newPostVC: self)
    lazy var linkCommunityView = LinkCommunityView(newPostVC: self)
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupPreviewCollectionView()
        
        // Set Listener and delegates
        imagePicker.delegate = self
        titleView.titleTextView.delegate = self
        
        linkView.linkTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(letFirstRespondersResign))
        contentView.addGestureRecognizer(tap)
        
        //Set up view
        setUpScrollView()
        
        //Settings when this view is called from inside the community
        if comingFromPostsOfFact || comingFromAddOnVC {
            
            linkCommunityView.cancelLinkedFactButton.isEnabled = false
            linkCommunityView.cancelLinkedFactButton.alpha = 0.5
            linkCommunityView.distributionInformationLabel.text = "Community"
        }
        
        //Show Info view if not already shown before
        let infoAlreadyShown = UserDefaults.standard.bool(forKey: "newPostInfo")
        if !infoAlreadyShown {
            showNewPostInfoView()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let view = infoView {
            view.removeFromSuperview()
        }
        self.removeTipViews()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.infoView = nil
        
        let alreadyShown = UserDefaults.standard.bool(forKey: "newPostNameInfo")
        if !alreadyShown {
            showInfoView()
        }
    }
    
    //MARK: - Set Up View
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.clipsToBounds = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        
        return scrollView
    }()
    
    let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        
        return view
    }()
    
    func setUpScrollView() {
        self.view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        let contentGuide = scrollView.contentLayoutGuide
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentGuide.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentGuide.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            contentGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        
        //Load the different views into the contentView
        setUpViewUI()
    }
    
    func setUpViewUI() {
        
        //Style the view a bit
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        headerView.addSubview(segmentedControlView)
        segmentedControlView.delegate = self
        segmentedControlView.constrain(top: headerLabel.bottomAnchor, leading: headerView.leadingAnchor, bottom: headerView.bottomAnchor, trailing: headerLabel.trailingAnchor, paddingTop: 10, paddingBottom: -5, height: 30)
                
        //Load the UI
        setCompleteUIForThought()
        setPictureViewUI()
        setLinkViewUI()
        setUpOptionViewUI() // Shows linked Fact in here, if there is one
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "searchFactsSegue":
            if let navCon = segue.destination as? UINavigationController, let factVC = navCon.topViewController as? CommunityCollectionVC {
                factVC.addFactToPost = .newPost
                factVC.delegate = self
            }
        case "toMapSegue":
            if let mapVC = segue.destination as? MapViewController {
                mapVC.locationDelegate = self
            }
        default: break
        }
    }
    
    
    //MARK: - ShareTapped
    
    @IBAction func sharePostTapped(_ sender: Any) {
        
        if let user = Auth.auth().currentUser {
            var userID = ""
            
            let postRef: DocumentReference?
            var collectionRef: CollectionReference!
            let language = LanguageSelection().getLanguage()
            
            if comingFromAddOnVC || postOnlyInTopic {
                if language == .english {
                    collectionRef = self.db.collection("Data").document("en").collection("topicPosts")
                } else {
                    collectionRef = self.db.collection("TopicPosts")
                }
                postRef = collectionRef.document()
            } else {
                if language == .english {
                    collectionRef = self.db.collection("Data").document("en").collection("posts")
                } else {
                    collectionRef = self.db.collection("Posts")
                }
                postRef = collectionRef.document()
            }

            userID = user.uid
            
            if let id = fakeProfileUserID {
                userID = id
            }

            if titleView.titleTextView.text != "", let postRef = postRef {
                self.view.activityStartAnimating()
                self.shareButton.isEnabled = false
                
                switch selectedOption {
                case .thought:
                    self.postThought(postRef: postRef, userID: userID)
                case .multiPicture:
                    prepareMultiPicturePost(postRef: postRef, userID: userID)
                case .picture:
                    preparePicturePost(postRef: postRef, userID: userID)
                case .link:
                    prepareLinkPost(postRef: postRef, userID: userID)
                }
            } else {
                self.alert(message: NSLocalizedString("missing_info_alert_title", comment: "enter title pls"))
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    
    
    func showInfoView() {
        
        let height = UIScreen.main.bounds.height
        let view = UIView(frame: CGRect(x: 20, y: height-150, width: self.view.frame.width-40, height: 35))
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        view.alpha = 0
        view.layer.cornerRadius = 10

        self.infoView = view
        
        let label = UILabel(frame: CGRect(x: 5, y: 2, width: infoView!.frame.width-10, height: infoView!.frame.height-5))
        label.text = NSLocalizedString("just_name_info_message", comment: "surname is not visible")
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.font = UIFont(name: "IBMPlexSans", size: 15)
        label.alpha = 0
        label.adjustsFontSizeToFitWidth = true
        label.textColor = .label
        
        infoView!.addSubview(label)
        
        if let window = UIApplication.keyWindow() {
            window.addSubview(infoView!)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UIView.animate(withDuration: 0.7, animations: {
                self.infoView!.alpha = 1
                label.alpha = 1
            }) { (_) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    UIView.animate(withDuration: 0.7, animations: {
                        self.infoView!.alpha = 0
                        label.alpha = 0
                    }) { (_) in
                        self.infoView!.removeFromSuperview()
                        UserDefaults.standard.set(true, forKey: "newPostNameInfo")
                    }
                }
            }
        }
    }

    @objc func donePosting() {
        if comingFromPostsOfFact {
            self.dismiss(animated: true) {
                self.newInstanceDelegate?.finishedCreatingNewInstance(item: nil)
            }
        } else {
            delegate?.posted()
            tabBarController?.selectedIndex = 0
        }
    }
    
    func showShareAlert() {
        let shareAlert = UIAlertController(title: NSLocalizedString("link_fact_destination_alert_header", comment: "Where?"), message: NSLocalizedString("link_fact_destination_alert_message", comment: "with everybody or just community?"), preferredStyle: .actionSheet)
        
        shareAlert.addAction(UIAlertAction(title: NSLocalizedString("link_fact_destination_everybody", comment: "everybody"), style: .default, handler: { (_) in
            
        }))
        shareAlert.addAction(UIAlertAction(title: NSLocalizedString("link_fact_destination_community", comment: "community"), style: .default, handler: { (_) in
            
            self.linkCommunityView.distributionInformationLabel.text = "Community"
            self.linkCommunityView.distributionInformationImageView.image = UIImage(named: "topicIcon")
            self.postOnlyInTopic = true
            
        }))
        
        self.present(shareAlert, animated: true, completion: nil)
    }
    
    // MARK: - Touches began
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        letFirstRespondersResign()
    }
    
    @objc func letFirstRespondersResign() {
        titleView.titleTextView.resignFirstResponder()
        linkView.linkTextField.resignFirstResponder()
        descriptionView.descriptionTextView.resignFirstResponder()
        
        self.removeTipViews()
    }
    
    
    //MARK: - Info Views
    
    func showNewPostInfoView() {
        let height = topbarHeight + 40
        
        let frame = CGRect(x: 20, y: 20, width: self.view.frame.width-40, height: self.view.frame.height-height)
        let popUpView = PopUpInfoView(frame: frame)
        popUpView.alpha = 0
        popUpView.type = .newPost
        
        if let window = UIApplication.keyWindow() {
            window.addSubview(popUpView)
        }
        
        UIView.animate(withDuration: 0.5) {
            popUpView.alpha = 1
        }
    }
    
    func explainFunctionOnFirstOpen() {
        let defaults = UserDefaults.standard
        
        if let _ = defaults.string(forKey: "showExplanationForLinkFact") {
            
        } else {
            showExplanationForLinkFactToPost()
            defaults.set(true, forKey: "showExplanationForLinkFact")
            print("NEW Post launched first time")
        }
    }
    
    func showExplanationForLinkFactToPost() {
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.linkFactExplanationTipView = EasyTipView(text: NSLocalizedString("link_fact_first_open_tip_view_text", comment: "how it works and such"))
            self.linkFactExplanationTipView!.show(forView: self.linkCommunityView)
        }
    }
    
    func removeTipViews() {
        if let tipView = self.postAnonymousTipView {
            tipView.dismiss()
            postAnonymousTipView = nil
        }
        if let tipView = self.linkedFactTipView {
            tipView.dismiss()
            linkedFactTipView = nil
        }
        if let tipView = self.markPostTipView {
            tipView.dismiss()
            markPostTipView = nil
        }
        
        if let tipView = self.postLinkTipView {
            tipView.dismiss()
            postLinkTipView = nil
        }
        
        if let tipView = self.linkFactExplanationTipView {
            tipView.dismiss()
            linkFactExplanationTipView = nil
        }
    }
    
    //MARK: - MemeMode Maker
    
    func memeModeTapped() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        optionView.memeModeButton.isEnabled = false
        showMemeMode()
    }
    
    
    func showMemeMode() {
        if let window = UIApplication.keyWindow() {
            let memeView: MemeInputView = MemeInputView.fromNib()
            memeView.delegate = self
            
            window.addSubview(memeView)
            self.memeView = memeView
            
            window.layoutSubviews()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.letItRezzle()
            }
        }
    }
    
    
    func letItRezzle() {    /// A little distorted effect for the meme view
        if let memeView = memeView {
            memeView.alpha = 0.98
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                
                if self.howManyFlickersIndex <= 3 {
                    
                    memeView.alpha = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.flickerInterval) {
                        self.letItRezzle()
                        self.generator.impactOccurred()
                    }
                    
                    self.flickerInterval-=0.1
                    self.howManyFlickersIndex+=1
                } else {
                    let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
                    heavyImpact.impactOccurred()
                    
                    memeView.startUpMemeMode()
                    self.optionView.memeModeButton.isEnabled = true
                    
                    if self.selectedOption != .picture || self.selectedOption != .multiPicture {
                        //Switch to picture mode so the meme can be shown
                        self.segmentedControlView.segmentedControl.selectedSegmentIndex = 1
                        self.prepareForSelectionChange()
                    }
                }
            }
        }
    }
    
    //MARK: - Picture Post Actions
    
    func camTapped() {
        if let _ = Auth.auth().currentUser {
            
            let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            switch status {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted) in
                    if granted {
                        self.showCamera()
                    } else {
                        self.showCamDeniedAlert()
                    }
                }
                
            case .authorized:
                self.showCamera()
                
            case .denied:
                self.showCamDeniedAlert()
                
            case .restricted:
                self.showCamRestrictedAlert()
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func showCamRestrictedAlert() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Restricted",
                                          message: "You've been restricted from using the camera on this device. Without camera access this feature won't work. Please contact the device owner so they can give you access.",
                                          preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showCamDeniedAlert() {
        DispatchQueue.main.async {
                var alertText = NSLocalizedString("newPost_camera_error_text", comment: "cant acces, what to do")

                var alertButton = "OK"
                var goAction = UIAlertAction(title: alertButton, style: .default, handler: nil)

                if UIApplication.shared.canOpenURL(URL(string: UIApplication.openSettingsURLString)!) {
                    alertText = NSLocalizedString("newPost_camera_error_text", comment: "CANT ACCESS    what to do")

                    alertButton = "Go"

                    goAction = UIAlertAction(title: alertButton, style: .default, handler: {(alert: UIAlertAction!) -> Void in
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                    })
                }

                let alert = UIAlertController(title: "Error", message: alertText, preferredStyle: .alert)
                alert.addAction(goAction)
                self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showCamera() {
        DispatchQueue.main.async {
            
            self.imagePicker.sourceType = .camera
            self.imagePicker.cameraCaptureMode = .photo
            self.imagePicker.cameraDevice = .rear
            self.imagePicker.cameraFlashMode = .off
            self.imagePicker.showsCameraControls = true
            
            self.present(self.imagePicker, animated: true, completion: nil)
        }
    }
    
    func camRollTapped() {
        if let _ = Auth.auth().currentUser {
            
            switch PHPhotoLibrary.authorizationStatus() {
            case .notDetermined:
                
                //Not yet decided - ask the user for authorization
                PHPhotoLibrary.requestAuthorization { (status) in
                    switch status {
                    case .limited:
                        self.showPictureAlert()
                    case .authorized:
                        self.showPictureAlert()
                    default:
                        self.showPermissionDeniedAlert()
                    }
                }
            case .restricted, .denied:
                self.showPermissionDeniedAlert()
            case .authorized:
                showPictureAlert()
            case .limited:
                showPictureAlert()
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func showPermissionDeniedAlert() {
        DispatchQueue.main.async {
            self.alert(message: NSLocalizedString("photoAccess_permission_denied_text", comment: "how you can change that"), title: "Something seems to be wrong")
        }
    }
    
    func showPictureAlert() {
        
        DispatchQueue.main.async {
            
            if let _ = self.memeView {  //Select image for meme, no multi picture possible
                self.showImagePicker()
            } else {
                let alert = UIAlertController(title: NSLocalizedString("how_many_pics_alert_header", comment: "How many pics do you want to post?"), message: NSLocalizedString("how_many_pics_alert_message", comment: "How many pics do you want to post?"), preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: NSLocalizedString("how_many_just_one", comment: "just one"), style: .default, handler: { (_) in
                    self.showImagePicker()
                }))
                
                
                alert.addAction(UIAlertAction(title: NSLocalizedString("how_many_three", comment: "two or three pics"), style: .default, handler: { (_) in
                    
                    //toDo: remove the selection
                    self.selectedOption = .multiPicture
                    self.openMultiPictureImagePicker()
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "cancel"), style: .destructive, handler: { (_) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func showImagePicker() {
        self.imagePicker.sourceType = .photoLibrary
        self.imagePicker.mediaTypes = ["public.image"]
//        self.imagePicker.mediaTypes = ["public.movie", "public.image"]
        //imagePicker.allowsEditing = true
        
        self.selectedOption = .picture
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
    func removePictureTapped() {
        
        self.multiImageAssets.removeAll()
        self.previewPictures.removeAll()
        self.pictureView.previewCollectionView.reloadData()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.pictureView.removePictureButton.alpha = 0
            self.pictureView.removePictureButton.isEnabled = true
        }) { (_) in
            self.decreasePictureUI()
            self.selectedImageFromPicker = nil
            self.selectedImagesFromPicker = []
            self.selectedImageHeight = 0
            self.selectedImageWidth = 0
        }
    }
    
    
    //MARK: - Option Actions
    
    func optionButtonTapped() {
                
        if descriptionView.descriptionTextView.isFirstResponder {
            descriptionView.descriptionTextView.resignFirstResponder()
        } else if titleView.titleTextView.isFirstResponder {
            titleView.titleTextView.resignFirstResponder()
        }
        
        if let height = optionViewHeight {
            if height.constant <= defaultOptionViewHeight {
                height.constant = 125   
                stackViewHeight!.isActive = false
                
                
                UIView.animate(withDuration: 0.4, animations: {
                    self.view.layoutIfNeeded()
                }) { (_) in
                    self.optionView.optionStackView.isHidden = false
                    UIView.animate(withDuration: 0.1) {
                        self.optionView.optionStackView.alpha = 1
                    }
                }
            } else {
                stackViewHeight = optionView.optionStackView.heightAnchor.constraint(equalToConstant: 0)
                stackViewHeight!.isActive = true
                
                height.constant = defaultOptionViewHeight
                
                UIView.animate(withDuration: 0.4, animations: {
                    self.optionView.optionStackView.alpha = 0
                    self.view.layoutIfNeeded()
                }) { (_) in
                    self.optionView.optionStackView.isHidden = true
                }
            }
        }
    }
    
    func linkFactToPostTapped() {
        performSegue(withIdentifier: "searchFactsSegue", sender: nil)
    }
    
    func cancelLinkedFactTapped() {
        linkCommunityView.hideLinkedCommunity()
        
        self.linkedFact = nil
        self.postOnlyInTopic = false
    }
    
    func linkedFactInfoButtonTapped() {
        if let tipView = self.linkedFactTipView {
            tipView.dismiss()
            linkedFactTipView = nil
        } else {
            self.linkedFactTipView = EasyTipView(text: NSLocalizedString("linked_fact_tip_view_text", comment: "how and why"))
            linkedFactTipView!.show(forView: linkCommunityView)
        }
    }
    
    func postAnonymousButtonPressed() {
        if let tipView = self.postAnonymousTipView {
            tipView.dismiss()
            postAnonymousTipView = nil
        } else {
            self.postAnonymousTipView = EasyTipView(text: Constants.texts.postAnonymousText)
            postAnonymousTipView!.show(forView: optionView)
        }
    }
    
    
    // MARK: - UI Initialization
    
    func setCompleteUIForThought() {
        
        if let topAnchor = self.descriptionViewTopAnchor {
            topAnchor.isActive = false
        }
        
        setTitleViewUI()
        setDescriptionViewUI()
        
        descriptionViewTopAnchor = descriptionView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 1)
        descriptionViewTopAnchor!.isActive = true
        
        segmentedControlView.segmentedControl.isEnabled = true
    }
    
    
    //MARK: TitleView UI
    
    
    func setTitleViewUI() {
        
        self.contentView.addSubview(titleView)
        titleView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        titleView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        titleView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        titleView.heightAnchor.constraint(equalToConstant: 100).isActive = true
                
    }
    
    
    
    // MARK: DescriptionView UI
    
    func setDescriptionViewUI() {   // have to set descriptionview topanchor
        
        self.contentView.addSubview(descriptionView)
        descriptionView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        descriptionView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        descriptionView.heightAnchor.constraint(equalToConstant: 110).isActive = true
    }
    
    
    
    // MARK: LinkViewUI
    
    func setLinkViewUI() {   // have to set descriptionview topanchor
        
        self.contentView.addSubview(linkView)
        linkView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 1).isActive = true
        linkView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        linkView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        self.linkViewHeight = linkView.heightAnchor.constraint(equalToConstant: 0)
        self.linkViewHeight!.isActive = true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text {
            
            linkView.internetImageView.alpha = 0.4
            linkView.youTubeImageView.alpha = 0.4
            linkView.songWhipImageView.alpha = 0.4
            linkView.GIFImageView.alpha = 0.4
            
            if text.isValidURL {
                if let _ = text.youtubeID {
                    linkView.youTubeImageView.alpha = 1
                } else if text.contains("songwhip.com") || text.contains("music.apple.com") || text.contains("open.spotify.com/") || text.contains("deezer.page.link") {
                    linkView.songWhipImageView.alpha = 1
                } else if text.contains(".mp4") {
                    linkView.GIFImageView.alpha = 1
                    print("Got mp4")
                } else {
                    linkView.internetImageView.alpha = 1
                }
            }
        }
    }
    
    func linkInfoButtonTapped() {
        if let tipView = self.postLinkTipView {
            tipView.dismiss()
            postLinkTipView = nil
        } else {
            self.postLinkTipView = EasyTipView(text: NSLocalizedString("postLinkTipViewText", comment: "What you can post and such"))
            postLinkTipView!.show(forView: linkView)
        }
    }
    
    // MARK: PictureViewUI
    
    @objc func showChoosenImage(tapGestureRecognizer: UITapGestureRecognizer) {
        print("To choosen Image")
        if let imageView = tapGestureRecognizer.view as? UIImageView {
            if let image = imageView.image {
                let pinchVC = PinchToZoomViewController()
            
                pinchVC.imageView.image = image
                self.navigationController?.pushViewController(pinchVC, animated: true)
            }
        }
    }
    
    func setPictureViewUI() {
        
        self.contentView.addSubview(pictureView)
        pictureView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        pictureView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        self.pictureViewHeight = pictureView.heightAnchor.constraint(equalToConstant: 0)
        self.pictureViewHeight!.isActive = true
        self.pictureViewTopAnchor = pictureView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 1)
        self.pictureViewTopAnchor!.isActive = true
    }
    
    //MARK: Change Picture UI
    func increasePictureUI() {
        if let pictureHeight = self.pictureViewHeight {
            pictureHeight.constant = increasedPictureViewHeightConstraint
            
            UIView.animate(withDuration: 0.6) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func decreasePictureUI() {
        if let pictureHeight = self.pictureViewHeight {
            pictureHeight.constant = pictureViewHeightConstant
            
            UIView.animate(withDuration: 0.6) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: OptionViewUI

    func chooseLocationButtonTapped() {
        performSegue(withIdentifier: "toMapSegue", sender: nil)
    }
    
    func setUpOptionViewUI() {
        let smallOptionViewHeight = defaultOptionViewHeight-4
        
        self.contentView.addSubview(locationView)
        locationView.topAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: 1).isActive = true
        locationView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        locationView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        locationView.heightAnchor.constraint(equalToConstant: smallOptionViewHeight+labelHeight).isActive = true
        
        self.contentView.addSubview(linkCommunityView)
        linkCommunityView.topAnchor.constraint(equalTo: locationView.bottomAnchor, constant: 1).isActive = true
        linkCommunityView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        linkCommunityView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        linkCommunityView.heightAnchor.constraint(equalToConstant: smallOptionViewHeight+labelHeight).isActive = true
        
        self.contentView.addSubview(optionView)
        optionView.topAnchor.constraint(equalTo: linkCommunityView.bottomAnchor, constant: 1).isActive = true
        optionView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        optionView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        optionViewHeight = optionView.heightAnchor.constraint(equalToConstant: defaultOptionViewHeight)
        optionViewHeight!.isActive = true
        
        
        // Here so it doesnt mess with the layout
        if let fact = linkedFact {
            self.showLinkedFact(community: fact)
        }
        
        let endView = UIView()
        endView.backgroundColor = .systemBackground
        endView.translatesAutoresizingMaskIntoConstraints = false

        self.contentView.addSubview(endView)
        endView.topAnchor.constraint(equalTo: optionView.bottomAnchor, constant: 1).isActive = true
        endView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        endView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        endView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        endView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
    }
    

    
    //MARK: - Animate UI Changes
    
    func insertUIForLink() {
        self.descriptionViewTopAnchor!.isActive = false
        
        
        self.descriptionViewTopAnchor! = descriptionView.topAnchor.constraint(equalTo: linkView.bottomAnchor, constant: 1)
        self.descriptionViewTopAnchor!.isActive = true
        
        self.linkViewHeight!.constant = 75
        
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
        }) { (_) in
        
            UIView.animate(withDuration: 0.1, animations: {
                self.linkView.linkLabel.alpha = 1
                self.linkView.linkTextField.alpha = 1
                self.linkView.webImageViewStackView.alpha = 1
                self.linkView.linkInfoButton.alpha = 1
            }, completion: { (_) in
                self.segmentedControlView.segmentedControl.isEnabled = true
            })
        }
    }
    
    
    func insertUIForPicture() {
        self.descriptionViewTopAnchor!.isActive = false
        
        
        if let pictureTop = pictureViewTopAnchor {
            pictureTop.isActive = false
            
        }
        
        self.pictureViewTopAnchor = pictureView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 1)
        self.pictureViewTopAnchor!.isActive = true
        
        var imageIsPresented = false
        
        if self.selectedImageFromPicker != nil || self.multiImageAssets.count != 0 {
            imageIsPresented = true
            print("* Image is presented")
        }
        
        if imageIsPresented {
            self.pictureViewHeight!.constant = increasedPictureViewHeightConstraint
        } else {
            self.pictureViewHeight!.constant = pictureViewHeightConstant
        }
        
        self.descriptionViewTopAnchor! = descriptionView.topAnchor.constraint(equalTo: pictureView.bottomAnchor, constant: 1)
        self.descriptionViewTopAnchor!.isActive = true
        
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
        }) { (_) in
            
            UIView.animate(withDuration: 0.1, animations: {
                self.pictureView.cameraButton.alpha = 1
                self.pictureView.folderButton.alpha = 1
                self.pictureView.pictureLabel.alpha = 1
                self.pictureView.previewCollectionView.alpha = 1
                if imageIsPresented {
                    self.pictureView.removePictureButton.alpha = 1
                }
            }, completion: { (_) in
                self.segmentedControlView.segmentedControl.isEnabled = true
            })
        }
    }
    
    //MARK: - Animate Layout Change
    
    func prepareForSelectionChange() {
        segmentedControlView.segmentedControl.isEnabled = false
        
        switch self.selectedOption {
        case .picture, .multiPicture:
            
            //Let the pictureView disappear
            UIView.animate(withDuration: 0.1, animations: {
                self.pictureView.folderButton.alpha = 0
                self.pictureView.cameraButton.alpha = 0
                self.pictureView.pictureLabel.alpha = 0
                self.pictureView.removePictureButton.alpha = 0
                self.pictureView.previewCollectionView.alpha = 0
            }) { (_) in
                
                self.pictureViewHeight!.constant = 0
                
                UIView.animate(withDuration: 0.4, animations: {
                    self.view.layoutIfNeeded()
                }) { (_) in
                    self.setTheChange()
                }
            }
        case .link:
            
            // Let the LinkView disappear
            UIView.animate(withDuration: 0.1, animations: {
                self.linkView.linkLabel.alpha = 0
                self.linkView.linkTextField.alpha = 0
                self.linkView.webImageViewStackView.alpha = 0
                self.linkView.linkInfoButton.alpha = 0
            }) { (_) in
                self.linkViewHeight!.constant = 0
                
                UIView.animate(withDuration: 0.4, animations: {
                    self.view.layoutIfNeeded()
                }) { (_) in
                    self.setTheChange()
                }
            }
        default:
            self.setTheChange()
        }
    }
    
    func setTheChange() {
        if segmentedControlView.segmentedControl.selectedSegmentIndex == 0 {
            self.selectedOption = .thought
            setCompleteUIForThought()
        }
        if segmentedControlView.segmentedControl.selectedSegmentIndex == 1 {
            self.selectedOption = .picture
            insertUIForPicture()
        }
        if segmentedControlView.segmentedControl.selectedSegmentIndex == 2 {
            self.selectedOption = .link
            insertUIForLink()
        }
    }
}

//MARK: - TextViewDelegate

extension NewPostViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if textView == titleView.titleTextView {  // No lineBreaks in titleTextView
            guard text.rangeOfCharacter(from: CharacterSet.newlines) == nil else {
                return descriptionView.descriptionTextView.becomeFirstResponder()   // Switch to description when "continue" is hit on keyboard
            }
        }
        
        return textView.text.count + (text.count - range.length) <= characterLimitForTitle
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        let characterLeft = characterLimitForTitle-textView.text.count
        self.titleView.characterCountLabel.text = String(characterLeft)
    }
}

//MARK: - AddOnDelegate
extension NewPostViewController: AddOnDelegate {
    func fetchCompleted() {
        print("Not needed")
    }
    
    func itemAdded(successfull: Bool) {
        // remove ActivityIndicator incl. backgroundView
        self.view.activityStopAnimating()
        self.shareButton.isEnabled = true
        
        if successfull {
            self.addItemDelegate?.itemAdded()
            self.dismiss(animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Something went wrong", message: "Please try later again or ask the developers to do a better job. We are sorry!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                
                alert.dismiss(animated: true, completion: nil)
            }))
            
            self.present(alert, animated: true)
        }
        
    }
}

//MARK: - Location Delegate

extension NewPostViewController: ChoosenLocationDelegate {
    func gotLocation(location: Location) {
        self.linkedLocation = location
        self.locationView.choosenLocationLabel.text = location.title
    }
}


//MARK: - Link Community With Post Delegate

extension NewPostViewController: LinkFactWithPostDelegate {
    
    func selectedFact(fact: Community, isViewAlreadyLoaded: Bool) {    // Link Fact with post - When posting, from postsOfFactTableVC and from OptionalInformationTableVC
        
        self.linkedFact = fact
        
        if isViewAlreadyLoaded {  // Means it is coming from the selection of a topic to link with, so the view is already loaded, so it doesnt crash
            showLinkedFact(community: fact)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { //I know, I know
                self.showShareAlert()
            }
        }
    }
    
    func showLinkedFact(community: Community) {
        
        linkCommunityView.showLinkedCommunity(community: community)
    }
    
    func setDismissButton() {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        button.setImage(UIImage(named: "Dismiss"), for: .normal)
        button.heightAnchor.constraint(equalToConstant: 23).isActive = true
        button.widthAnchor.constraint(equalToConstant: 23).isActive = true
        
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    @objc func dismissTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK: - MemeViewDelegate
extension NewPostViewController: MemeViewDelegate {
    
    func showAlert(alert: MemeViewAlert) {
        
        switch alert {
        case .error:
            self.alert(message: "Something went wrong, we're sorry! I don't know what it could be, to ask that you should try again is a bit annoying I know. Maybe flame the developers a bit, so they know where they should put more work in!", title: "Error")
        case .needMoreInfo:
            self.alert(message: "Please enter some text and add a picture.", title: "Not enough input")
        case .successfullyStored:
            self.alert(message: "Your meme has been saved!", title: "All done!")
        }
    }
    
    func selectImageForMemeTouched() {
        self.camRollTapped()
    }
    
    func memeViewDismissed(meme: UIImage?) {
        if let meme = meme {
            setImageAndShowPreviewImage(image: meme)
            
            let alert = UIAlertController(title: "Save your meme?", message: "Do you want to save your meme to your phone?", preferredStyle: .actionSheet)
            let yesAlert = UIAlertAction(title: "Yes", style: .default) { (_) in
                UIImageWriteToSavedPhotosAlbum(meme, nil, nil, nil)
            }
            let cancelAlert = UIAlertAction(title: "No thanks", style: .cancel) { (_) in
                alert.dismiss(animated: true, completion: nil)
            }
            alert.addAction(yesAlert)
            alert.addAction(cancelAlert)
            self.present(alert, animated: true, completion: nil)
        }
        
        self.memeView = nil
    }
}

// MARK: - BaseSegmentControl Delegate

extension NewPostViewController: BaseSegmentControlDelegate {
    func segmentChanged(to index: Int, direction: UIPageViewController.NavigationDirection) {
        prepareForSelectionChange()
    }
}
