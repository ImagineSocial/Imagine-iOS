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

enum PostSelection {
    case picture
    case link
    case thought
    case event
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

class NewPostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var postSelectionSegmentedControl: UISegmentedControl!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var headerView: UIView!
    
    var imagePicker = UIImagePickerController()
    var multiImagePicker = ImagePickerController()
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
    let characterLimitForTitle = 200
    let characterLimitForEventTitle = 100
    let defaultOptionViewHeight: CGFloat = 45
    
    let infoButtonSize: CGFloat = 22
    
    var up = false
    
    var linkedFact: Fact?
    var linkedLocation: Location?
    
    var comingFromPostsOfFact = false
    var comingFromAddOnVC = false   // This will create a difference reference for the post to be stored, to show it just in the topic and not in the main feed - later it will show up for those who follow this topic
    var addItemDelegate: AddItemDelegate?
    var postOnlyInTopic = false
    
    var pictureViewHeight: NSLayoutConstraint?
    var linkViewHeight: NSLayoutConstraint?
    var eventViewHeight: NSLayoutConstraint?
    var locationViewHeight: NSLayoutConstraint?
    var optionViewHeight: NSLayoutConstraint?
    var stackViewHeight: NSLayoutConstraint?
    
    var descriptionViewTopAnchor: NSLayoutConstraint?
    var pictureViewTopAnchor: NSLayoutConstraint?
    
    var delegate: JustPostedDelegate?
    var newInstanceDelegate: NewFactDelegate?
    
    var infoView: UIView?
    
    var markPostTipView: EasyTipView?
    var postLinkTipView: EasyTipView?
    var linkedFactTipView: EasyTipView?
    var postAnonymousTipView: EasyTipView?
    var linkFactExplanationTipView: EasyTipView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewCollectionView.register(UINib(nibName: "MultiPictureCollectionCell", bundle: nil), forCellWithReuseIdentifier: identifier)
        
        previewCollectionView.dataSource = self
        previewCollectionView.delegate = self
        
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        previewCollectionView.setCollectionViewLayout(layout, animated: true)
        
        let options = multiImagePicker.settings
        options.selection.max = 3
        
        imagePicker.delegate = self
        titleTextView.delegate = self
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        linkTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        
        setCompleteUIForThought()
        setPictureViewUI()
        setLinkViewUI()
        setUpOptionViewUI() // Shows linked Fact in here, if there is one
        
//        setEventViewUI()
//        setLocationViewUI()
        
        if comingFromPostsOfFact || comingFromAddOnVC {
            setDismissButton()
            cancelLinkedFactButton.isEnabled = false
            cancelLinkedFactButton.alpha = 0.5
            distributionInformationLabel.text = "Community"
        }
        
        let font: [AnyHashable : Any] = [NSAttributedString.Key.font : UIFont(name: "IBMPlexSans", size: 15) as Any]
        markPostSegmentControl.setTitleTextAttributes(font as? [NSAttributedString.Key : Any], for: .normal)
        markPostSegmentControl.tintColor = .imagineColor
        postSelectionSegmentedControl.tintColor = .imagineColor
        postSelectionSegmentedControl.setTitleTextAttributes(font as? [NSAttributedString.Key : Any], for: .normal)
        
        //KeyboardGoesUp
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
   
