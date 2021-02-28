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

protocol JustPostedDelegate {
    func posted()
}

class NewPostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, CropViewControllerDelegate {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var postSelectionSegmentedControl: UISegmentedControl!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var headerView: UIView!
    
    var imagePicker = UIImagePickerController()
    
    var imageURLs = [String]()
    var multiImageAssets = [PHAsset]()
    var previewPictures = [UIImage]()
    var selectedImagesFromPicker = [Data]()
    var selectedImageFromPicker:UIImage?
    var selectedImageHeight: CGFloat = 0.0
    var selectedImageWidth: CGFloat = 0.0
    var imageURL:String?
    var reportType :ReportType = .normal
    var eventType: EventType = .activity
    var camPic = false
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
    let characterLimitForEventTitle = 100
    let defaultOptionViewHeight: CGFloat = 45
    
    let infoButtonSize: CGFloat = 22
    
    var cropViewController: CropViewController?
    
    /// Is the keyboard up for better typing
    var up = false
    
    //Link Fact With Post
    var linkedFact: Community?
    var linkedLocation: Location?
    
    var comingFromPostsOfFact = false
    var comingFromAddOnVC = false   // This will create a difference reference for the post to be stored, to show it just in the topic and not in the main feed - later it will show up for those who follow this topic
    var addItemDelegate: AddItemDelegate?
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
    var delegate: JustPostedDelegate?
    var newInstanceDelegate: NewFactDelegate?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //CollectionViewSettings for the previewImages
        pictureView.previewCollectionView.register(UINib(nibName: "MultiPictureCollectionCell", bundle: nil), forCellWithReuseIdentifier: identifier)
        
        pictureView.previewCollectionView.dataSource = self
        pictureView.previewCollectionView.delegate = self
        
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        pictureView.previewCollectionView.setCollectionViewLayout(layout, animated: true)
        
        
        // Set Listener and delegates
        imagePicker.delegate = self
        titleView.titleTextView.delegate = self
        linkView.linkTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        
        
        
        //Load the UI
        setCompleteUIForThought()
        setPictureViewUI()
        setLinkViewUI()
        setUpOptionViewUI() // Shows linked Fact in here, if there is one
        
        
        //Settings when this view is called from inside the community
        if comingFromPostsOfFact || comingFromAddOnVC {
            if #available(iOS 13.0, *) {
                //no need for a dismiss button
            } else {
                setDismissButton()
            }
            
            cancelLinkedFactButton.isEnabled = false
            cancelLinkedFactButton.alpha = 0.5
            distributionInformationLabel.text = "Community"
        }
        
        //UI Changes
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        let font: [AnyHashable : Any] = [NSAttributedString.Key.font : UIFont(name: "IBMPlexSans", size: 15) as Any]
        markPostSegmentControl.setTitleTextAttributes(font as? [NSAttributedString.Key : Any], for: .normal)
        markPostSegmentControl.tintColor = .imagineColor
        postSelectionSegmentedControl.tintColor = .imagineColor
        postSelectionSegmentedControl.setTitleTextAttributes(font as? [NSAttributedString.Key : Any], for: .normal)
        
        //KeyboardGoesUp
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
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
    
    func showNewPostInfoView() {
        let upperHeight = UIApplication.shared.statusBarFrame.height +
              self.navigationController!.navigationBar.frame.height
        let height = upperHeight+40
        
        let frame = CGRect(x: 20, y: 20, width: self.view.frame.width-40, height: self.view.frame.height-height)
        let popUpView = PopUpInfoView(frame: frame)
        popUpView.alpha = 0
        popUpView.type = .newPost
        
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(popUpView)
        }
        
        UIView.animate(withDuration: 0.5) {
            popUpView.alpha = 1
        }
    }
    
    // MARK: - Functions for the UI Initializing
    
    func setCompleteUIForThought() {
        
        if let topAnchor = self.descriptionViewTopAnchor {
            topAnchor.isActive = false
        }
        
        setTitleViewUI()
        setDescriptionViewUI()
        
        self.descriptionViewTopAnchor = descriptionView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 1)
        self.descriptionViewTopAnchor!.isActive = true
        
        self.postSelectionSegmentedControl.isEnabled = true
    }
    
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
                self.linkInfoButton.alpha = 1
            }, completion: { (_) in
                self.postSelectionSegmentedControl.isEnabled = true
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
        
        self.pictureViewHeight!.constant = 100
        
        
        self.descriptionViewTopAnchor! = descriptionView.topAnchor.constraint(equalTo: pictureView.bottomAnchor, constant: 1)
        self.descriptionViewTopAnchor!.isActive = true
        
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
        }) { (_) in
            
            UIView.animate(withDuration: 0.1, animations: {
                self.pictureView.cameraButton.alpha = 1
                self.pictureView.folderButton.alpha = 1
                self.pictureView.pictureLabel.alpha = 1
            }, completion: { (_) in
                self.postSelectionSegmentedControl.isEnabled = true
            })
        }
    }
    
    
    
    let titleView = TitleView()
    
    func setTitleViewUI() {
        
        self.view.addSubview(titleView)
        titleView.topAnchor.constraint(equalTo: postSelectionSegmentedControl.bottomAnchor, constant: 5).isActive = true
        titleView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        titleView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        titleView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
    }
    
    
    
    // MARK: - DescriptionViewUI
    let descriptionView = DescriptionView()
    
    func setDescriptionViewUI() {   // have to set descriptionview topanchor
        
        self.view.addSubview(descriptionView)
        descriptionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        descriptionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        descriptionView.heightAnchor.constraint(equalToConstant: 110).isActive = true
    }
    
    
    
    // MARK: - LinkViewUI
    
    let linkView = LinkView()
    
    let linkInfoButton: DesignableButton = {
        let button = DesignableButton(type: .detailDisclosure)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(linkInfoButtonTapped), for: .touchUpInside)
        button.alpha = 0
        
        return button
    }()
    
    func setLinkViewUI() {   // have to set descriptionview topanchor
        
        
        linkView.addSubview(linkInfoButton)
        
        linkInfoButton.centerYAnchor.constraint(equalTo: linkView.linkTextField.centerYAnchor).isActive = true
        linkInfoButton.trailingAnchor.constraint(equalTo: linkView.trailingAnchor, constant: -10).isActive = true
        linkInfoButton.heightAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        linkInfoButton.widthAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        
        
        self.view.addSubview(linkView)
        linkView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 1).isActive = true
        linkView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        linkView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
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
    
    @objc func linkInfoButtonTapped() {
        if let tipView = self.postLinkTipView {
            tipView.dismiss()
            postLinkTipView = nil
        } else {
            self.postLinkTipView = EasyTipView(text: NSLocalizedString("postLinkTipViewText", comment: "What you can post and such"))
            postLinkTipView!.show(forView: linkView)
        }
    }
    
    // MARK: - PictureViewUI
    
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
    
    lazy var pictureView = PictureView(newPostVC: self)
    
    func setPictureViewUI() {
        
        self.view.addSubview(pictureView)
        pictureView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        pictureView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.pictureViewHeight = pictureView.heightAnchor.constraint(equalToConstant: 0)
        self.pictureViewHeight!.isActive = true
        self.pictureViewTopAnchor = pictureView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 1)
        self.pictureViewTopAnchor!.isActive = true
    }
    
    
    
    // MARK: - OptionViewUI
    let optionView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        return view
    }()
    
    let optionButton: DesignableButton = {  // little Burger Menu
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            button.setTitleColor(.label, for: .normal)
            
        } else {
            button.setTitleColor(.black, for: .normal)
        }
        button.tintColor = .imagineColor
        button.setImage(UIImage(named: "menu"), for: .normal)
        button.addTarget(self, action: #selector(optionButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
    let optionStackView: UIStackView = {
       let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alpha = 0
        stack.isHidden = true
        stack.distribution = .fillEqually
        
        return stack
    }()
    
    let anonymousImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "mask")
        imageView.contentMode = .scaleAspectFit
        if #available(iOS 13.0, *) {
            imageView.tintColor = .label
        } else {
            imageView.tintColor = .black
        }
        imageView.isHidden = true
        
        return imageView
    }()
    
    let anonymousNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 13)
        label.minimumScaleFactor = 0.5
