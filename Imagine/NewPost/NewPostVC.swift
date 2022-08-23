//
//  NewPostVC.swift
//  Imagine
//
//  Created by Don Malte on 08.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit
import Photos
import EasyTipView
import SwiftLinkPreview
import CropViewController

enum NewPostButton {
    case meme, option, location, linkInfo, anonymousInfo, linkedCommunityInfo, linkCommunity, cancelLinkedCommunity, cancelLocation
}

enum PostSelection {
    case picture
    case link
    case thought
    case multiPicture
}

enum NewPostTextType {
    case title, description, link
}

protocol JustPostedDelegate: class {
    func posted()
}

class NewPostVC: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - Variables
    
    var selectedOption: PostSelection = .thought
    var collectionItems: [NewPostItem] {
        switch selectedOption {
        case .link:
            return [.title, .link, .description, .location, .linkCommunity, .options]
        case .thought:
            return [.title, .description, .location, .linkCommunity, .options]
        default:
            return [.title, .picture, .description, .location, .linkCommunity, .options]
        }
    }
    
    var titleText: String?
    var descriptionText: String?
    var images: [UIImage]?
    var location: Location?
    var url: String?
    var linkedCommunity: Community?
    
    var imageURLs = [String]()
    var multiImageAssets = [PHAsset]()
    var previewPictures = [UIImage]()
    
    var sharingEnabled = true
    var postOptions: NewPostOption?
    
    // MemeMode
    var memeView: MemeInputView?    
    var howManyFlickersIndex = 0
    var flickerInterval = 0.3
    let generator = UIImpactFeedbackGenerator(style: .light)
    
    var comingFromPostsOfFact = false
    var comingFromAddOnVC = false   // This will create a difference reference for the post to be stored, to show it just in the topic and not in the main feed - later it will show up for those who follow this topic
    weak var addItemDelegate: AddItemDelegate?
    var isTopicPost = false
    var addOn: AddOn?
    
    var selectedImagesFromPicker = [Data]()
    var selectedImageFromPicker:UIImage?
    
    var selectedImageHeight: CGFloat = 0.0
    var selectedImageWidth: CGFloat = 0.0
    var imageURL: String?
    var thumbnailImageURL: String?
    
    var reportType :ReportType = .normal
        
    var postAnonymous = false
    var anonymousName: String?
    var anonymousString = "anonym"
    
    var fakeProfileUserID: String?
        
    let defaultOptionViewHeight: CGFloat = 45
    
    let infoButtonSize: CGFloat = 22
    
    var cropViewController: CropViewController?
    
    let db = FirestoreRequest.shared.db
    
    /// Link the delegate from the main feed to switch to its view again and reload if somebody posts something
    weak var delegate: JustPostedDelegate?
    weak var newInstanceDelegate: NewFactDelegate?
    
    var savePictureAfterwards = false   // If you have made the image with the cam
    
    //InfoViews
    var infoView: UIView?
    
    lazy var slp = SwiftLinkPreview(session: URLSession.shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, cache: InMemoryCache())
    
    var markPostTipView: EasyTipView?
    var postLinkTipView: EasyTipView?
    var linkedFactTipView: EasyTipView?
    var postAnonymousTipView: EasyTipView?
    var linkFactExplanationTipView: EasyTipView?
    
    // MARK: - Elements
    
    let layout = UICollectionViewFlowLayout()
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupBarButton()
        
        // Set Listener and delegates
        imagePicker.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let view = infoView {
            view.removeFromSuperview()
        }
        removeTipViews()
    }
    
    func setupBarButton() {
        let barButton = UIBarButtonItem(title: Strings.share, style: .done, target: self, action: #selector(shareTapped))
        
        navigationItem.rightBarButtonItem = barButton
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "searchFactsSegue":
            if let navCon = segue.destination as? UINavigationController, let factVC = navCon.topViewController as? CommunityCollectionVC {
                factVC.addFactToPost = .newPost
                factVC.delegate = self
            }            
        default: break
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
}
