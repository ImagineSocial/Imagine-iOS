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
import SDWebImage
import EasyTipView

enum PostSelection {
    case picture
    case link
    case thought
    case YTVideo
    case event
}

enum EventType {
    case activity
    case project
    case event
}

// Fehlermeldungen für nichtvorhandene Links oder Bilder
// Constraints Absichern
// Event alles hinzufügen
class NewPostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {
    
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var postSelectionSegmentedControl: UISegmentedControl!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var headerView: UIView!
    
    
    var imagePicker = UIImagePickerController()
    var selectedImageFromPicker:UIImage?
    var selectedImageHeight: CGFloat = 0.0
    var selectedImageWidth: CGFloat = 0.0
    var imageURL:String?
    var reportType :ReportType = .normal
    var eventType: EventType = .activity
    var camPic = false
    var selectDate = false
    var selectedDate: Date?
    
    var postAnonymous = false
    
    let db = Firestore.firestore()
    
    var selectedOption: PostSelection = .thought
    
    let labelFont = UIFont(name: "IBMPlexSans-Medium", size: 15)
    let characterLimitForTitle = 200
    let characterLimitForEventTitle = 100
    let defaultOptionViewHeight: CGFloat = 45
    
    var up = false
    
    var linkedFact: Fact?
    
    var pictureViewHeight: NSLayoutConstraint?
    var linkViewHeight: NSLayoutConstraint?
    var eventViewHeight: NSLayoutConstraint?
    var locationViewHeight: NSLayoutConstraint?
    var optionViewHeight: NSLayoutConstraint?
    
    var descriptionViewTopAnchor: NSLayoutConstraint?
    var pictureViewTopAnchor: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        titleTextView.delegate = self
        
//        let factCollectionVC = FactCollectionViewController()
//        factCollectionVC.delegate = self
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        setCompleteUIForThought()
        setPictureViewUI()
        setLinkViewUI()
        setUpOptionViewUI()
//        setEventViewUI()
//        setLocationViewUI()
        
        
        let font: [AnyHashable : Any] = [NSAttributedString.Key.font : UIFont(name: "IBMPlexSans", size: 15) as Any]
        markPostSegmentControl.setTitleTextAttributes(font as? [NSAttributedString.Key : Any], for: .normal)
        markPostSegmentControl.tintColor = Constants.imagineColor
        postSelectionSegmentedControl.tintColor = Constants.imagineColor
        postSelectionSegmentedControl.setTitleTextAttributes(font as? [NSAttributedString.Key : Any], for: .normal)
        
        //KeyboardGoesUp
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
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
        
//        if let linkViewHeight = self.linkViewHeight {
//            linkViewHeight.isActive = false
//        }
        
        switch selectedOption {
        case .link:
            self.linkLabel.text = "Link:"
            self.linkTextField.placeholder = "Link: https://..."
        case .YTVideo:
            self.linkLabel.text = "Youtube Video-Link:"
            self.linkTextField.placeholder = "Link: youtube.com/watch?v=9zr_whatever..."
        default:
            print("Wont happen")
        }
        
        self.descriptionViewTopAnchor! = descriptionView.topAnchor.constraint(equalTo: linkView.bottomAnchor, constant: 1)
        self.descriptionViewTopAnchor!.isActive = true
        