    override func viewWillDisappear(_ animated: Bool) {
        if let view = infoView {
            view.removeFromSuperview()
        }
        self.removeTipViews()
    }
    override func viewWillAppear(_ animated: Bool) {
        self.infoView = nil
        showInfoView()
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
                self.linkLabel.alpha = 1
                self.linkTextField.alpha = 1
                self.webImageViewStackView.alpha = 1
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
                self.cameraButton.alpha = 1
                self.folderButton.alpha = 1
                self.pictureLabel.alpha = 1
            }, completion: { (_) in
                self.postSelectionSegmentedControl.isEnabled = true
            })
        }
    }
    
    func insertUIForEvent() {
        self.descriptionViewTopAnchor!.isActive = false
        
        
        if let pictureTop = pictureViewTopAnchor {
            pictureTop.isActive = false
        }
        
        self.pictureViewTopAnchor = pictureView.topAnchor.constraint(equalTo: locationView.bottomAnchor, constant: 1)
        self.pictureViewTopAnchor!.isActive = true
        
        self.descriptionViewTopAnchor! = descriptionView.topAnchor.constraint(equalTo: pictureView.bottomAnchor, constant: 1)
        self.descriptionViewTopAnchor!.isActive = true
        
        self.eventViewHeight!.constant = 50
        self.pictureViewHeight!.constant = 100
        self.locationViewHeight!.constant = 50
        
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
            
            self.markPostSegmentControl.setTitle("Veranstaltung", forSegmentAt: 0)
            self.markPostSegmentControl.setTitle("Projekt", forSegmentAt: 1)
            self.markPostSegmentControl.setTitle("Event", forSegmentAt: 2)
            
            self.markPostSwitch.alpha = 0
            self.markPostLabel.alpha = 0
            self.markPostSegmentControl.alpha = 1
            
        }) { (_) in
            self.markPostSegmentControl.isHidden = false
            
            UIView.animate(withDuration: 0.1, animations: {
                self.timeLabel.alpha = 1
                self.dateLabel.alpha = 1
                self.setTimeButton.alpha = 1
                
                self.locationTextField.alpha = 1
                self.locationLabel.alpha = 1
                
                self.cameraButton.alpha = 1
                self.folderButton.alpha = 1
                self.pictureLabel.alpha = 1
                
            }, completion: { (_) in
                self.postSelectionSegmentedControl.isEnabled = true
                self.markPostSwitch.isHidden = true
                self.markPostLabel.isHidden = true
            })
        }
    }
    
    // MARK: - TitleViewUI
    let titleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Titel:"
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        
        return label
    }()
    
    let characterCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "200"
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 11)
        
        return label
    }()
    
    let titleTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont(name: "IBMPlexSans", size: 14)
        textView.returnKeyType = UIReturnKeyType.next
        textView.enablesReturnKeyAutomatically = true
        
        return textView
    }()
    
    func setTitleViewUI() {
        titleView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: titleView.topAnchor, constant: 5).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: titleView.leadingAnchor, constant: 10).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        titleView.addSubview(characterCountLabel)
        characterCountLabel.trailingAnchor.constraint(equalTo: titleView.trailingAnchor, constant: -5).isActive = true
        characterCountLabel.bottomAnchor.constraint(equalTo: titleView.bottomAnchor).isActive = true
        characterCountLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        titleView.addSubview(titleTextView)
        titleTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        titleTextView.leadingAnchor.constraint(equalTo: titleView.leadingAnchor, constant: 10).isActive = true
        titleTextView.trailingAnchor.constraint(equalTo: titleView.trailingAnchor, constant: -10).isActive = true
        titleTextView.bottomAnchor.constraint(equalTo: characterCountLabel.topAnchor).isActive = true
        
        self.view.addSubview(titleView)
        titleView.topAnchor.constraint(equalTo: postSelectionSegmentedControl.bottomAnchor, constant: 5).isActive = true
        titleView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        titleView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        titleView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
    }
    
    
    
    // MARK: - DescriptionViewUI
    let descriptionView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        return view
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("decriptionLabelText", comment: "...:")
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        
        return label
    }()
    
    let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont(name: "IBMPlexSans", size: 14)
        
        return textView
    }()
    
    func setDescriptionViewUI() {   // have to set descriptionview topanchor
        descriptionView.addSubview(descriptionLabel)
        descriptionLabel.topAnchor.constraint(equalTo: descriptionView.topAnchor, constant: 5).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: descriptionView.leadingAnchor, constant: 10).isActive = true
        descriptionLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        descriptionView.addSubview(descriptionTextView)
        descriptionTextView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor).isActive = true
        descriptionTextView.leadingAnchor.constraint(equalTo: descriptionView.leadingAnchor, constant: 10).isActive = true
        descriptionTextView.trailingAnchor.constraint(equalTo: descriptionView.trailingAnchor, constant: -10).isActive = true
        descriptionTextView.bottomAnchor.constraint(equalTo: descriptionView.bottomAnchor).isActive = true
        
        self.view.addSubview(descriptionView)
        descriptionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        descriptionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        descriptionView.heightAnchor.constraint(equalToConstant: 110).isActive = true
    }
    
    
    
    // MARK: - LinkViewUI
    let linkView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        return view
    }()
    
    let linkLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Link:"
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        label.alpha = 0
        
        return label
    }()
    
    let linkTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .none
        textField.placeholder = "Link: https://..."
        textField.alpha = 0
        
        return textField
    }()
    
    let youTubeImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "YouTubeButtonIcon")
        imageView.contentMode = .scaleAspectFit
        if #available(iOS 13.0, *) {
            imageView.tintColor = .secondaryLabel
        } else {
            imageView.tintColor = .black
        }
        imageView.alpha = 0.4
        
        return imageView
    }()
    
    let GIFImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "GIFIcon")
        imageView.contentMode = .scaleAspectFit
        if #available(iOS 13.0, *) {
            imageView.tintColor = .secondaryLabel
        } else {
            imageView.tintColor = .black
        }
        imageView.alpha = 0.4
        
        return imageView
    }()
    
    let songWhipImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "MusicIcon")
        imageView.contentMode = .scaleAspectFit
        if #available(iOS 13.0, *) {
            imageView.tintColor = .secondaryLabel
        } else {
            imageView.tintColor = .black
        }
        imageView.alpha = 0.4
        
        return imageView
    }()
    
    let internetImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "translate")
        imageView.contentMode = .scaleAspectFill
        if #available(iOS 13.0, *) {
            imageView.tintColor = .secondaryLabel
        } else {
            imageView.tintColor = .black
        }
        imageView.alpha = 0.4
        
        return imageView
    }()
    
    let linkInfoButton: DesignableButton = {
        let button = DesignableButton(type: .detailDisclosure)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(linkInfoButtonTapped), for: .touchUpInside)
        button.alpha = 0
        
        return button
    }()
    
    let webImageViewStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        stackView.clipsToBounds = true
        stackView.alpha = 0
        
        return stackView
    }()
    
    func setLinkViewUI() {   // have to set descriptionview topanchor
        linkView.addSubview(linkLabel)
        linkLabel.topAnchor.constraint(equalTo: linkView.topAnchor, constant: 7).isActive = true
        linkLabel.leadingAnchor.constraint(equalTo: linkView.leadingAnchor, constant: 10).isActive = true
        linkLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        webImageViewStackView.addArrangedSubview(internetImageView)
        webImageViewStackView.addArrangedSubview(youTubeImageView)
        webImageViewStackView.addArrangedSubview(GIFImageView)
        webImageViewStackView.addArrangedSubview(songWhipImageView)
        
        internetImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        internetImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        youTubeImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        youTubeImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        GIFImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        GIFImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        songWhipImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        songWhipImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        
        linkView.addSubview(webImageViewStackView)
        webImageViewStackView.trailingAnchor.constraint(equalTo: linkView.trailingAnchor, constant: -10).isActive = true
        webImageViewStackView.centerYAnchor.constraint(equalTo: linkLabel.centerYAnchor).isActive = true
        webImageViewStackView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        webImageViewStackView.widthAnchor.constraint(equalToConstant: 110).isActive = true
        
        linkView.addSubview(linkInfoButton)
        linkView.addSubview(linkTextField)
        
        linkInfoButton.centerYAnchor.constraint(equalTo: linkTextField.centerYAnchor).isActive = true
        linkInfoButton.trailingAnchor.constraint(equalTo: linkView.trailingAnchor, constant: -10).isActive = true
        linkInfoButton.heightAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        linkInfoButton.widthAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        
        linkTextField.topAnchor.constraint(equalTo: linkLabel.bottomAnchor, constant: 10).isActive = true
        linkTextField.leadingAnchor.constraint(equalTo: linkView.leadingAnchor, constant: 10).isActive = true
        linkTextField.trailingAnchor.constraint(equalTo: linkInfoButton.leadingAnchor, constant: -5).isActive = true
        linkTextField.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.view.addSubview(linkView)
        linkView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 1).isActive = true
        linkView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        linkView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.linkViewHeight = linkView.heightAnchor.constraint(equalToConstant: 0)
        self.linkViewHeight!.isActive = true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text {
            
            internetImageView.alpha = 0.4
            youTubeImageView.alpha = 0.4
            songWhipImageView.alpha = 0.4
            GIFImageView.alpha = 0.4
            
            if text.isValidURL {
                if let _ = text.youtubeID {
                    youTubeImageView.alpha = 1
                } else if text.contains("songwhip.com") {
                    songWhipImageView.alpha = 1
                } else if text.contains(".mp4") {
                    GIFImageView.alpha = 1
                    print("Got mp4")
                } else {
                    internetImageView.alpha = 1
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
    let pictureView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        return view
    }()
    
    let pictureLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("pictureLabelText", comment: "picture:")
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        label.alpha = 0
        
        return label
    }()
    
    let cameraButton :DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "camera"), for: .normal)
        button.addTarget(self, action: #selector(camTapped), for: .touchUpInside)
        button.alpha = 0
        if #available(iOS 13.0, *) {
            button.tintColor = .label
        } else {
            button.tintColor = .black
        }
        
        return button
    }()
    
    let folderButton :DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "folder"), for: .normal)
        button.addTarget(self, action: #selector(CamRollTapped), for: .touchUpInside)
        button.alpha = 0
        if #available(iOS 13.0, *) {
            button.tintColor = .label
        } else {
            button.tintColor = .black
        }
        
        return button
    }()
    
    let removePictureButton :DesignableButton = {
       let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "DismissTemplate"), for: .normal)
        button.alpha = 0
        button.tintColor = .systemRed
        button.backgroundColor = .white
        button.cornerRadius = 9
        button.addTarget(self, action: #selector(removePictureTapped), for: .touchUpInside)
        
        return button
    }()
    
    
    
    let previewCollectionView: UICollectionView = {
       let collectView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())
        collectView.translatesAutoresizingMaskIntoConstraints = false
        collectView.allowsSelection = true  //Pictures clickable
        collectView.layer.cornerRadius = 8
        collectView.isPagingEnabled = true
        if #available(iOS 13.0, *) {
            collectView.backgroundColor = .systemBackground
        } else {
            collectView.backgroundColor = .white
        }
        
        return collectView
    }()
    
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
        pictureView.addSubview(pictureLabel)
        pictureLabel.topAnchor.constraint(equalTo: pictureView.topAnchor, constant: 5).isActive = true
        pictureLabel.leadingAnchor.constraint(equalTo: pictureView.leadingAnchor, constant: 10).isActive = true
        pictureLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        pictureView.addSubview(cameraButton)
        cameraButton.topAnchor.constraint(equalTo: pictureView.topAnchor, constant: 15).isActive = true
        cameraButton.leadingAnchor.constraint(equalTo: pictureLabel.trailingAnchor, constant: 25).isActive = true
        cameraButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        cameraButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        pictureView.addSubview(folderButton)
        folderButton.bottomAnchor.constraint(equalTo: pictureView.bottomAnchor, constant: -10).isActive = true
        folderButton.leadingAnchor.constraint(equalTo: cameraButton.leadingAnchor).isActive = true
        folderButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        folderButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        pictureView.addSubview(previewCollectionView)
        previewCollectionView.topAnchor.constraint(equalTo: pictureView.topAnchor).isActive = true