//        if #available(iOS 13.0, *) {
//            label.tintColor = .label
//        } else {
//            label.tintColor = .black
//        }
        
        return label
    }()
    
    //MARK: - Meme Mode Button UI
    
    let memeModeButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let tronColor = UIColor(red: 0.05, green: 0.97, blue: 0.97, alpha: 1.00)
        
        var color: UIColor!
        if #available(iOS 13.0, *) {
            color = .label
        } else {
            color = .black
        }
        
        let text = NSMutableAttributedString()
        text.append(NSAttributedString(string: "M", attributes: [NSAttributedString.Key.foregroundColor: color]))
        text.append(NSAttributedString(string: "M", attributes: [NSAttributedString.Key.foregroundColor: tronColor]))
        
        button.setTitleColor(tronColor, for: .normal)
        button.setAttributedTitle(text, for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(memeModeTapped), for: .touchUpInside)
        
        return button
    }()
        
    
    //MARK: - Link Fact with Post UI
    
    let addFactButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.setTitle(NSLocalizedString("distribution_button_text", comment: "link community"), for: .normal)
        button.addTarget(self, action: #selector(linkFactToPostTapped), for: .touchUpInside)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        button.setTitleColor(.imagineColor, for: .normal)
        
        return button
    }()
    
    let addedFactImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.borderWidth = 0.5
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }()
    
    let addedFactDescriptionLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        label.textAlignment = .right
        
        return label
    }()
    
    let distributionLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        label.textAlignment = .left
        label.text = NSLocalizedString("distribution_label_text", comment: "destination:")
        if #available(iOS 13.0, *) {
            label.textColor = .label
        } else {
            label.textColor = .black
        }
        
        return label
    }()
    
    let distributionInformationLabel: UILabel = {   // Shows where the post will be posted: In a topic only or in the main Feed
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        label.textAlignment = .left
        label.text = "Feed"
        if #available(iOS 13.0, *) {
            label.textColor = .secondaryLabel
        } else {
            label.textColor = .lightGray
        }
        
        return label
    }()
    
    let distributionInformationImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "Feed")    //topicIcon
        if #available(iOS 13.0, *) {
            imageView.tintColor = .secondaryLabel
        } else {
            imageView.tintColor = .lightGray
        }
        
        return imageView
    }()
    
    let distributionInformationView: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        return view
    }()
    
    let linkedFactView: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        return view
    }()
    
    let linkedFactInfoButton :DesignableButton = {
        let button = DesignableButton(type: .detailDisclosure)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(linkedFactInfoButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
    let cancelLinkedFactButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "Dismiss"), for: .normal)
        button.addTarget(self, action: #selector(cancelLinkedFactTapped), for: .touchUpInside)
        button.isHidden = true
        button.clipsToBounds = true

        return button
    }()
    
    //MARK:- LocationUI
    let locationDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("location_label_text", comment: "location:")
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        
        return label
    }()
    
    let choosenLocationLabel : UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        label.textAlignment = .center
        
        return label
    }()
    
    let chooseLocationButton: DesignableButton = {
       let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "mapIcon"), for: .normal)
        button.addTarget(self, action: #selector(chooseLocationButtonTapped), for: .touchUpInside)
        button.tintColor = .imagineColor
        
        return button
    }()
    
    let linkedLocationImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "locationCircle")
        if #available(iOS 13.0, *) {
            imageView.tintColor = .secondaryLabel
        } else {
            imageView.tintColor = .lightGray
        }
        
        return imageView
    }()
    
    let linkedLocationView: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        return view
    }()
    
    @objc func chooseLocationButtonTapped() {
        performSegue(withIdentifier: "toMapSegue", sender: nil)
    }
    
    //MARK:- Set Up Options UI
    func setUpOptionViewUI() {
        let labelHeight: CGFloat = 17
        let smallOptionViewHeight = defaultOptionViewHeight-4
        
        //LocationView
        linkedLocationView.addSubview(locationDescriptionLabel)
        locationDescriptionLabel.topAnchor.constraint(equalTo: linkedLocationView.topAnchor, constant: 5).isActive = true
        locationDescriptionLabel.leadingAnchor.constraint(equalTo: linkedLocationView.leadingAnchor, constant: 10).isActive = true
        locationDescriptionLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true
        
        linkedLocationView.addSubview(linkedLocationImageView)
        linkedLocationImageView.centerYAnchor.constraint(equalTo: linkedLocationView.centerYAnchor, constant: (labelHeight/2)+2).isActive = true
        linkedLocationImageView.leadingAnchor.constraint(equalTo: linkedLocationView.leadingAnchor, constant: 14).isActive = true
        linkedLocationImageView.widthAnchor.constraint(equalToConstant: 17).isActive = true
        linkedLocationImageView.heightAnchor.constraint(equalToConstant: 17).isActive = true
        
        linkedLocationView.addSubview(choosenLocationLabel)
        choosenLocationLabel.centerYAnchor.constraint(equalTo: linkedLocationImageView.centerYAnchor).isActive = true
        choosenLocationLabel.leadingAnchor.constraint(equalTo: locationDescriptionLabel.trailingAnchor, constant: 10).isActive = true
        
        linkedLocationView.addSubview(chooseLocationButton)
        chooseLocationButton.leadingAnchor.constraint(equalTo: choosenLocationLabel.trailingAnchor, constant: 20).isActive = true
        chooseLocationButton.trailingAnchor.constraint(equalTo: linkedLocationView.trailingAnchor, constant: -10).isActive = true
        chooseLocationButton.centerYAnchor.constraint(equalTo: choosenLocationLabel.centerYAnchor).isActive = true
        chooseLocationButton.heightAnchor.constraint(equalToConstant: infoButtonSize-1).isActive = true
        chooseLocationButton.widthAnchor.constraint(equalToConstant: infoButtonSize-1).isActive = true
        
        self.view.addSubview(linkedLocationView)
        linkedLocationView.topAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: 1).isActive = true
        linkedLocationView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        linkedLocationView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        linkedLocationView.heightAnchor.constraint(equalToConstant: smallOptionViewHeight+labelHeight).isActive = true
        
        //LinkedFactView
        linkedFactView.addSubview(distributionLabel)
        distributionLabel.topAnchor.constraint(equalTo: linkedFactView.topAnchor, constant: 5).isActive = true
        distributionLabel.leadingAnchor.constraint(equalTo: linkedFactView.leadingAnchor, constant: 10).isActive = true
        distributionLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true

        linkedFactView.addSubview(linkedFactInfoButton)
        linkedFactInfoButton.centerYAnchor.constraint(equalTo: linkedFactView.centerYAnchor, constant: labelHeight/2).isActive = true
        linkedFactInfoButton.trailingAnchor.constraint(equalTo: linkedFactView.trailingAnchor, constant: -10).isActive = true
        linkedFactInfoButton.widthAnchor.constraint(equalToConstant: infoButtonSize-1).isActive = true
        linkedFactInfoButton.heightAnchor.constraint(equalToConstant: infoButtonSize-1).isActive = true
        
        linkedFactView.addSubview(addFactButton)
        addFactButton.centerYAnchor.constraint(equalTo: linkedFactView.centerYAnchor, constant: labelHeight/2).isActive = true
        addFactButton.trailingAnchor.constraint(equalTo: linkedFactInfoButton.leadingAnchor, constant: -20).isActive = true
//        addFactButton.centerXAnchor.constraint(equalTo: linkedFactView.centerXAnchor).isActive = true
        addFactButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        distributionInformationView.addSubview(distributionInformationImageView)
        distributionInformationImageView.leadingAnchor.constraint(equalTo: distributionInformationView.leadingAnchor).isActive = true
        distributionInformationImageView.centerYAnchor.constraint(equalTo: distributionInformationView.centerYAnchor).isActive = true
        distributionInformationImageView.widthAnchor.constraint(equalToConstant: 23).isActive = true
        distributionInformationImageView.heightAnchor.constraint(equalToConstant: 23).isActive = true
        
        distributionInformationView.addSubview(distributionInformationLabel)
        distributionInformationLabel.leadingAnchor.constraint(equalTo: distributionInformationImageView.trailingAnchor, constant: 2).isActive = true
        distributionInformationLabel.trailingAnchor.constraint(equalTo: distributionInformationView.trailingAnchor, constant: -3).isActive = true
        distributionInformationLabel.centerYAnchor.constraint(equalTo: distributionInformationView.centerYAnchor).isActive = true
        
        linkedFactView.addSubview(distributionInformationView)
        distributionInformationView.leadingAnchor.constraint(equalTo: linkedFactView.leadingAnchor, constant: 10).isActive = true