        self.linkViewHeight!.constant = 65
        
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
        }) { (_) in
        
            UIView.animate(withDuration: 0.1, animations: {
                self.linkLabel.alpha = 1
                self.linkTextField.alpha = 1
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
        label.text = "Beschreibung:"
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
    
    func setLinkViewUI() {   // have to set descriptionview topanchor
        linkView.addSubview(linkLabel)
        linkLabel.topAnchor.constraint(equalTo: linkView.topAnchor, constant: 5).isActive = true
        linkLabel.leadingAnchor.constraint(equalTo: linkView.leadingAnchor, constant: 10).isActive = true
        linkLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        linkView.addSubview(linkTextField)
        linkTextField.topAnchor.constraint(equalTo: linkLabel.bottomAnchor, constant: 5).isActive = true
        linkTextField.leadingAnchor.constraint(equalTo: linkView.leadingAnchor, constant: 10).isActive = true
        linkTextField.trailingAnchor.constraint(equalTo: linkView.trailingAnchor, constant: -10).isActive = true
        linkTextField.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.view.addSubview(linkView)
        linkView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 1).isActive = true
        linkView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        linkView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.linkViewHeight = linkView.heightAnchor.constraint(equalToConstant: 0)
        self.linkViewHeight!.isActive = true
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
        label.text = "Bild:"
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        label.alpha = 0
        
        return label
    }()
    
    let cameraButton :DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "compact_camera"), for: .normal)
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
    
    let previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.image = UIImage(named: "default")
        imageView.contentMode = .scaleAspectFit
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showChoosenImage(tapGestureRecognizer:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
        imageView.layer.cornerRadius = 4
        
        // Tap isnt working
        
        return imageView
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
        
        pictureView.addSubview(previewImageView)
        previewImageView.topAnchor.constraint(equalTo: pictureView.topAnchor).isActive = true
        previewImageView.trailingAnchor.constraint(equalTo: pictureView.trailingAnchor).isActive = true
        previewImageView.leadingAnchor.constraint(equalTo: cameraButton.trailingAnchor, constant: 25).isActive = true
        previewImageView.bottomAnchor.constraint(equalTo: pictureView.bottomAnchor).isActive = true
        
        
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
    
    let optionButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            button.setTitleColor(.label, for: .normal)
            
        } else {
            button.setTitleColor(.black, for: .normal)
        }
        button.tintColor = Constants.imagineColor
        button.setImage(UIImage(named: "menu"), for: .normal)