//        previewCollectionView.trailingAnchor.constraint(equalTo: pictureView.trailingAnchor, constant: -50).isActive = true
        previewCollectionView.leadingAnchor.constraint(equalTo: cameraButton.trailingAnchor, constant: 75).isActive = true
        previewCollectionView.widthAnchor.constraint(equalToConstant: 125).isActive = true
        previewCollectionView.bottomAnchor.constraint(equalTo: pictureView.bottomAnchor).isActive = true
        
        pictureView.addSubview(removePictureButton)
        removePictureButton.topAnchor.constraint(equalTo: previewCollectionView.topAnchor, constant: -5).isActive = true
        removePictureButton.trailingAnchor.constraint(equalTo: previewCollectionView.trailingAnchor, constant: 5).isActive = true
        removePictureButton.widthAnchor.constraint(equalToConstant: 18).isActive = true
        removePictureButton.heightAnchor.constraint(equalToConstant: 18).isActive = true
        
        self.view.addSubview(pictureView)
        pictureView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        pictureView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.pictureViewHeight = pictureView.heightAnchor.constraint(equalToConstant: 0)
        self.pictureViewHeight!.isActive = true
        self.pictureViewTopAnchor = pictureView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 1)
        self.pictureViewTopAnchor!.isActive = true
    }
    
    // MARK: - EventViewUI
    let eventView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        return view
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Zeit:"
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        label.alpha = 0
        
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = ""
        label.font = UIFont(name: "IBMPlexSans", size: 14)
        label.alpha = 0
        label.textAlignment = .center
        
        return label
    }()
    
    let setTimeButton :DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(timeButtonTapped), for: .touchUpInside)
        button.setTitle("Zeit einstellen", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 3
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1
        button.clipsToBounds = true
        button.alpha = 0
        
        return button
    }()
    
    let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .dateAndTime
        picker.alpha = 0
        
        return picker
    }()
    
    func setEventViewUI() {
        eventView.addSubview(datePicker)
        datePicker.topAnchor.constraint(equalTo: eventView.topAnchor).isActive = true
        datePicker.trailingAnchor.constraint(equalTo: eventView.trailingAnchor).isActive = true
        datePicker.leadingAnchor.constraint(equalTo: eventView.leadingAnchor).isActive = true
        datePicker.bottomAnchor.constraint(equalTo: eventView.bottomAnchor, constant: -30).isActive = true
        
        eventView.addSubview(timeLabel)
        timeLabel.topAnchor.constraint(equalTo: eventView.topAnchor, constant: 5).isActive = true
        timeLabel.leadingAnchor.constraint(equalTo: eventView.leadingAnchor, constant: 10).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        eventView.addSubview(setTimeButton)
//        setTimeButton.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 5).isActive = true
        setTimeButton.bottomAnchor.constraint(equalTo: eventView.bottomAnchor, constant: -10).isActive = true
        setTimeButton.trailingAnchor.constraint(equalTo: eventView.trailingAnchor, constant: -15).isActive = true
        setTimeButton.widthAnchor.constraint(equalToConstant: 130).isActive = true
        setTimeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        eventView.addSubview(dateLabel)
        dateLabel.trailingAnchor.constraint(equalTo: setTimeButton.leadingAnchor, constant: 10).isActive = true
        dateLabel.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 10).isActive = true
        dateLabel.bottomAnchor.constraint(equalTo: eventView.bottomAnchor, constant: -10).isActive = true
        
        self.view.addSubview(eventView)
        eventView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 1).isActive = true
        eventView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        eventView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.eventViewHeight = eventView.heightAnchor.constraint(equalToConstant: 0)
        self.eventViewHeight!.isActive = true
    }
    
    
    // MARK: - EventLocationViewUI
    let locationView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        return view
    }()
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Location:"
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        label.alpha = 0
        
        return label
    }()
    
    let locationTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .none
        textField.placeholder = "Neuersberg, An der Mühle 13..."
        textField.alpha = 0
        
        return textField
    }()
    
    func setLocationViewUI() {
        locationView.addSubview(locationLabel)
        locationLabel.topAnchor.constraint(equalTo: locationView.topAnchor, constant: 5).isActive = true
        locationLabel.leadingAnchor.constraint(equalTo: locationView.leadingAnchor, constant: 10).isActive = true
        locationLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        locationView.addSubview(locationTextField)
        locationTextField.topAnchor.constraint(equalTo: locationLabel.bottomAnchor).isActive = true
        locationTextField.leadingAnchor.constraint(equalTo: locationView.leadingAnchor, constant: 10).isActive = true
        locationTextField.trailingAnchor.constraint(equalTo: locationView.trailingAnchor, constant: -10).isActive = true
        locationTextField.bottomAnchor.constraint(equalTo: locationView.bottomAnchor).isActive = true
        
        self.view.addSubview(locationView)
        locationView.topAnchor.constraint(equalTo: eventView.bottomAnchor, constant: 1).isActive = true
        locationView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        locationView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.locationViewHeight = locationView.heightAnchor.constraint(equalToConstant: 0)
        self.locationViewHeight!.isActive = true
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
    
    //MARK: - Link Fact with Post UI
    
    let addFactButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.setTitle("Community verlinken", for: .normal)
        button.addTarget(self, action: #selector(linkFactToPostTapped), for: .touchUpInside)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
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
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        label.textAlignment = .left
        label.text = "Ziel:"
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
    
    //Location
    let locationDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("location_label_text", comment: "location:")
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        
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
        let labelHeight: CGFloat = 20
        
        //LocationView
        linkedLocationView.addSubview(locationDescriptionLabel)
        locationDescriptionLabel.topAnchor.constraint(equalTo: linkedLocationView.topAnchor, constant: 5).isActive = true
        locationDescriptionLabel.leadingAnchor.constraint(equalTo: linkedLocationView.leadingAnchor, constant: 10).isActive = true
        locationDescriptionLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true
        
        linkedLocationView.addSubview(linkedLocationImageView)
        linkedLocationImageView.centerYAnchor.constraint(equalTo: linkedLocationView.centerYAnchor, constant: labelHeight/2).isActive = true
        linkedLocationImageView.leadingAnchor.constraint(equalTo: linkedLocationView.leadingAnchor, constant: 14).isActive = true
        linkedLocationImageView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        linkedLocationImageView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        
        linkedLocationView.addSubview(choosenLocationLabel)
        choosenLocationLabel.centerYAnchor.constraint(equalTo: linkedLocationImageView.centerYAnchor).isActive = true
        choosenLocationLabel.leadingAnchor.constraint(equalTo: locationDescriptionLabel.trailingAnchor, constant: 10).isActive = true
        
        linkedLocationView.addSubview(chooseLocationButton)
        chooseLocationButton.leadingAnchor.constraint(equalTo: choosenLocationLabel.trailingAnchor, constant: 20).isActive = true
        chooseLocationButton.trailingAnchor.constraint(equalTo: linkedLocationView.trailingAnchor, constant: -10).isActive = true
        chooseLocationButton.centerYAnchor.constraint(equalTo: choosenLocationLabel.centerYAnchor).isActive = true
        chooseLocationButton.heightAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        chooseLocationButton.widthAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        
        self.view.addSubview(linkedLocationView)
        linkedLocationView.topAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: 1).isActive = true
        linkedLocationView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        linkedLocationView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        linkedLocationView.heightAnchor.constraint(equalToConstant: defaultOptionViewHeight+labelHeight).isActive = true
        
        //LinkedFactView
        linkedFactView.addSubview(distributionLabel)
        distributionLabel.topAnchor.constraint(equalTo: linkedFactView.topAnchor, constant: 5).isActive = true
        distributionLabel.leadingAnchor.constraint(equalTo: linkedFactView.leadingAnchor, constant: 10).isActive = true
        distributionLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true

        linkedFactView.addSubview(linkedFactInfoButton)
        linkedFactInfoButton.centerYAnchor.constraint(equalTo: linkedFactView.centerYAnchor, constant: labelHeight/2).isActive = true
        linkedFactInfoButton.trailingAnchor.constraint(equalTo: linkedFactView.trailingAnchor, constant: -10).isActive = true
        linkedFactInfoButton.widthAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        linkedFactInfoButton.heightAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        
        linkedFactView.addSubview(addFactButton)
        addFactButton.centerYAnchor.constraint(equalTo: linkedFactView.centerYAnchor, constant: labelHeight/2).isActive = true
        addFactButton.trailingAnchor.constraint(equalTo: linkedFactInfoButton.leadingAnchor, constant: -20).isActive = true
//        addFactButton.centerXAnchor.constraint(equalTo: linkedFactView.centerXAnchor).isActive = true
        addFactButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        distributionInformationView.addSubview(distributionInformationImageView)
        distributionInformationImageView.leadingAnchor.constraint(equalTo: distributionInformationView.leadingAnchor).isActive = true
        distributionInformationImageView.centerYAnchor.constraint(equalTo: distributionInformationView.centerYAnchor).isActive = true
        distributionInformationImageView.widthAnchor.constraint(equalToConstant: 25).isActive = true
        distributionInformationImageView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        distributionInformationView.addSubview(distributionInformationLabel)
        distributionInformationLabel.leadingAnchor.constraint(equalTo: distributionInformationImageView.trailingAnchor, constant: 2).isActive = true
        distributionInformationLabel.trailingAnchor.constraint(equalTo: distributionInformationView.trailingAnchor, constant: -3).isActive = true
        distributionInformationLabel.centerYAnchor.constraint(equalTo: distributionInformationView.centerYAnchor).isActive = true
        
        linkedFactView.addSubview(distributionInformationView)
        distributionInformationView.leadingAnchor.constraint(equalTo: linkedFactView.leadingAnchor, constant: 10).isActive = true
//        distributionInformationView.trailingAnchor.constraint(equalTo: addFactButton.leadingAnchor, constant: -3).isActive = true
        distributionInformationView.centerYAnchor.constraint(equalTo: linkedFactView.centerYAnchor, constant: labelHeight/2).isActive = true
        distributionInformationView.heightAnchor.constraint(equalToConstant: defaultOptionViewHeight-15).isActive = true

        linkedFactView.addSubview(cancelLinkedFactButton)
        cancelLinkedFactButton.trailingAnchor.constraint(equalTo: linkedFactInfoButton.leadingAnchor, constant: -10).isActive = true
        cancelLinkedFactButton.widthAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        cancelLinkedFactButton.heightAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        cancelLinkedFactButton.centerYAnchor.constraint(equalTo: linkedFactView.centerYAnchor, constant: labelHeight/2).isActive = true
        
        self.view.addSubview(linkedFactView)
        linkedFactView.topAnchor.constraint(equalTo: linkedLocationView.bottomAnchor, constant: 1).isActive = true
        linkedFactView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        linkedFactView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        linkedFactView.heightAnchor.constraint(equalToConstant: defaultOptionViewHeight+labelHeight).isActive = true
        
        
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
        
        explainFunctionOnFirstOpen()
    }
    
    //MARK:-PostAsSomebodyElse-UI
    //Just for Yvonne, Sophie and Malte
    
    
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
                if descriptionTextView.isFirstResponder {
                    
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
                    case .event:
                        offset = 175
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
            case .event:
                offset = 175
            }
            
            self.view.frame.origin.y += offset
            self.up = false
        }
    }
    
    // MARK: - Functions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTextView.resignFirstResponder()
        linkTextField.resignFirstResponder()
        descriptionTextView.resignFirstResponder()
        
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
    
    // Geht einfacher
    func getDate() -> Timestamp {
        let date = Date()
        return Timestamp(date: date)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if textView == titleTextView {  // No lineBreaks in titleTextView
            guard text.rangeOfCharacter(from: CharacterSet.newlines) == nil else {
                return descriptionTextView.becomeFirstResponder()   // Switch to description when "continue" is hit on keyboard
            }
        }
        
        switch selectedOption { // Title no longer than x characters
        case .event:
            return textView.text.count + (text.count - range.length) <= characterLimitForEventTitle  // Text no longer than 100 characters
        default:
            return textView.text.count + (text.count - range.length) <= characterLimitForTitle
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        switch selectedOption {
        case .event:
            let characterLeft = characterLimitForEventTitle-textView.text.count
            self.characterCountLabel.text = String(characterLeft)
        default:
            let characterLeft = characterLimitForTitle-textView.text.count
            self.characterCountLabel.text = String(characterLeft)
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
            self.linkFactExplanationTipView!.show(forView: self.linkedFactView)
        }
    }
    
    //MARK: - Buttons & Stuff
    
    @objc func camTapped() {
        if let _ = Auth.auth().currentUser {
            imagePicker.sourceType = .camera
            imagePicker.cameraCaptureMode = .photo
            imagePicker.cameraDevice = .rear
            imagePicker.cameraFlashMode = .off
            imagePicker.showsCameraControls = true
            
            //imagePicker.allowsEditing = true
            self.present(self.imagePicker, animated: true, completion: nil)
            
        } else {
            self.notLoggedInAlert()
        }
    }
    
    @objc func CamRollTapped() {
        if let _ = Auth.auth().currentUser {
            
            let alert = UIAlertController(title: NSLocalizedString("how_many_pics_alert_header", comment: "How many pics do you want to post?"), message: NSLocalizedString("how_many_pics_alert_message", comment: "How many pics do you want to post?"), preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: NSLocalizedString("how_many_just_one", comment: "just one"), style: .default, handler: { (_) in
                self.imagePicker.sourceType = .photoLibrary
                //imagePicker.allowsEditing = true
                
                self.selectedOption = .picture
                self.present(self.imagePicker, animated: true, completion: nil)
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
            
        } else {
            self.notLoggedInAlert()
        }
    }
    
    @objc func removePictureTapped() {
        
        self.multiImageAssets.removeAll()
        self.previewPictures.removeAll()
        self.previewCollectionView.reloadData()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.removePictureButton.alpha = 0
            self.removePictureButton.isEnabled = true
        }) { (_) in
            self.decreasePictureUI()
            self.selectedImageFromPicker = nil
            self.selectedImagesFromPicker = []
        }
    }
    
    @objc func timeButtonTapped() {
        if selectDate {
            selectDate = false
            UIView.animate(withDuration: 0.1, animations: {
                
                self.datePicker.alpha = 0
            }) { (_) in
                self.eventViewHeight!.constant = 50
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.layoutIfNeeded()
                })
            }
            
            selectedDate = datePicker.date
            if let date = selectedDate {
                
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy, HH:mm"
                let stringDate = formatter.string(from: date)
                
                dateLabel.text = "\(stringDate) Uhr"
            }
            
            setTimeButton.setTitle("Zeit einstellen", for: .normal)
        } else {
            self.eventViewHeight!.constant = 200
            
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
                
            }) { (_) in
                UIView.animate(withDuration: 0.1, animations: {
                    self.datePicker.alpha = 1
                })
            }
            selectDate = true
            setTimeButton.setTitle("Übernehmen", for: .normal)
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
                
        if descriptionTextView.isFirstResponder {
            descriptionTextView.resignFirstResponder()
        } else if titleTextView.isFirstResponder {
            titleTextView.resignFirstResponder()
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
        
        self.postSelectionSegmentedControl.isEnabled = false
        
        switch self.selectedOption {
        case .picture:
            
            //Let the pictureView disappear
            UIView.animate(withDuration: 0.1, animations: {
                self.folderButton.alpha = 0
                self.cameraButton.alpha = 0
                self.pictureLabel.alpha = 0
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
                self.linkLabel.alpha = 0
                self.linkTextField.alpha = 0
                self.webImageViewStackView.alpha = 0
                self.linkInfoButton.alpha = 0
            }) { (_) in
                self.linkViewHeight!.constant = 0
                
                UIView.animate(withDuration: 0.4, animations: {
                    self.view.layoutIfNeeded()
                }) { (_) in
                    self.setTheChange()
                }
            }
        case .event:
            // Let the EventView disappear
            
            markPostSegmentControl.setTitle("Meinung", forSegmentAt: 0)
            markPostSegmentControl.setTitle("Sensation", forSegmentAt: 1)
            markPostSegmentControl.setTitle("Bearbeitet", forSegmentAt: 2)
            
            UIView.animate(withDuration: 0.1, animations: {
                //Date
                self.dateLabel.alpha = 0
                self.timeLabel.alpha = 0
                self.setTimeButton.alpha = 0
                // Location
                self.locationLabel.alpha = 0
                self.locationTextField.alpha = 0
                // TitlePicture
                self.folderButton.alpha = 0
                self.cameraButton.alpha = 0
                self.pictureLabel.alpha = 0
                
            }) { (_) in
                
                self.eventViewHeight!.constant = 0
                self.locationViewHeight!.constant = 0
                self.pictureViewHeight!.constant = 0
                
                UIView.animate(withDuration: 0.4, animations: {
                    self.view.layoutIfNeeded()
                    
                    self.markPostSwitch.alpha = 1
                    self.markPostLabel.alpha = 1
                    self.markPostSegmentControl.alpha = 0
                }) { (_) in
                    self.markPostSwitch.isHidden = false
                    self.markPostLabel.isHidden = false
                    self.markPostSegmentControl.isHidden = true
                    
                    self.pictureLabel.text = "Bild:"
                    self.characterCountLabel.text = "200"
                    
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
        if postSelectionSegmentedControl.selectedSegmentIndex == 4 {
            self.selectedOption = .event
            self.pictureLabel.text = "Titelbild:"
            self.characterCountLabel.text = "100"
            insertUIForEvent()
        }
    }
    
    
    @objc func markPostSegmentChanged() {
        switch selectedOption {
        case .event:
            if markPostSegmentControl.selectedSegmentIndex == 0 {
                eventType = .activity
            }
            if markPostSegmentControl.selectedSegmentIndex == 1 {
                eventType = .project
            }
            if markPostSegmentControl.selectedSegmentIndex == 2 {
                eventType = .event
            }
        default:
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchFactsSegue" {
            if let navCon = segue.destination as? UINavigationController {
                if let factVC = navCon.topViewController as? FactCollectionViewController {
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
    
    //MARK: -SharePressed
    
    @IBAction func sharePressed(_ sender: Any) {
        
        if let user = Auth.auth().currentUser {
            var userID = ""
            
            let postRef: DocumentReference?
            if comingFromAddOnVC || postOnlyInTopic {
                postRef = db.collection("TopicPosts").document()
            } else {
                postRef = db.collection("Posts").document()
            }

            if self.postAnonymous {
                userID = anonymousString
            } else {
                userID = user.uid
            }
            
            if let id = fakeProfileUserID {
                userID = id
            }

            if titleTextView.text != "", let postRef = postRef {
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
                    if let text = linkTextField.text {
                        if text.contains(".mp4") {
                            self.postGIF(postRef: postRef, userID: userID)
                        } else if let _ = text.youtubeID {
                            self.postYTVideo(postRef: postRef, userID: userID)
                        } else {
                            self.postLink(postRef: postRef, userID: userID)
                        }
                    } else {
                        self.alert(message: NSLocalizedString("missing_info_alert_link", comment: "enter link please"))
                    }
                case .event:
                    self.postEvent(postRef: postRef, userID: userID)
                }
            } else {
                self.alert(message: NSLocalizedString("missing_info_alert_title", comment: "enter title pls"))
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    
    // MARK: - MultiImagePicker
    
    func openMultiPictureImagePicker() {
        self.multiImageAssets.removeAll()
        //TODo: change the selection
        self.presentImagePicker(self.multiImagePicker,
                                
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
                        self.previewCollectionView.reloadData()
                        UIView.animate(withDuration: 0.3) {
                            self.removePictureButton.alpha = 1
                            self.removePictureButton.isEnabled = true
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
        
        
        /*if let editedImage = info[.editedImage] as? UIImage {
         selectedImageFromPicker = editedImage
         } else*/
        
        
        if picker.sourceType == .camera {
            self.camPic = true
        }
        if let originalImage = info[.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImageSize = selectedImageFromPicker?.size {
            selectedImageHeight = selectedImageSize.height
            selectedImageWidth = selectedImageSize.width
        }
        
        if let image = selectedImageFromPicker {
            self.increasePictureUI()
            self.previewPictures.removeAll()
            self.previewPictures.append(image)
            self.previewCollectionView.reloadData()
            
            UIView.animate(withDuration: 0.3) {
                self.removePictureButton.alpha = 1
                self.removePictureButton.isEnabled = true
            }
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
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
        
        storageRef.putData(data, metadata: nil, completion: { (metadata, error) in    //Bild speichern
            if let error = error {
                print(error)
                return
            }
            storageRef.downloadURL(completion: { (url, err) in  // Hier wird die URL runtergezogen
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
    
    // MARK: - Upload the post
    
    func postThought(postRef: DocumentReference, userID: String) {
        
        let text = descriptionTextView.text.trimmingCharacters(in: .newlines)
        let descriptionText = text.replacingOccurrences(of: "\n", with: "\\n")  // Just the text of the description has got line breaks
        
        let tags = self.getTagsToSave()
        
        let dataDictionary: [String: Any] = ["title": titleTextView.text, "description": descriptionText, "createTime": getDate(), "originalPoster": userID, "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "type": "thought", "report": getReportString(), "tags": tags]
        
        self.uploadTheData(postRef: postRef, userID: userID, dataDictionary: dataDictionary)
        
        print("thought posted")
    }
    
    func postLink(postRef: DocumentReference, userID: String) {
        if linkTextField.text != "" {
            if linkTextField.text!.isValidURL {
                
                let descriptionText = descriptionTextView.text.replacingOccurrences(of: "\n", with: "\\n")
                let tags = self.getTagsToSave()
                
                let dataDictionary: [String: Any] = ["title": titleTextView.text, "description": descriptionText, "createTime": getDate(), "originalPoster": userID, "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "type": "link", "report": getReportString(), "link": linkTextField.text!, "tags": tags]
                
                self.uploadTheData(postRef: postRef, userID: userID, dataDictionary: dataDictionary)
            } else {
                self.view.activityStopAnimating()
                self.shareButton.isEnabled = true
                self.alert(message: NSLocalizedString("error_link_not_valid", comment: "not valid"), title: NSLocalizedString("error_title", comment: "got error"))
            }
        } else {
            self.view.activityStopAnimating()
            self.shareButton.isEnabled = true
            self.alert(message: NSLocalizedString("error_no_link", comment: "no link"), title: NSLocalizedString("error_title", comment: "got error"))
        }
    }
    
    func postPicture(postRef: DocumentReference, userID: String) {
        if let _ = selectedImageFromPicker, let url = imageURL {
            
            let descriptionText = descriptionTextView.text.replacingOccurrences(of: "\n", with: "\\n")
            let tags = self.getTagsToSave()
            
            let dataDictionary: [String: Any] = ["title": titleTextView.text, "description": descriptionText, "createTime": getDate(), "originalPoster": userID, "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "type": "picture", "report": getReportString(), "imageURL": url, "imageHeight": Double(selectedImageHeight), "imageWidth": Double(selectedImageWidth), "tags": tags]
            
            self.uploadTheData(postRef: postRef, userID: userID, dataDictionary: dataDictionary)
            print("picture posted")
            
        } else {
            self.view.activityStopAnimating()
            self.shareButton.isEnabled = true
            self.alert(message: NSLocalizedString("error_no_picture", comment: "no picture"), title: NSLocalizedString("error_title", comment: "got error"))
        }
    }
    
    func postMultiplePictures(postRef: DocumentReference, userID: String) {
        
        let descriptionText = descriptionTextView.text.replacingOccurrences(of: "\n", with: "\\n")
        let tags = self.getTagsToSave()
        
        let dataDictionary: [String: Any] = ["title": titleTextView.text, "description": descriptionText, "createTime": getDate(), "originalPoster": userID, "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "type": "multiPicture", "report": getReportString(), "imageURLs": self.imageURLs, "imageHeight": Double(selectedImageHeight), "imageWidth": Double(selectedImageWidth), "tags": tags]
        
        self.uploadTheData(postRef: postRef, userID: userID, dataDictionary: dataDictionary)
        print("multiPicture posted")
        
    }
    
    func postGIF(postRef: DocumentReference, userID: String) {
        
        let text = linkTextField.text
        
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
            
            
            let descriptionText = descriptionTextView.text.replacingOccurrences(of: "\n", with: "\\n")
            let tags = self.getTagsToSave()

            let dataDictionary: [String: Any] = ["title": titleTextView.text, "description": descriptionText, "createTime": getDate(), "originalPoster": userID, "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "type": "GIF", "report": getReportString(), "link": link, "tags": tags]

            self.uploadTheData(postRef: postRef, userID: userID, dataDictionary: dataDictionary)

            print("GIF Postet")
            
        }
    }
    
    
    func postYTVideo(postRef: DocumentReference, userID: String) {
        if let _ = linkTextField.text?.youtubeID {  // YouTubeVideo
            
            let descriptionText = descriptionTextView.text.replacingOccurrences(of: "\n", with: "\\n")
            let tags = self.getTagsToSave()
            
            let dataDictionary: [String: Any] = ["title": titleTextView.text, "description": descriptionText, "createTime": getDate(), "originalPoster": userID, "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "type": "youTubeVideo", "report": getReportString(), "link": linkTextField.text!, "tags": tags]
            
            self.uploadTheData(postRef: postRef, userID: userID, dataDictionary: dataDictionary)
            
            print("YouTubeVideo Postet")
        } else {
            self.view.activityStopAnimating()
            self.shareButton.isEnabled = true
            self.alert(message: "Du hast kein Youtube Link angegeben. Möchtest du kein Youtube-Video posten, wähle bitte eine andere Post-Option aus", title: "Kein YouTube Link")
        }
    }
    
    func postEvent(postRef: DocumentReference, userID: String) {
        
        if let date = selectedDate, let locationText = locationTextField.text {
            
            if let url = imageURL {
                let timestamp = Timestamp(date: date)
                let participants: [String] = [userID]
                let tags = self.getTagsToSave()
                
                let descriptionText = descriptionTextView.text.replacingOccurrences(of: "\n", with: "\\n")
                
                let dataDictionary: [String: Any] = ["title": titleTextView.text, "description": descriptionText, "createDate": getDate(), "admin": userID, "location": locationText, "imageURL": url, "imageHeight": Double(selectedImageHeight), "imageWidth": Double(selectedImageWidth), "type": getEventTypeString(), "participants": participants, "time": timestamp, "tags": tags]
                
                self.uploadTheEvent(userID: userID, dataDictionary: dataDictionary)
                
            } else {
                self.view.activityStopAnimating()
                self.shareButton.isEnabled = true
                self.alert(message: "Bitte füge ein Titelbild hinzu, das spricht die Menschen eher an. Danke!", title: "Kein Bild")
            }
        } else {
            self.view.activityStopAnimating()
            self.shareButton.isEnabled = true
            self.alert(message: "Bitte gib Datum und Ort an, wenn du eine Veranstaltung erstellst", title: "Datum oder Ort fehlt")
        }
    }
    
    
    func uploadTheData(postRef: DocumentReference, userID: String, dataDictionary: [String: Any]) {
        
        let documentID = postRef.documentID
        
        var userRef: DocumentReference?
        
        if postAnonymous {
            userRef = db.collection("AnonymousPosts").document(documentID)
        } else {
            userRef = db.collection("Users").document(userID).collection("posts").document(documentID)
        }
        
        var data = dataDictionary
        
        if let fact = self.linkedFact { // If there is a fact that should be linked to this post, and append its ID to the array
            data["linkedFactID"] = fact.documentID
            
            // Add the post to the specific fact, so that it can be looked into
            let ref = db.collection("Facts").document(fact.documentID).collection("posts").document(documentID)
            
            var data: [String: Any] = ["createTime": self.getDate()]
            
            if self.comingFromAddOnVC || postOnlyInTopic {
                data["type"] = "topicPost"  // To fetch in a different ref when loading the posts of the topic
            }
            
            ref.setData(data) { (err) in
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
        
        let userRef = Firestore.firestore().collection("Users").document(userID).collection("events").document(documentID)
        
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
        
        // remove ActivityIndicator incl. backgroundView
        self.view.activityStopAnimating()
        self.shareButton.isEnabled = true
        if self.comingFromAddOnVC {
            self.dismiss(animated: true) {
                if let post = post {
                    self.addItemDelegate?.itemSelected(item: post)  // Save the post in OptionalInformationVC
                }
            }
        } else {
            let alert = UIAlertController(title: "Done!", message: NSLocalizedString("message_after_done_posting", comment: "thanks"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                
                self.descriptionTextView.text.removeAll()
                self.linkTextField.text?.removeAll()
                self.locationTextField.text?.removeAll()
                self.titleTextView.text?.removeAll()
                self.previewPictures.removeAll()
                self.previewCollectionView.reloadData()
                
                self.removePictureButton.alpha = 0
                self.removePictureButton.isEnabled = false
                
                self.characterCountLabel.text = "200"
                self.pictureViewHeight!.constant = 100
                
                if self.optionViewHeight?.constant != self.defaultOptionViewHeight {
                    self.optionButtonTapped()
                }
                self.addedFactDescriptionLabel.text?.removeAll()
                self.addedFactImageView.image = nil
                self.addedFactImageView.layer.borderColor = UIColor.clear.cgColor
                self.cancelLinkedFactTapped()
                
                self.titleTextView.resignFirstResponder()
                self.descriptionTextView.resignFirstResponder()
                self.linkTextField.resignFirstResponder()
                self.locationTextField.resignFirstResponder()
                
                
                
                
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
        guard let title = titleTextView.text else { return [""] }
        
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

extension NewPostViewController: ChoosenLocationDelegate {
    func gotLocation(location: Location) {
        self.linkedLocation = location
        self.choosenLocationLabel.text = location.title
    }
}

extension NewPostViewController: LinkFactWithPostDelegate {
    
    func selectedFact(fact: Fact, isViewAlreadyLoaded: Bool) {    // Link Fact with post - When posting, from postsOfFactTableVC and from OptionalInformationTableVC
        
        self.linkedFact = fact
        
        if isViewAlreadyLoaded {  // Means it is coming from the selection of a topic to link with, so the view is already loaded, so it doesnt crash
            showLinkedFact(fact: fact)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { //I know, I know
                self.showShareAlert()
            }
        }
    }
    
    func showLinkedFact(fact: Fact) {
        
        addFactButton.isHidden = true
        cancelLinkedFactButton.isHidden = false
        
        linkedFactView.addSubview(addedFactImageView)
        addedFactImageView.centerYAnchor.constraint(equalTo: linkedFactView.centerYAnchor, constant: 10).isActive = true
        addedFactImageView.heightAnchor.constraint(equalToConstant: defaultOptionViewHeight-10).isActive = true
        addedFactImageView.trailingAnchor.constraint(equalTo: cancelLinkedFactButton.leadingAnchor, constant: -10).isActive = true
        addedFactImageView.widthAnchor.constraint(equalToConstant: defaultOptionViewHeight-10).isActive = true
        
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


//MARK: -PreviewCollectionView
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
        
        let size = CGSize(width: previewCollectionView.frame.width, height: previewCollectionView.frame.height)
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