//        distributionInformationView.trailingAnchor.constraint(equalTo: addFactButton.leadingAnchor, constant: -3).isActive = true
        distributionInformationView.centerYAnchor.constraint(equalTo: linkedFactView.centerYAnchor, constant: labelHeight/2).isActive = true
        distributionInformationView.heightAnchor.constraint(equalToConstant: smallOptionViewHeight-15).isActive = true

        linkedFactView.addSubview(cancelLinkedFactButton)
        cancelLinkedFactButton.trailingAnchor.constraint(equalTo: linkedFactInfoButton.leadingAnchor, constant: -10).isActive = true
        cancelLinkedFactButton.widthAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        cancelLinkedFactButton.heightAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        cancelLinkedFactButton.centerYAnchor.constraint(equalTo: linkedFactView.centerYAnchor, constant: labelHeight/2).isActive = true
        
        self.view.addSubview(linkedFactView)
        linkedFactView.topAnchor.constraint(equalTo: linkedLocationView.bottomAnchor, constant: 1).isActive = true
        linkedFactView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        linkedFactView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        linkedFactView.heightAnchor.constraint(equalToConstant: smallOptionViewHeight+labelHeight).isActive = true
        
        
        // OptionView
        optionView.addSubview(optionButton)
        optionButton.topAnchor.constraint(equalTo: optionView.topAnchor, constant: 5).isActive = true
        optionButton.leadingAnchor.constraint(equalTo: optionView.leadingAnchor, constant: 10).isActive = true
        optionButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        optionView.addSubview(anonymousImageView)
        anonymousImageView.leadingAnchor.constraint(equalTo: optionButton.trailingAnchor, constant: 20).isActive = true
        anonymousImageView.centerYAnchor.constraint(equalTo: optionButton.centerYAnchor).isActive = true
        anonymousImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        anonymousImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        optionView.addSubview(anonymousNameLabel)
        anonymousNameLabel.leadingAnchor.constraint(equalTo: anonymousImageView.trailingAnchor, constant: 5).isActive = true
        anonymousNameLabel.centerYAnchor.constraint(equalTo: anonymousImageView.centerYAnchor).isActive = true
        anonymousNameLabel.heightAnchor.constraint(equalToConstant: defaultOptionViewHeight-10).isActive = true
        
        optionStackView.addArrangedSubview(markPostView)
        optionStackView.addArrangedSubview(postAnonymousView)
        
        optionView.addSubview(optionStackView)
        optionStackView.leadingAnchor.constraint(equalTo: optionView.leadingAnchor).isActive = true
        optionStackView.trailingAnchor.constraint(equalTo: optionView.trailingAnchor).isActive = true
        optionStackView.topAnchor.constraint(equalTo: optionButton.bottomAnchor, constant: 3).isActive = true
        optionStackView.bottomAnchor.constraint(equalTo: optionView.bottomAnchor, constant: -5).isActive = true
        stackViewHeight = optionStackView.heightAnchor.constraint(equalToConstant: 0)
        stackViewHeight!.isActive = true
        
        //Meme Mode Button
        optionView.addSubview(memeModeButton)
        memeModeButton.centerYAnchor.constraint(equalTo: optionButton.centerYAnchor).isActive = true
        memeModeButton.trailingAnchor.constraint(equalTo: optionView.trailingAnchor, constant: -10).isActive = true
        memeModeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
                
        
        self.view.addSubview(optionView)
        optionView.topAnchor.constraint(equalTo: linkedFactView.bottomAnchor, constant: 1).isActive = true
        optionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        optionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        optionViewHeight = optionView.heightAnchor.constraint(equalToConstant: defaultOptionViewHeight)
        optionViewHeight!.isActive = true
        
        setMarkPostViewUI()
        setPostAnonymousViewUI()
        
        // Here so it doesnt mess with the layout
        if let fact = linkedFact {
            self.showLinkedFact(fact: fact)
        }
        
        let endView = UIView()
        if #available(iOS 13.0, *) {
            endView.backgroundColor = .systemBackground
        } else {
            endView.backgroundColor = .white
        }
        endView.translatesAutoresizingMaskIntoConstraints = false
        
        if let user = Auth.auth().currentUser {
            if user.uid == Constants.userIDs.uidMalte || user.uid == Constants.userIDs.uidSophie || user.uid == Constants.userIDs.uidYvonne {
                endView.addSubview(fakeNameSegmentedControl)
                fakeNameSegmentedControl.leadingAnchor.constraint(equalTo: endView.leadingAnchor, constant: 10).isActive = true
                fakeNameSegmentedControl.trailingAnchor.constraint(equalTo: endView.trailingAnchor, constant: -10).isActive = true
                fakeNameSegmentedControl.topAnchor.constraint(equalTo: endView.topAnchor, constant: 10).isActive = true
                fakeNameSegmentedControl.heightAnchor.constraint(equalToConstant: 30).isActive = true
                
                endView.addSubview(fakeNameInfoLabel)
                fakeNameInfoLabel.topAnchor.constraint(equalTo: fakeNameSegmentedControl.bottomAnchor, constant: 10).isActive = true
                fakeNameInfoLabel.leadingAnchor.constraint(equalTo: endView.leadingAnchor, constant: 10).isActive = true
            }
        }
        
//        endView.addSubview(blueOwenButton)
//        blueOwenButton.topAnchor.constraint(equalTo: endView.topAnchor, constant: 10).isActive = true
//        blueOwenButton.leadingAnchor.constraint(equalTo: endView.leadingAnchor, constant: 10).isActive = true
//        blueOwenButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
//        blueOwenButton.widthAnchor.constraint(equalToConstant: 85).isActive = true
//
//        endView.addSubview(blueOwenImageView)
//        blueOwenImageView.centerYAnchor.constraint(equalTo: blueOwenButton.centerYAnchor).isActive = true
//        blueOwenImageView.leadingAnchor.constraint(equalTo: blueOwenButton.trailingAnchor, constant: 3).isActive = true
//        blueOwenImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
//        blueOwenImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        self.view.addSubview(endView)
        endView.topAnchor.constraint(equalTo: optionView.bottomAnchor, constant: 1).isActive = true
        endView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        endView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        endView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