//        button.setTitle("Mehr", for: .normal)
        button.addTarget(self, action: #selector(optionButtonTapped), for: .touchUpInside)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
//        button.layer.borderColor = Constants.imagineColor.cgColor
//        button.layer.borderWidth = 1
//        button.cornerRadius = 4
        
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
    
    let addFactButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = Constants.imagineColor
        button.setTitle("Mit Fakt verlinken", for: .normal)
        button.addTarget(self, action: #selector(linkFactToPostTapped), for: .touchUpInside)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
//        if #available(iOS 13.0, *) {
//            button.setTitleColor(.label, for: .normal)
//        } else {
//            button.setTitleColor(.black, for: .normal)
//        }
        button.setTitleColor(Constants.imagineColor, for: .normal)
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
        
        return label
    }()
    
    func setUpOptionViewUI() {
        
        optionView.addSubview(optionButton)
        optionButton.topAnchor.constraint(equalTo: optionView.topAnchor, constant: 5).isActive = true
        optionButton.leadingAnchor.constraint(equalTo: optionView.leadingAnchor, constant: 10).isActive = true
        optionButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        setMarkPostViewUI()
        setPostAnonymousViewUI()
        
        optionStackView.addArrangedSubview(markPostView)
        optionStackView.addArrangedSubview(postAnonymousView)
        optionStackView.addArrangedSubview(addFactButton)
        
        optionView.addSubview(optionStackView)
        optionStackView.leadingAnchor.constraint(equalTo: optionView.leadingAnchor).isActive = true
        optionStackView.trailingAnchor.constraint(equalTo: optionView.trailingAnchor).isActive = true
        optionStackView.topAnchor.constraint(equalTo: optionButton.bottomAnchor, constant: 3).isActive = true
        optionStackView.bottomAnchor.constraint(equalTo: optionView.bottomAnchor, constant: -5).isActive = true
                
        self.view.addSubview(optionView)
        optionView.topAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: 1).isActive = true
        optionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        optionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        optionViewHeight = optionView.heightAnchor.constraint(equalToConstant: defaultOptionViewHeight)
        optionViewHeight!.isActive = true
        
        let endView = UIView()
        if #available(iOS 13.0, *) {
            endView.backgroundColor = .systemBackground
        } else {
            endView.backgroundColor = .white
        }
        endView.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(endView)
        endView.topAnchor.constraint(equalTo: optionView.bottomAnchor, constant: 1).isActive = true
        endView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        endView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        endView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
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
        label.text = "Post Markieren"
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
        let items = ["Meinung", "Sensation", "Bearbeitet"]
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
        button.tintColor = Constants.imagineColor
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
        markPostButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        markPostButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
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
        label.text = "Anonym posten"
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
        button.tintColor = Constants.imagineColor
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
        postAnonymousButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        postAnonymousButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
    }
    
    // MARK: - KeyboardGoesUp
    
    @objc func keyboardWillChange(notification: NSNotification) {
        
        if !self.up {
            
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                if descriptionTextView.isFirstResponder {
                    
                    var offset:CGFloat = 75
                    switch selectedOption {
                    case .thought:
                        offset = 50
                    case .picture:
                        offset = 125
                    case .link:
                        offset = 100
                    case .YTVideo:
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
            case .thought:
                offset = 50
            case .picture:
                offset = 125
            case .link:
                offset = 100
            case .YTVideo:
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
            imagePicker.sourceType = .photoLibrary
            //imagePicker.allowsEditing = true
            
            self.present(self.imagePicker, animated: true, completion: nil)
            
        } else {
            self.notLoggedInAlert()
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
                height.constant = 165
                
                UIView.animate(withDuration: 0.4, animations: {
                    self.view.layoutIfNeeded()
                }) { (_) in
                    self.optionStackView.isHidden = false
                    UIView.animate(withDuration: 0.1) {
                        self.optionStackView.alpha = 1
                    }
                }
            } else {
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
    
    @objc func markPostInfoButtonPressed() {
        EasyTipView.show(forView: headerView, text: Constants.texts.markPostText)
    }
    
    @objc func postAnonymousButtonPressed() {
        EasyTipView.show(forView: headerView, text: Constants.texts.postAnonymousText)
    }
    
    @objc func postAnonymousSwitchChanged() {
        if postAnonymousSwitch.isOn {
            self.postAnonymous = true
            print("Post anonym: ",postAnonymous)
        } else {
            self.postAnonymous = false
            print("Post anonym: ",postAnonymous)
            
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
            }) { (_) in
                self.linkViewHeight!.constant = 0
                
                UIView.animate(withDuration: 0.4, animations: {
                    self.view.layoutIfNeeded()
                }) { (_) in
                    self.setTheChange()
                }
            }
        case .YTVideo:
            // Let the LinkView disappear
            UIView.animate(withDuration: 0.1, animations: {
                self.linkLabel.alpha = 0
                self.linkTextField.alpha = 0
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
        if postSelectionSegmentedControl.selectedSegmentIndex == 3 {
            self.selectedOption = .YTVideo
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
                    factVC.addFactToPost = true
                    factVC.delegate = self
                }
            }
        }
    }
    
    //MARK: SharePressed
    
    @IBAction func sharePressed(_ sender: Any) {
        
        if let user = Auth.auth().currentUser {
            var userID = ""
            let postRef = db.collection("Posts").document()
            
            if self.postAnonymous {
                userID = "anonym"
            } else {
                userID = user.uid
            }

            if titleTextView.text != "" {
                switch selectedOption {
                case .thought:
                    self.view.activityStartAnimating()
                    self.postThought(postRef: postRef, userID: userID)
                case .picture:
                    self.view.activityStartAnimating()
                    self.savePicture(userID: userID, postRef: postRef)
//                    self.shareButton.isEnabled = false
                case .link:
                    self.view.activityStartAnimating()
                    self.postLink(postRef: postRef, userID: userID)
                case .YTVideo:
                    self.view.activityStartAnimating()
                    self.postYTVideo(postRef: postRef, userID: userID)
                case .event:
                    self.view.activityStartAnimating()
                    self.postEvent(postRef: postRef, userID: userID)
                }
            } else {
                self.alert(message: "Der Post muss einen Titel haben", title: "Kein Titel")
            }
        } else {
            self.notLoggedInAlert()
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
            setImage(image: image)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    
    func setImage(image: UIImage) {
        previewImageView.image = image
        
        self.pictureViewHeight!.constant = 150        // Absichern
        
        UIView.animate(withDuration: 3) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func savePicture(userID: String, postRef: DocumentReference) {
        let storageRef = Storage.storage().reference().child("postPictures").child("\(postRef.documentID).png")
        
        if let uploadData = self.selectedImageFromPicker?.jpegData(compressionQuality: 0.1) {   //Es war das Fragezeichen
            storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in    //Bild speichern
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
        } else {
            self.alert(message: "Du hast kein Bild hochgeladen. Möchtest du kein Bild hochladen, wähle bitte eine andere Post-Option aus", title: "Kein Bild")
        }
    }
    
    // MARK: - Upload the post
    
    func postThought(postRef: DocumentReference, userID: String) {
        let descriptionText = descriptionTextView.text.replacingOccurrences(of: "\n", with: "\\n")  // Just the text of the description has got line breaks
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
                self.alert(message: "Unser Programm sagt mir, dass die URL nicht korrekt ist. Bitte überprüfe den Link", title: "Link fehlerhaft")
            }
        } else {
            self.alert(message: "Du hast kein Link angegeben. Möchtest du kein Link posten, wähle bitte eine andere Post-Option aus", title: "Kein Link")
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
            self.alert(message: "Du hast kein Bild hochgeladen. Möchtest du kein Bild hochladen, wähle bitte eine andere Post-Option aus", title: "Kein Bild")
            self.shareButton.isEnabled = true
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
                self.alert(message: "Bitte füge ein Titelbild hinzu, das spricht die Menschen eher an. Danke!", title: "Kein Bild")
            }
        } else {
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
        
        if let fact = self.linkedFact { // If there is a fact that should be linked to this post, i append its ID to the array
            data["linkedFactID"] = fact.documentID
        }
        
        postRef.setData(data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
                // Inform User
            } else {
                if let ref = userRef {
                    if self.postAnonymous {
                        if let user = Auth.auth().currentUser {
                            ref.setData(["createTime": self.getDate(), "originalPoster": user.uid])
                        }
                    } else {
                        ref.setData(["createTime": self.getDate()])      // add the post to the user
                    }
                }
                if self.camPic { // To Save on your device, not the best solution though
                    if let selectedImage = self.selectedImageFromPicker {
                        UIImageWriteToSavedPhotosAlbum(selectedImage, nil, nil, nil)
                    }
                }
                
                self.presentAlert()
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
                
                self.presentAlert()
            }
        }
        
    }
    
    func presentAlert() {
        
        // remove ActivityIndicator incl. backgroundView
        self.view.activityStopAnimating()
        self.shareButton.isEnabled = true
        
        let alert = UIAlertController(title: "Done!", message: "Danke für deine Weisheiten.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            self.descriptionTextView.text.removeAll()
            self.linkTextField.text?.removeAll()
            self.locationTextField.text?.removeAll()
            self.titleTextView.text?.removeAll()
            self.previewImageView.image = nil
            self.characterCountLabel.text = "200"
            self.pictureViewHeight!.constant = 100
            self.optionButtonTapped()
            self.addedFactDescriptionLabel.text?.removeAll()
            self.addedFactImageView.image = nil
            
            self.titleTextView.resignFirstResponder()
            self.descriptionTextView.resignFirstResponder()
            self.linkTextField.resignFirstResponder()
            self.locationTextField.resignFirstResponder()
        }))
        
        self.present(alert, animated: true) {
            
        }
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

extension NewPostViewController: LinkFactWithPostDelegate {
    func selectedFact(fact: Fact) {
        
        self.linkedFact = fact
        
        optionView.addSubview(addedFactImageView)
        addedFactImageView.topAnchor.constraint(equalTo: optionView.topAnchor, constant: 5).isActive = true
        addedFactImageView.trailingAnchor.constraint(equalTo: optionView.trailingAnchor, constant: -20).isActive = true
        addedFactImageView.widthAnchor.constraint(equalToConstant: defaultOptionViewHeight-10).isActive = true
        addedFactImageView.heightAnchor.constraint(equalToConstant: defaultOptionViewHeight-10).isActive = true
        
        if let url = URL(string: fact.imageURL) {
            addedFactImageView.sd_setImage(with: url, completed: nil)
        }
        
        optionView.addSubview(addedFactDescriptionLabel)
        addedFactDescriptionLabel.centerYAnchor.constraint(equalTo: addedFactImageView.centerYAnchor).isActive = true
        addedFactDescriptionLabel.trailingAnchor.constraint(equalTo: addedFactImageView.leadingAnchor, constant: -15).isActive = true
        
        addedFactDescriptionLabel.text = "Verlinkter Fakt:  '\(fact.title)' "
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.optionButtonTapped()
        }
        
    }
}