//        explainFunctionOnFirstOpen()
    }
    
    //MARK:- PostAsSomebodyElse-UI
    
    
    let fakeNameSegmentedControl: UISegmentedControl = {
        let items = ["Me","FM", "MR", "AN", "LV", "LM"]
       let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(segmentControlChanged(sender:)), for: .valueChanged)
        control.selectedSegmentIndex = 0
        
        return control
    }()
    
    @objc func segmentControlChanged(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            if let user = Auth.auth().currentUser {
                fakeProfileUserID = user.uid
                fakeNameInfoLabel.text = "Dein persönliches Profil"
            }
        case 1:
            fakeProfileUserID = Constants.userIDs.FrankMeindlID
            fakeNameInfoLabel.text = "Frank Meindl"
        case 2:
            fakeProfileUserID = Constants.userIDs.MarkusRiesID
            fakeNameInfoLabel.text = "Markus Ries"
        case 3:
            fakeProfileUserID = Constants.userIDs.AnnaNeuhausID
            fakeNameInfoLabel.text = "Anna Neuhaus"
        case 4:
            fakeProfileUserID = Constants.userIDs.LaraVoglerID
            fakeNameInfoLabel.text = "Lara Vogler"
        case 5:
            fakeProfileUserID = Constants.userIDs.LenaMasgarID
            fakeNameInfoLabel.text = "Lena Masgar"
        default:
            fakeProfileUserID = Constants.userIDs.FrankMeindlID
        }
    }
    
    let fakeNameInfoLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 13)
        
        return label
    }()
    
    // Just for the moment, so the people get a sense of what is possible
    let blueOwenButton :DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.imagineColor, for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 13)
        button.setTitle("Nur Freunde", for: .normal)
        button.addTarget(self, action: #selector(blueOwenTapped), for: .touchUpInside)
        button.cornerRadius = 4
        button.layer.borderColor = UIColor.imagineColor.cgColor
        button.layer.borderWidth = 0.5
        
        return button
    }()
    
    let blueOwenImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "wow")
        imageView.contentMode = .scaleAspectFill
                
        return imageView
    }()
    
    @objc func blueOwenTapped() {
        performSegue(withIdentifier: "toProposals", sender: nil)
    }
    
    // MARK: - MarkPostViewUI
    let markPostView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        return view
    }()
    
    let markPostLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("markPostButtonText", comment: "mark your post text")
        label.textAlignment = .center
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        
        return label
    }()
    
    let markPostSwitch: UISwitch = {
        let switcher = UISwitch()
        switcher.translatesAutoresizingMaskIntoConstraints = false
        switcher.addTarget(self, action: #selector(markPostSwitchChanged), for: .valueChanged)
        
        
        return switcher
    }()
    
    let markPostSegmentControl :UISegmentedControl = {
        let items = [NSLocalizedString("opinion", comment: "just opinion"), NSLocalizedString("sansational", comment: "sansational"), NSLocalizedString("edited", comment: "edited")]
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.isHidden = true
        control.alpha = 0
        control.addTarget(self, action: #selector(markPostSegmentChanged), for: .touchUpInside)
        
        return control
    }()
    
    let markPostButton :DesignableButton = {
        let button = DesignableButton(type: .detailDisclosure)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(markPostInfoButtonPressed), for: .touchUpInside)
        
        return button
    }()
    
    func setMarkPostViewUI() {
        markPostView.addSubview(markPostSwitch)
        markPostSwitch.centerYAnchor.constraint(equalTo: markPostView.centerYAnchor).isActive = true
        markPostSwitch.leadingAnchor.constraint(equalTo: markPostView.leadingAnchor, constant: 5).isActive = true
        
        markPostView.addSubview(markPostSegmentControl)
        markPostSegmentControl.topAnchor.constraint(equalTo: markPostView.topAnchor, constant: 8).isActive = true
        markPostSegmentControl.leadingAnchor.constraint(equalTo: markPostSwitch.trailingAnchor, constant: 3).isActive = true
        markPostSegmentControl.bottomAnchor.constraint(equalTo: markPostView.bottomAnchor, constant: -8).isActive = true
        
        markPostView.addSubview(markPostLabel)
        markPostLabel.centerXAnchor.constraint(equalTo: markPostView.centerXAnchor).isActive = true
        markPostLabel.centerYAnchor.constraint(equalTo: markPostView.centerYAnchor).isActive = true
        
        markPostView.addSubview(markPostButton)
        markPostButton.centerYAnchor.constraint(equalTo: markPostView.centerYAnchor).isActive = true
        markPostButton.trailingAnchor.constraint(equalTo: markPostView.trailingAnchor, constant: -10).isActive = true
        markPostButton.leadingAnchor.constraint(equalTo: markPostSegmentControl.trailingAnchor, constant: 5).isActive = true
        markPostButton.widthAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        markPostButton.heightAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        
    }
    
    // MARK: - Post Anonymous UI
    let postAnonymousView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        return view
    }()
    
    let postAnonymousLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("post_anonymous_label", comment: "post anonymous")
        label.textAlignment = .center
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        
        return label
    }()
    
    let postAnonymousSwitch: UISwitch = {
       let switcher = UISwitch()
        switcher.translatesAutoresizingMaskIntoConstraints = false
        switcher.addTarget(self, action: #selector(postAnonymousSwitchChanged), for: .valueChanged)
        
        return switcher
    }()
    
    let postAnonymousButton :DesignableButton = {
        let button = DesignableButton(type: .detailDisclosure)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(postAnonymousButtonPressed), for: .touchUpInside)
        
        return button
    }()
    
    func setPostAnonymousViewUI() {
        postAnonymousView.addSubview(postAnonymousSwitch)
        postAnonymousSwitch.centerYAnchor.constraint(equalTo: postAnonymousView.centerYAnchor).isActive = true
        postAnonymousSwitch.leadingAnchor.constraint(equalTo: postAnonymousView.leadingAnchor, constant: 5).isActive = true
        
        postAnonymousView.addSubview(postAnonymousLabel)
        postAnonymousLabel.centerYAnchor.constraint(equalTo: postAnonymousView.centerYAnchor).isActive = true
        postAnonymousLabel.centerXAnchor.constraint(equalTo: postAnonymousView.centerXAnchor).isActive = true
        
        postAnonymousView.addSubview(postAnonymousButton)
        postAnonymousButton.centerYAnchor.constraint(equalTo: postAnonymousView.centerYAnchor).isActive = true
        postAnonymousButton.trailingAnchor.constraint(equalTo: postAnonymousView.trailingAnchor, constant: -10).isActive = true
        postAnonymousButton.widthAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        postAnonymousButton.heightAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        
    }
    
    // MARK: - KeyboardGoesUp
    
    @objc func keyboardWillChange(notification: NSNotification) {
        
        if !self.up {
            
            if let _ = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                if descriptionView.descriptionTextView.isFirstResponder {
                    
                    var offset:CGFloat = 75
                    switch selectedOption {
                    case .multiPicture:
                        offset = 125
                    case .thought:
                        offset = 50
                    case .picture:
                        offset = 125
                    case .link:
                        offset = 100
                    }
                    
                    
                    self.view.frame.origin.y -= offset
                    self.up = true
                    
                }
            }
        }
    }
    
    @objc func keyboardWillHide() {
        
        if self.up {
            
            var offset:CGFloat = 75
            switch selectedOption {
            case .multiPicture:
                offset = 125
            case .thought:
                offset = 50
            case .picture:
                offset = 125
            case .link:
                offset = 100
            }
            
            self.view.frame.origin.y += offset
            self.up = false
        }
    }
    
    // MARK: - Functions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleView.titleTextView.resignFirstResponder()
        linkView.linkTextField.resignFirstResponder()
        descriptionView.descriptionTextView.resignFirstResponder()
        
        self.removeTipViews()
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
            self.linkFactExplanationTipView!.show(forView: self.linkedFactView)
        }
    }
    
    //MARK: - MemeMode Maker
    
    @objc func memeModeTapped() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        memeModeButton.isEnabled = false
        showMemeMode()
    }
    
    
    func showMemeMode() {
        if let window = UIApplication.shared.keyWindow {
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
                    self.memeModeButton.isEnabled = true
                    
                    if self.selectedOption != .picture || self.selectedOption != .multiPicture {
                        //Switch to picture mode so the meme can be shown
                        self.postSelectionSegmentedControl.selectedSegmentIndex = 1
                        self.prepareForSelectionChange()
                    }
                }
            }
        }
    }
    
    //MARK: - Buttons & Stuff
    
    func camTapped() {
        if let _ = Auth.auth().currentUser {
            
            let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            switch status {
            case .authorized:
                self.showCamera()
                
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted) in
                    if granted {
                        self.showCamera()
                    } else {
                        self.camDenied()
                    }
                }
                
            case .denied:
                self.camDenied()
                
            case .restricted:
                let alert = UIAlertController(title: "Restricted",
                                              message: "You've been restricted from using the camera on this device. Without camera access this feature won't work. Please contact the device owner so they can give you access.",
                                              preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func camDenied() {
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
        imagePicker.sourceType = .camera
        imagePicker.cameraCaptureMode = .photo
        imagePicker.cameraDevice = .rear
        imagePicker.cameraFlashMode = .off
        imagePicker.showsCameraControls = true
        
        //imagePicker.allowsEditing = true
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
    func camRollTapped() {
        if let _ = Auth.auth().currentUser {
            
            switch PHPhotoLibrary.authorizationStatus() {
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { (status) in
                    if status == .authorized {
                        self.showPictureAlert()
                    } else {
                        self.alert(message: NSLocalizedString("photoAccess_permission_denied_text", comment: "how you can change that"), title: "Something seems to be wrong")
                    }
                }
            case .restricted, .denied:
                alert(message: NSLocalizedString("photoAccess_permission_denied_text", comment: "how you can change that"), title: "Something seems to be wrong")
            case .authorized:
                showPictureAlert()
            case .limited:
                showPictureAlert()
            }
            
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func showPictureAlert() {
        
        if let _ = memeView {  //Select image for meme, no multi picture possible
            showImagePicker()
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
        }
    }
    
    
    
    @objc func markPostSwitchChanged() {
        if markPostSwitch.isOn {
            markPostSegmentControl.isHidden = false
            markPostLabel.isHidden = true
            
            UIView.animate(withDuration: 0.3) {
                self.markPostSegmentControl.alpha = 1
            }
            
            
            reportType = .opinion
        } else {
        
            UIView.animate(withDuration: 0.3, animations: {
                self.markPostSegmentControl.alpha = 0
            }) { (_) in
                self.markPostSegmentControl.isHidden = true
                self.markPostLabel.isHidden = false
            }
            
            reportType = .normal
        }
    }
    
    @objc func optionButtonTapped() {
                
        if descriptionView.descriptionTextView.isFirstResponder {
            descriptionView.descriptionTextView.resignFirstResponder()
        } else if titleView.titleTextView.isFirstResponder {
            titleView.titleTextView.resignFirstResponder()
        }
        if let height = optionViewHeight {
            if height.constant <= defaultOptionViewHeight {
                height.constant = 125   //Previously 165
                stackViewHeight!.isActive = false
                
                UIView.animate(withDuration: 0.4, animations: {
                    self.view.layoutIfNeeded()
                }) { (_) in
                    self.optionStackView.isHidden = false
                    UIView.animate(withDuration: 0.1) {
                        self.optionStackView.alpha = 1
                    }
                }
            } else {
                stackViewHeight = optionStackView.heightAnchor.constraint(equalToConstant: 0)
                stackViewHeight!.isActive = true
                
                height.constant = defaultOptionViewHeight
                
                UIView.animate(withDuration: 0.4, animations: {
                    self.optionStackView.alpha = 0
                    self.view.layoutIfNeeded()
                }) { (_) in
                    self.optionStackView.isHidden = true
                }
            }
        }
    }
    
    @objc func linkFactToPostTapped() {
        performSegue(withIdentifier: "searchFactsSegue", sender: nil)
    }
    
    @objc func cancelLinkedFactTapped() {
        distributionInformationLabel.text = "Feed"
        distributionInformationImageView.image = UIImage(named: "Feed")
        
        cancelLinkedFactButton.isHidden = true
        addedFactImageView.removeFromSuperview()
        addedFactDescriptionLabel.removeFromSuperview()
        
        self.linkedFact = nil
        self.postOnlyInTopic = false
        
        addFactButton.isHidden = false
    }
    
    @objc func markPostInfoButtonPressed() {
        if let tipView = self.markPostTipView {
            tipView.dismiss()
            markPostTipView = nil
        } else {
            self.markPostTipView = EasyTipView(text: Constants.texts.markPostText)
            markPostTipView!.show(forView: optionView)
        }
    }
    
    @objc func linkedFactInfoButtonTapped() {
        if let tipView = self.linkedFactTipView {
            tipView.dismiss()
            linkedFactTipView = nil
        } else {
            self.linkedFactTipView = EasyTipView(text: NSLocalizedString("linked_fact_tip_view_text", comment: "how and why"))
            linkedFactTipView!.show(forView: linkedFactView)
        }
    }
    
    @objc func postAnonymousButtonPressed() {
        if let tipView = self.postAnonymousTipView {
            tipView.dismiss()
            postAnonymousTipView = nil
        } else {
            self.postAnonymousTipView = EasyTipView(text: Constants.texts.postAnonymousText)
            postAnonymousTipView!.show(forView: optionView)
        }
    }
    
    @objc func postAnonymousSwitchChanged() {
        if postAnonymousSwitch.isOn {
            self.postAnonymous = true
            self.anonymousImageView.isHidden = false
            
            let alert = UIAlertController(title: NSLocalizedString("anonymous_name_alert_title", comment: "anonymous name"), message: NSLocalizedString("anonymous_name_alert_message", comment: "no real name and such"), preferredStyle: .alert)

            alert.addTextField { (textField) in
                textField.placeholder = NSLocalizedString("anonymous_name_placeholder", comment: "john doe")
            }

            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let textField = alert!.textFields![0] // Force unwrapping because we know it exists.
                
                if let text = textField.text {
                    self.anonymousName = text
                    self.anonymousNameLabel.text = text
                } //else: Default String will show in the feed
            }))
            self.present(alert, animated: true, completion: nil)
            
        } else {
            self.postAnonymous = false
            self.anonymousImageView.isHidden = true
        }
    }
    
    @IBAction func postSelectionSegmentChanged(_ sender: Any) {
        prepareForSelectionChange()
    }
    
    func prepareForSelectionChange() {
        self.postSelectionSegmentedControl.isEnabled = false
        
        switch self.selectedOption {
        case .picture:
            
            //Let the pictureView disappear
            UIView.animate(withDuration: 0.1, animations: {
                self.pictureView.folderButton.alpha = 0
                self.pictureView.cameraButton.alpha = 0
                self.pictureView.pictureLabel.alpha = 0
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
                self.linkInfoButton.alpha = 0
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
        if postSelectionSegmentedControl.selectedSegmentIndex == 0 {
            self.selectedOption = .thought
            setCompleteUIForThought()
        }
        if postSelectionSegmentedControl.selectedSegmentIndex == 1 {
            self.selectedOption = .picture
            insertUIForPicture()
        }
        if postSelectionSegmentedControl.selectedSegmentIndex == 2 {
            self.selectedOption = .link
            insertUIForLink()
        }
    }
    
    
    @objc func markPostSegmentChanged() {
        
        if markPostSegmentControl.selectedSegmentIndex == 0 {
            reportType = .opinion
        }
        if markPostSegmentControl.selectedSegmentIndex == 1 {
            reportType = .sensationalism
        }
        if markPostSegmentControl.selectedSegmentIndex == 2 {
            reportType = .edited
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchFactsSegue" {
            if let navCon = segue.destination as? UINavigationController {
                if let factVC = navCon.topViewController as? CommunityCollectionViewController {
                    factVC.addFactToPost = .newPost
                    factVC.delegate = self
                }
            }
        }
        
        if segue.identifier == "toMapSegue" {
            if let mapVC = segue.destination as? MapViewController {
                mapVC.locationDelegate = self
            }
        }
    }
    
    //MARK:- SharePressed
    
    @IBAction func sharePressed(_ sender: Any) {
        
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

            if self.postAnonymous {
                userID = anonymousString
            } else {
                userID = user.uid
            }
            
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
                    self.uploadImages(postRef: postRef, userID: userID)
                case .picture:
                    self.savePicture(userID: userID, postRef: postRef)
                case .link:
                    if let text = linkView.linkTextField.text {
                        if text.contains(".mp4") {
                            self.postGIF(postRef: postRef, userID: userID)
                        } else if text.contains("music.apple.com") || text.contains("open.spotify.com/") || text.contains("deezer.page.link") {
                            self.getSongwhipData(link: text) { (data) in
                                if let data = data {
                                    if let link = data["link"] as? String {
                                        self.getLinkPreview(linkString: link) { (link) in
                                            if let link = link {
                                                self.postLink(postRef: postRef, userID: userID, link: link, songwhipData: data)
                                            }
                                        }
                                    }
                                } else {
                                    print("No Songwhip data")
                                }
                            }
                        } else if let _ = text.youtubeID {
                            //check if the youtubeVideo is a music video/song
                            self.getSongwhipData(link: text) { (data) in
                                if let data = data {
                                    //if so get link data and post as link
                                    if let link = data["link"] as? String {
                                        self.getLinkPreview(linkString: link) { (link) in
                                            if let link = link {
                                                self.postLink(postRef: postRef, userID: userID, link: link, songwhipData: data)
                                            }
                                        }
                                    }
                                } else {
                                    //if not post as yt video
                                    self.postYTVideo(postRef: postRef, userID: userID)
                                }
                            }
                        } else {
                            //post a normal Link but get the image and the different descriptions first
                            self.getLinkPreview(linkString: text) { (link) in
                                if let link = link {
                                    self.postLink(postRef: postRef, userID: userID, link: link, songwhipData: nil)
                                } else {
                                    return
                                }
                            }
                        }
                    } else {
                        self.alert(message: NSLocalizedString("missing_info_alert_link", comment: "enter link please"))
                    }
                }
            } else {
                self.alert(message: NSLocalizedString("missing_info_alert_title", comment: "enter title pls"))
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    //MARK:- LinkPreview
    
    func getLinkPreview(linkString: String, returnLink: @escaping (Link?) -> Void) {
        if linkString.isValidURL {
            slp.preview(linkString, onSuccess: { (response) in
                var imageURL: String?
                var shortURL = ""
                var linkTitle = ""
                var linkDescription = ""

                if let URL = response.image {
                    imageURL = URL
                }
                if let URL = response.canonicalUrl {
                    shortURL = URL
                }
                if let title = response.title {
                    linkTitle = title
                }
                if let description = response.description {
                    linkDescription = description
                }
                let link = Link(link: linkString, title: linkTitle, description: linkDescription, shortURL: shortURL, imageURL: imageURL)

                returnLink(link)

            }) { (err) in
                print("We have an error: \(err.localizedDescription)")
                self.alert(message: err.localizedDescription, title: NSLocalizedString("error_title", comment: "got error"))
                self.view.activityStopAnimating()
                self.shareButton.isEnabled = true
                
                returnLink(nil)
            }
        } else {
            self.view.activityStopAnimating()
            self.shareButton.isEnabled = true
            self.alert(message: NSLocalizedString("error_link_not_valid", comment: "not valid"), title: NSLocalizedString("error_title", comment: "got error"))
            
            returnLink(nil)
        }
    }

    
    func getSongwhipData(link: String, returnData: @escaping ([String: Any]?) -> Void) {
        
        if let url = URL(string: "https://songwhip.com/") {
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            let body = "{\"url\":\"\(link)\"}"
            request.httpBody = body.data(using: .utf8)
            
            
            URLSession.shared.dataTask(with: request) { (data, response, err) in
                if let error = err {
                    print("We have an error getting the songwhip Data: ", error.localizedDescription)
                } else {
                    if let data = data {
                        
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] {
                                
                                guard let type = json["type"] as? String,
                                      let name = json["name"] as? String,
                                      let releaseDate = json["releaseDate"] as? String,
                                      let link = json["url"] as? String,
                                      let musicImage = json["image"] as? String,
                                      let artistData = json["artists"] as? [[String: Any]]
                                else {
                                    print("Returne ohne daten")
                                    return
                                }
                                
                                guard let date = self.getReleaseDate(stringDate: releaseDate) else { return }
                                
                                if let artistInfo = artistData.first {
                                    if let artistName = artistInfo["name"] as? String, let artistImage = artistInfo["image"] as? String {
                                        
                                        let songwhipData: [String: Any] = ["musicType": type, "name": name, "releaseDate": Timestamp(date: date), "link": link, "artist": artistName, "artistImage": artistImage, "musicImage": musicImage]
                                        
                                        returnData(songwhipData)
                                    }
                                }
                            } else {
                                print("Couldnt get the jsonData from Songwhip API Call")
                                returnData(nil)
                            }
                        } catch {
                            print("Couldnt get the jsonData from Songwhip API Call")
                            returnData(nil)
                        }
                    }
                }
            }.resume()
        }
    }
    
    func getReleaseDate(stringDate: String) -> Date? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let date = dateFormatter.date(from: stringDate)
        
        return date
    }
    
    // MARK: - MultiImagePicker
    
    func openMultiPictureImagePicker() {
        let multiImagePicker = ImagePickerController()
        let options = multiImagePicker.settings
        options.selection.max = 3
        let fetchOptions = options.fetch.album.options
                options.fetch.album.fetchResults = [
                    PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumRecentlyAdded, options: fetchOptions),
                    PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: fetchOptions),
                ]
        
        self.multiImageAssets.removeAll()
        //TODo: change the selection
        self.presentImagePicker(multiImagePicker,
                                
        select: { (asset) in
            self.multiImageAssets.append(asset)
        }, deselect: { (asset) in
            self.multiImageAssets = self.multiImageAssets.filter{ $0 != asset}
        }, cancel: { (asset) in
            self.multiImageAssets.removeAll()
        }, finish: { (asset) in
            self.previewPictures.removeAll()
            self.getImages(forPreview: true) { (_) in }
            self.increasePictureUI()
            })
    }
    
    
    func getPictureInCompressedQuality(image: UIImage) -> Data? {
        if let originalImage = image.jpegData(compressionQuality: 1) {
            let data = NSData(data: originalImage)
            
            let imageSize = data.count/1000
            
            if imageSize <= 500 {   // When the imageSize is under 500kB it wont be compressed, because you can see the difference
                // No compression
                return originalImage
            } else if imageSize <= 1000 {
                if let smallerImage = image.jpegData(compressionQuality: 0.4) {
                    
                    return smallerImage
                }
            } else if imageSize <= 2000 {
                if let smallerImage = image.jpegData(compressionQuality: 0.25) {
                    
                    return smallerImage
                }
            } else {
                if let smallerImage = image.jpegData(compressionQuality: 0.1) {
                    
                    return smallerImage
                }
            }
        }
        
        return nil
    }
    
    func getImages(forPreview: Bool, images: @escaping ([Data]) -> Void)  {
        self.selectedImagesFromPicker.removeAll()
        
        for asset in self.multiImageAssets {
            
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            
            // Request the maximum size. If you only need a smaller size make sure to request that instead.
            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (image, info) in
                if let image = image {
                    
                    if forPreview {
                        self.previewPictures.append(image)
                        self.pictureView.previewCollectionView.reloadData()
                        UIView.animate(withDuration: 0.3) {
                            self.pictureView.removePictureButton.alpha = 1
                            self.pictureView.removePictureButton.isEnabled = true
                        }
                    } else {
                        if self.selectedImageWidth == 0 {   // Set the width just for the first Image
                            let size = image.size
                            
                            self.selectedImageHeight = size.height
                            self.selectedImageWidth = size.width
                        } else {
                            print("Height already set")
                        }
                        
                        if let comImage = self.getPictureInCompressedQuality(image: image) {
                            self.selectedImagesFromPicker.append(comImage)
                            
                            if self.selectedImagesFromPicker.count == self.multiImageAssets.count {
                                images(self.selectedImagesFromPicker)
                            }
                            
                            print("##Das ist das komprimierte Bild: \(comImage)")
                        }
                    }
                } else {
                    self.alert(message: NSLocalizedString("error_uploading_multiple_pictures_message", comment: "werid bug"), title: NSLocalizedString("error_title", comment: "we have error"))
                    self.view.activityStopAnimating()
                    self.shareButton.isEnabled = true
                }
            }
        }
    }
    
    func uploadImages(postRef: DocumentReference, userID: String) {
        print("Upload Images")
        if multiImageAssets.count >= 2 && multiImageAssets.count <= 3 {
            
            getImages(forPreview: false) { (data) in
                
                let count = data.count
                var index = 0
                
                print("##So viele im selectedimagesfrompicker: \(count)")
                
                for image in data {
                    
                    let storageRef = Storage.storage().reference().child("postPictures").child("\(postRef.documentID)-\(index).png")
                    
                    index+=1
                    print("## storageRef: \(storageRef)")
                    storageRef.putData(image, metadata: nil, completion: { (metadata, error) in    //save picture
                        if let error = error {
                            print("We have an error: \(error)")
                            return
                        } else {
                            storageRef.downloadURL(completion: { (url, err) in  // Hier wird die URL runtergezogen
                                if let error = err {
                                    print("We have an error: \(error)")
                                    return
                                } else {
                                    if let url = url {
                                        self.imageURLs.append(url.absoluteString)
                                        
                                        if self.imageURLs.count == count { // Uploaded all x Pictures and stored the urls in self.imageURLs
                                            self.postMultiplePictures(postRef: postRef, userID: userID)
                                        }
                                    }
                                }
                            })
                        }
                    })
                }
            }
        } else {
            self.alert(message: NSLocalizedString("error_choosing_multiple_pictures_message", comment: "choose more"), title: NSLocalizedString("error_title", comment: "got error"))
            self.view.activityStopAnimating()
            self.shareButton.isEnabled = true
        }
        
    }
    
    //MARK: - Image Picker
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var animated = true
        if let _ = memeView {
            animated = false
        }
        imagePicker.dismiss(animated: animated, completion: nil)
        
        if picker.sourceType == .camera {
            self.camPic = true
        }
        
        if let originalImage = info[.originalImage] as? UIImage {
            
            showCropView(image: originalImage)
            print("#we have an image")
                        
        } else if let videoURL = info[.mediaURL] as? NSURL{
            print("#We got a video")
//            uploadVideo(videoURL: videoURL)
            testVideo(videoURL: videoURL)
        }
    }
    
    func showCropView(image: UIImage) {
        let cropViewController = CropViewController(image: image)
        cropViewController.delegate = self
        cropViewController.hidesBottomBarWhenPushed = true
        
        if let _ = memeView {
            cropViewController.aspectRatioLockEnabled = true
            cropViewController.aspectRatioPreset = .preset16x9
        } else {
            cropViewController.aspectRatioLockEnabled = false
        }
        self.cropViewController = cropViewController
        self.present(cropViewController, animated: true, completion: nil)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        
        if let cropVC = self.cropViewController {
            var animated = true
            if let _ = memeView {
                animated = false
            }
            cropVC.dismiss(animated: animated) {
                if let memeView = self.memeView {
                    memeView.imageSelected(image: image)
                } else {
                    self.setImageAndShowPreviewImage(image: image)
                }
            }
        }
    }
    
    func setImageAndShowPreviewImage(image: UIImage) {
        
        selectedImageFromPicker = image
        selectedImageHeight = image.size.height
        selectedImageWidth = image.size.width
        
        self.increasePictureUI()
        self.previewPictures.removeAll()
        self.previewPictures.append(image)
        self.pictureView.previewCollectionView.reloadData()
        
        UIView.animate(withDuration: 0.3) {
            self.pictureView.removePictureButton.alpha = 1
            self.pictureView.removePictureButton.isEnabled = true
        }
    }
    
    
    
    func increasePictureUI() {
        if let pictureHeight = self.pictureViewHeight {
            pictureHeight.constant = 150
            
            UIView.animate(withDuration: 0.6) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func decreasePictureUI() {
        if let pictureHeight = self.pictureViewHeight {
            pictureHeight.constant = 100
            
            UIView.animate(withDuration: 0.6) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    func savePicture(userID: String, postRef: DocumentReference) {
        
        if let image = self.selectedImageFromPicker?.jpegData(compressionQuality: 1) {
            let data = NSData(data: image)
            
            let imageSize = data.count/1000
            
            
            if imageSize <= 500 {   // When the imageSize is under 500kB it wont be compressed, because you can see the difference
                // No compression
                print("No compression")
                self.storeImage(data: image, postRef: postRef, userID: userID)
            } else if imageSize <= 1000 {
                if let image = self.selectedImageFromPicker?.jpegData(compressionQuality: 0.4) {
                    
                    self.storeImage(data: image, postRef: postRef, userID: userID)
                }
            } else if imageSize <= 2000 {
                if let image = self.selectedImageFromPicker?.jpegData(compressionQuality: 0.25) {
                    
                    self.storeImage(data: image, postRef: postRef, userID: userID)
                }
            } else {
                if let image = self.selectedImageFromPicker?.jpegData(compressionQuality: 0.1) {
                    
                    self.storeImage(data: image, postRef: postRef, userID: userID)
                }
            }
            
        } else {
            self.alert(message: NSLocalizedString("error_choosing_picture", comment: "got no pic"), title: NSLocalizedString("error_title", comment: "got error"))
            self.view.activityStopAnimating()
            self.shareButton.isEnabled = true
        }
    }
    
    func storeImage(data: Data, postRef: DocumentReference, userID: String) {
        
        let storageRef = Storage.storage().reference().child("postPictures").child("\(postRef.documentID).png")
        
        storageRef.putData(data, metadata: nil, completion: { (metadata, error) in    //Store image
            if let error = error {
                print(error)
                return
            }
            storageRef.downloadURL(completion: { (url, err) in  // Download url and save it
                if let err = err {
                    print(err)
                    return
                }
                if let url = url {
                    self.imageURL = url.absoluteString
                    
                    self.postPicture(postRef: postRef, userID: userID)
                }
            })
        })
    }
    
    //MARK:- UploadVideo
    
    func testVideo(videoURL: NSURL) {
        let semaphore = DispatchSemaphore (value: 0)
        
        if let data = NSData(contentsOf: videoURL as URL) {
            
            let parameters = [
                    "key": "video",
                    "value": data,
                    "type": "text"
                ] as [String : Any]

            let boundary = "Boundary-\(UUID().uuidString)"
            var body = Data()

            let paramName = parameters["key"]
            body.append(contentsOf: "--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition:form-data; name=\"\(paramName)\"".data(using: .utf8)!)
            
            if let paramValue = parameters["value"] as? String {
                body.append("\r\n\r\n\(paramValue)\r\n".data(using: .utf8)!)
            } else {
                body.append(data as Data)
            }
            
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
    
            let postData = body

            var request = URLRequest(url: URL(string: "https://api.imgur.com/3/image")!,timeoutInterval: Double.infinity)
            request.addValue("Client-ID \(imgurClientID)", forHTTPHeaderField: "Authorization")
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            request.httpMethod = "POST"
            request.httpBody = postData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data else {
                    print(String(describing: error))
                    return
                }
                print(String(data: data, encoding: .utf8)!)
                semaphore.signal()
                
            }
            
            task.resume()
            semaphore.wait()
            
        }
    }
    
//    func testVideo(videoURL: NSURL) {
//        let semaphore = DispatchSemaphore (value: 0)
//
//        if let data = NSData(contentsOf: videoURL as URL) {
//
//            let parameters = [
//                [
//                    "key": "image",
//                    "value": data.base64EncodedString(options: .lineLength64Characters),
//                    "type": "text"
//                ]] as [[String : Any]]
//
//            let boundary = "Boundary-\(UUID().uuidString)"
//            var body = ""
//            var error: Error? = nil
//            for param in parameters {
//                if param["disabled"] == nil {
//                    let paramName = param["key"]!
//                    body += "--\(boundary)\r\n"
//                    body += "Content-Disposition:form-data; name=\"\(paramName)\""
//                    let paramType = param["type"] as! String
//                    if paramType == "text" {
//                        let paramValue = param["value"] as! String
//                        body += "\r\n\r\n\(paramValue)\r\n"
//                    } else {
//                        let paramSrc = param["src"] as! String
//                        do {
//                            let fileData = try NSData(contentsOfFile:paramSrc, options:[]) as Data
//                            let fileContent = String(data: fileData, encoding: .utf8)!
//                            body += "; filename=\"\(paramSrc)\"\r\n"
//                                + "Content-Type: \"content-type header\"\r\n\r\n\(fileContent)\r\n"
//                        } catch {
//                            return
//                        }
//
//                    }
//                }
//            }
//            body += "--\(boundary)--\r\n";
//            let postData = body.data(using: .utf8)
//
//            var request = URLRequest(url: URL(string: "https://api.imgur.com/3/image")!,timeoutInterval: Double.infinity)
//            request.addValue("Client-ID \(imgurClientID)", forHTTPHeaderField: "Authorization")
//            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//
//            request.httpMethod = "POST"
//            request.httpBody = postData
//
//            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                guard let data = data else {
//                    print(String(describing: error))
//                    return
//                }
//                print(String(data: data, encoding: .utf8)!)
//                semaphore.signal()
//
//            }
//
//            task.resume()
//            semaphore.wait()
//
//        }
//    }
    
    func uploadVideo(videoURL: NSURL) {
        if let url = URL(string: "https://api.imgur.com/3/upload") {
            print("Upload Video")
            
            var request = URLRequest(url: url)
            request.addValue("Client-ID \(imgurClientID)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "POST"
            
            if let data = NSData(contentsOf: videoURL as URL) {
                let base64String = data.base64EncodedString(options: .lineLength64Characters)
                
//                // Build our multiform and add our base64 image
//                let body = NSMutableData()
////                body.append("Content-Disposition: form-data; name=\"image\"\r\n\r\n".data(using: .utf8)!)
//                body.append(base64String.data(using: .utf8)!)
//                request.httpBody = body as Data
//                let body = "video"=\"\(base64Data)\", \"title\"=\"whatever bruh\", \"type\"=\"base64\", \"disable_audio=1"

                let body = "image=\"\(base64String)\""
                request.httpBody = body.data(using: .utf8)
                print(body, "##boooody")
                URLSession.shared.dataTask(with: request) { (data, response, err) in
                    if let error = err {
                        print("We have an error getting the video data: ", error.localizedDescription)
                    } else {
                        if let data = data {
                            
                            do {
                                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] {
                                    
                                    guard let data = json["data"] as? [String: Any]
                                    else {
                                        print("Returne ohne daten: \(json)")
                                        return
                                    }
                                    
                                    print("Got data: ", json)
//                                    if let jsonData = data.first {
//                                        guard let type = jsonData["type"] as? String,
//                                              let name = jsonData["name"] as? String,
//                                              let link = jsonData["link"] as? String
//                                        else {
//                                            print("Returne ohne jsondaten: \(jsonData)")
//                                            return
//                                        }
//
//                                        print("type: \(type), name: \(name), link: \(link)")
//                                    }
                                    
                                    
                                } else {
                                    print("Couldnt get the jsonData from Imgur API Call")
                                }
                            } catch {
                                print("Could not get the jsonData from Imgur API Call")
                            }
                        }
                    }
                }.resume()
            }
        }
    }
    
    let imgurClientID = "22e958a40c80519"
    let imgurClientSecret = "02027ffe7b67b8f30cb5f3d9dd9820dc7391d5ac"
    
    // MARK: - Upload the post
    
    func getDate() -> Timestamp {
        return Timestamp(date: Date())
    }
    
    func postThought(postRef: DocumentReference, userID: String) {
        
        let text = descriptionView.descriptionTextView.text.trimmingCharacters(in: .newlines)
        let descriptionText = text.replacingOccurrences(of: "\n", with: "\\n")  // Just the text of the description has got line breaks
        
        let tags = self.getTagsToSave()
        
        let dataDictionary: [String: Any] = ["title": titleView.titleTextView.text, "description": descriptionText, "createTime": getDate(), "originalPoster": userID, "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "type": "thought", "report": getReportString(), "tags": tags]
        
        self.uploadTheData(postRef: postRef, userID: userID, dataDictionary: dataDictionary)
        
        print("thought posted")
    }
    
    func postLink(postRef: DocumentReference, userID: String, link: Link, songwhipData: [String: Any]?) {
        if linkView.linkTextField.text != "", let title = titleView.titleTextView.text {
            
            let descriptionText = descriptionView.descriptionTextView.text.replacingOccurrences(of: "\n", with: "\\n")
            let tags = self.getTagsToSave()
            
            var dataDictionary: [String: Any] = ["title": title, "description": descriptionText, "createTime": getDate(), "originalPoster": userID, "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "type": "link", "report": getReportString(), "link": link.link, "linkTitle": link.linkTitle, "linkDescription": link.linkDescription, "linkShortURL": link.shortURL, "tags": tags]
            
            if let dictionary = songwhipData {
                //Merge the uploaddata and the songwhip data to one dictionary and keep the songwhip link, not the streaming service link
                dataDictionary = dataDictionary.merging(dictionary) { (_, new) in new }
            }
            
            if let url = link.imageURL {
                dataDictionary["linkImageURL"] = url
            }
                            
            self.uploadTheData(postRef: postRef, userID: userID, dataDictionary: dataDictionary)
            
        } else {
            self.view.activityStopAnimating()
            self.shareButton.isEnabled = true
            self.alert(message: NSLocalizedString("error_no_link", comment: "no link"), title: NSLocalizedString("error_title", comment: "got error"))
        }
    }
    
    func postPicture(postRef: DocumentReference, userID: String) {
        if let _ = selectedImageFromPicker, let url = imageURL, let title = titleView.titleTextView.text {
            
            let descriptionText = descriptionView.descriptionTextView.text.replacingOccurrences(of: "\n", with: "\\n")
            let tags = self.getTagsToSave()
            
            let dataDictionary: [String: Any] = ["title": title, "description": descriptionText, "createTime": getDate(), "originalPoster": userID, "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "type": "picture", "report": getReportString(), "imageURL": url, "imageHeight": Double(selectedImageHeight), "imageWidth": Double(selectedImageWidth), "tags": tags]
            
            self.uploadTheData(postRef: postRef, userID: userID, dataDictionary: dataDictionary)
            print("picture posted")
            
        } else {
            self.view.activityStopAnimating()
            self.shareButton.isEnabled = true
            self.alert(message: NSLocalizedString("error_no_picture", comment: "no picture"), title: NSLocalizedString("error_title", comment: "got error"))
        }
    }
    
    func postMultiplePictures(postRef: DocumentReference, userID: String) {
        
        let descriptionText = descriptionView.descriptionTextView.text.replacingOccurrences(of: "\n", with: "\\n")
        let tags = self.getTagsToSave()
        
        let dataDictionary: [String: Any] = ["title": titleView.titleTextView.text, "description": descriptionText, "createTime": getDate(), "originalPoster": userID, "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "type": "multiPicture", "report": getReportString(), "imageURLs": self.imageURLs, "imageHeight": Double(selectedImageHeight), "imageWidth": Double(selectedImageWidth), "tags": tags]
        
        self.uploadTheData(postRef: postRef, userID: userID, dataDictionary: dataDictionary)
        print("multiPicture posted")
        
    }
    
    func postGIF(postRef: DocumentReference, userID: String) {
        
        let text = linkView.linkTextField.text
        
        var link: String?
        
        if let text = text {
            if text.contains(".mp4") {
                link = text
            } else {
                
                Analytics.logEvent("FailedToPostGIF", parameters: [
                    AnalyticsParameterTerm: ""
                ])
                self.alert(message: NSLocalizedString("error_gif_wrong_ending", comment: "just .mp4"), title: NSLocalizedString("error_title", comment: "got error"))
                return
                
//                if let imgurID = text.imgurID { // Check if Imgur
//                    let imgurLink = "https://i.imgur.com/\(imgurID).mp4"
//
//                    link = imgurLink
//                } else {
//                    self.alert(message: "Wir können dein GIF leider nicht hochladen. Im Moment sind nur Links mit Endung '.mp4' oder von der Internetseite imgur.com möglich. Sag uns aber gerne bescheid, wie du deine GIFs verbreiten möchtest!", title: "Tut uns Leid...")
//                    self.view.activityStopAnimating()
//                    self.shareButton.isEnabled = true
//
//                    return
//                }
            }
        } else {
            self.alert(message: "Bitte gib einen link zu deinem GIF ein.", title: "Kein Link angegeben")
            self.view.activityStopAnimating()
            self.shareButton.isEnabled = true
            
            return
        }
        
                    
        if let link = link {
            print("Das ist der GIF Link: \(link)")
            self.view.activityStopAnimating()
            self.shareButton.isEnabled = true
            
            
            let descriptionText = descriptionView.descriptionTextView.text.replacingOccurrences(of: "\n", with: "\\n")
            let tags = self.getTagsToSave()

            let dataDictionary: [String: Any] = ["title": titleView.titleTextView.text, "description": descriptionText, "createTime": getDate(), "originalPoster": userID, "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "type": "GIF", "report": getReportString(), "link": link, "tags": tags]

            self.uploadTheData(postRef: postRef, userID: userID, dataDictionary: dataDictionary)

            print("GIF Postet")
            
        }
    }
    
    
    func postYTVideo(postRef: DocumentReference, userID: String) {
        if let _ = linkView.linkTextField.text?.youtubeID {  // YouTubeVideo
            
            let descriptionText = descriptionView.descriptionTextView.text.replacingOccurrences(of: "\n", with: "\\n")
            let tags = self.getTagsToSave()
            
            let dataDictionary: [String: Any] = ["title": titleView.titleTextView.text, "description": descriptionText, "createTime": getDate(), "originalPoster": userID, "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "type": "youTubeVideo", "report": getReportString(), "link": linkView.linkTextField.text!, "tags": tags]
            
            self.uploadTheData(postRef: postRef, userID: userID, dataDictionary: dataDictionary)
            
            print("YouTubeVideo Postet")
        } else {
            self.view.activityStopAnimating()
            self.shareButton.isEnabled = true
            self.alert(message: "Du hast kein Youtube Link angegeben. Möchtest du kein Youtube-Video posten, wähle bitte eine andere Post-Option aus", title: "Kein YouTube Link")
        }
    }
    
    
    func uploadTheData(postRef: DocumentReference, userID: String, dataDictionary: [String: Any]) {
        
        let documentID = postRef.documentID
        
        var userRef: DocumentReference?
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        
        if postAnonymous {
            userRef = db.collection("AnonymousPosts").document(documentID)
        } else {
            userRef = db.collection("Users").document(userID).collection("posts").document(documentID)
        }
        
        var data = dataDictionary
        data["notificationRecipients"] = [userID]   //So he can set notifications off in his own post
        
        if let location = linkedLocation {
            data["locationName"] = location.title
            let geoPoint = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            data["locationCoordinate"] = geoPoint
        }
        
        if let fact = self.linkedFact { // If there is a fact that should be linked to this post, and append its ID to the array
            data["linkedFactID"] = fact.documentID
            
            // Add the post to the specific fact, so that it can be looked into
            
            if language == .english {
                collectionRef = self.db.collection("Data").document("en").collection("topics")
            } else {
                collectionRef = self.db.collection("Facts")
            }
            
            let topicRef = collectionRef.document(fact.documentID).collection("posts").document(documentID)
            
            var data: [String: Any] = ["createTime": self.getDate()]
            
            if self.comingFromAddOnVC || postOnlyInTopic {
                data["type"] = "topicPost"  // To fetch in a different ref when loading the posts of the topic
            }
            
            topicRef.setData(data) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    print("FactReference successfully added")
                }
            }
        }
        
        if userID == anonymousString {
            if let anonymousName = anonymousName {
                // Add the anonymousName, set in the alert, to the array
                data["anonymousName"] = anonymousName
            }
        }
        
        postRef.setData(data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
                // Inform User
            } else {
                if let userRef = userRef {
                    
                    var data: [String: Any] = ["createTime": self.getDate()]
                    
                    if language == .english {
                        data["language"] = "en"
                    }
                    
                    if self.postAnonymous {
                        if let user = Auth.auth().currentUser {
                            data["originalPoster"] = user.uid
                            
                            userRef.setData(data)
                        }
                    } else {
                        if self.comingFromAddOnVC || self.postOnlyInTopic {
                            data["isTopicPost"] = true  // To fetch in a different ref when loading the posts of the topic
                        }
                        userRef.setData(data)      // add the post to the user
                    }
                }
                if self.camPic { // To Save on your device, not the best solution though
                    if let selectedImage = self.selectedImageFromPicker {
                        UIImageWriteToSavedPhotosAlbum(selectedImage, nil, nil, nil)
                    }
                }
                
                if self.comingFromAddOnVC {
                    let post = Post()
                    post.documentID = documentID
                    post.isTopicPost = true  // To fetch in a different ref when loading the posts of the topic
                    
                    self.presentAlert(post: post)
                } else {
                    self.presentAlert(post: nil)
                }
            }
        }
    }
    
    func uploadTheEvent(userID: String, dataDictionary: [String:Any]) {
        let eventRef = db.collection("Events").document()
        let documentID = eventRef.documentID
        
        let userRef = db.collection("Users").document(userID).collection("events").document(documentID)
        
        userRef.setData(["createTime": getDate()])      // add event to User
        
        eventRef.setData(dataDictionary) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if self.camPic { // Um es auf in dem Handy-Photo Ordner zu speichern Geht besser :/
                    if let selectedImage = self.selectedImageFromPicker {
                        UIImageWriteToSavedPhotosAlbum(selectedImage, nil, nil, nil)
                    }
                }
                
                self.presentAlert(post: nil)
            }
        }
        
    }
    
    func presentAlert(post: Post?) {
        
        
        if self.comingFromAddOnVC {
            if let addOn = addOn, let post = post {
                addOn.delegate = self
                addOn.saveItem(item: post)
            }
        } else {
            // remove ActivityIndicator incl. backgroundView
            self.view.activityStopAnimating()
            self.shareButton.isEnabled = true
            
            let alert = UIAlertController(title: "Done!", message: NSLocalizedString("message_after_done_posting", comment: "thanks"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                
                self.descriptionView.descriptionTextView.text.removeAll()
                self.linkView.linkTextField.text?.removeAll()
                self.titleView.titleTextView.text?.removeAll()
                self.previewPictures.removeAll()
                self.pictureView.previewCollectionView.reloadData()
                
                self.pictureView.removePictureButton.alpha = 0
                self.pictureView.removePictureButton.isEnabled = false
                
                self.titleView.characterCountLabel.text = "200"
                self.pictureViewHeight!.constant = 100
                
                if self.optionViewHeight?.constant != self.defaultOptionViewHeight {
                    self.optionButtonTapped()
                }
                self.addedFactDescriptionLabel.text?.removeAll()
                self.addedFactImageView.image = nil
                self.addedFactImageView.layer.borderColor = UIColor.clear.cgColor
                self.cancelLinkedFactTapped()
                
                self.titleView.titleTextView.resignFirstResponder()
                self.descriptionView.descriptionTextView.resignFirstResponder()
                self.linkView.linkTextField.resignFirstResponder()
                
                
                
                Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.donePosting), userInfo: nil, repeats: false)
                
            }))
            self.present(alert, animated: true) {
            }
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
        
        if #available(iOS 13.0, *) {
            label.textColor = .label
        } else {
            label.textColor = .black
        }
        
        infoView!.addSubview(label)
        
        if let window = UIApplication.shared.keyWindow {
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
            
            self.distributionInformationLabel.text = "Community"
            self.distributionInformationImageView.image = UIImage(named: "topicIcon")
            self.postOnlyInTopic = true
            
        }))
        
        self.present(shareAlert, animated: true, completion: nil)
    }
    
    func getTagsToSave() -> [String] {
        // Detect the nouns in the title and save them to Firebase in an array. We cant really search in Firebase, but we search through an array, so that way we can at least give the search function in the feedtableviewcontroller some functionality
        var tags = [String]()
        guard let title = titleView.titleTextView.text else { return [""] }
        
        let tagger = NSLinguisticTagger(tagSchemes: [.lexicalClass], options: 0)
        tagger.string = title
        let range = NSRange(location: 0, length: title.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange, _ in
            if let tag = tag {
                let word = (title as NSString).substring(with: tokenRange)
                print("\(word): \(tag)")
                
                if tag == NSLinguisticTag(rawValue: "Noun") {
                    tags.append(word)
                }
            }
        }
        return tags
    }
    
    func getReportString() -> String {
        switch reportType {
        case .normal:
            return "normal"
        case .opinion:
            return "opinion"
        case .sensationalism:
            return "sensationalism"
        case .edited:
            return "edited"
        default:
            return "normal"
        }
    }
    
    func getEventTypeString() -> String {
        switch eventType {
        case .activity:
            return "activity"
        case .project:
            return "project"
        case .event:
            return "event"
        }
    }
}

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

extension NewPostViewController: ChoosenLocationDelegate {
    func gotLocation(location: Location) {
        self.linkedLocation = location
        self.choosenLocationLabel.text = location.title
    }
}

extension NewPostViewController: LinkFactWithPostDelegate {
    
    func selectedFact(fact: Community, isViewAlreadyLoaded: Bool) {    // Link Fact with post - When posting, from postsOfFactTableVC and from OptionalInformationTableVC
        
        self.linkedFact = fact
        
        if isViewAlreadyLoaded {  // Means it is coming from the selection of a topic to link with, so the view is already loaded, so it doesnt crash
            showLinkedFact(fact: fact)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { //I know, I know
                self.showShareAlert()
            }
        }
    }
    
    func showLinkedFact(fact: Community) {
        
        addFactButton.isHidden = true
        cancelLinkedFactButton.isHidden = false
        
        linkedFactView.addSubview(addedFactImageView)
        addedFactImageView.centerYAnchor.constraint(equalTo: linkedFactView.centerYAnchor, constant: 10).isActive = true
        addedFactImageView.heightAnchor.constraint(equalToConstant: defaultOptionViewHeight-15).isActive = true
        addedFactImageView.trailingAnchor.constraint(equalTo: cancelLinkedFactButton.leadingAnchor, constant: -10).isActive = true
        addedFactImageView.widthAnchor.constraint(equalToConstant: defaultOptionViewHeight-15).isActive = true
        
        linkedFactView.addSubview(addedFactDescriptionLabel)
        addedFactDescriptionLabel.centerYAnchor.constraint(equalTo: addedFactImageView.centerYAnchor).isActive = true
        addedFactDescriptionLabel.trailingAnchor.constraint(equalTo: addedFactImageView.leadingAnchor, constant: -10).isActive = true
//        addedFactDescriptionLabel.leadingAnchor.constraint(equalTo: addFactButton.trailingAnchor, constant: -2).isActive = true
        
        if let url = URL(string: fact.imageURL) {
            addedFactImageView.sd_setImage(with: url, completed: nil)
        } else {
            addedFactImageView.image = UIImage(named: "FactStamp")
        }
         
        addedFactDescriptionLabel.text = "'\(fact.title)'"
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

//MARK: - PreviewCollectionView
extension NewPostViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return previewPictures.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let image = previewPictures[indexPath.item]
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? MultiImageCollectionCell {
            
            cell.image = image
            cell.layoutIfNeeded()
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let size = CGSize(width: pictureView.previewCollectionView.frame.width, height: pictureView.previewCollectionView.frame.height)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let image = previewPictures[indexPath.item]
        
        let pinchVC = PinchToZoomViewController()
        pinchVC.image = image
        pinchVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(pinchVC, animated: true)
    }
    
    //If we implement a pageControl
    //        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    //            if let indexPath = collectionView.indexPathsForVisibleItems.first {
    //                pageControl.currentPage = indexPath.row
    //            }
    //        }
}
