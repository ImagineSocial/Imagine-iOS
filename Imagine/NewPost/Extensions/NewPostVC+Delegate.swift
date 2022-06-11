//
//  NewPostVC+Delegate.swift
//  Imagine
//
//  Created by Don Malte on 14.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit
import EasyTipView

extension NewPostVC {
    
    func getCell(for item: NewPostItem) -> UICollectionViewCell? {
        if let index = collectionItems.firstIndex(of: item) {
            return collectionView.cellForItem(at: IndexPath(item: index, section: 0))
        }
        
        return nil
    }
}

extension NewPostVC: LinkFactWithPostDelegate {
    
    func selectedFact(community: Community, isViewAlreadyLoaded: Bool) {    // Link Fact with post - When posting, from postsOfFactTableVC and from OptionalInformationTableVC
        
        self.linkedCommunity = community
        
        if isViewAlreadyLoaded {  // Means it is coming from the selection of a topic to link with, so the view is already loaded, so it doesnt crash
            showLinkedFact(community: community)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { //I know, I know
                self.showShareAlert()
            }
        }
    }
    
    func showShareAlert() {
        let shareAlert = UIAlertController(title: NSLocalizedString("link_fact_destination_alert_header", comment: "Where?"), message: NSLocalizedString("link_fact_destination_alert_message", comment: "with everybody or just community?"), preferredStyle: .actionSheet)
        
        shareAlert.addAction(UIAlertAction(title: NSLocalizedString("link_fact_destination_everybody", comment: "everybody"), style: .default) { _ in
            self.changeCommunityDestination(communityOnly: false)
        })
        shareAlert.addAction(UIAlertAction(title: NSLocalizedString("link_fact_destination_community", comment: "community"), style: .default) { _ in
            self.changeCommunityDestination(communityOnly: true)
        })
        
        present(shareAlert, animated: true, completion: nil)
    }
    
    func changeCommunityDestination(communityOnly: Bool) {
        self.postOnlyInTopic = communityOnly
        
        if let cell = getCell(for: .linkCommunity) as? NewPostLinkCommunityCell {
            cell.changeCommunityDestination(communityOnly: communityOnly)
        }
    }
    
    func showLinkedFact(community: Community) {
        if let cell = getCell(for: .linkCommunity) as? NewPostLinkCommunityCell {
            cell.showLinkedCommunity(community: community)
        }
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
        self.dismiss(animated: true)
    }

}

extension NewPostVC: ChoosenLocationDelegate {
    func gotLocation(location: Location) {
        self.location = location
        
        setLocation(location: location)
    }
    
    private func setLocation(location: Location?) {
        if let cell = getCell(for: .location) as? NewPostLocationCell {
            cell.setLocation(location: location)
        }
    }
}


extension NewPostVC: NewPostCollectionDelegate {
    
    func animateCellHeightChange() {
        collectionView.collectionViewLayout.invalidateLayout()
        UIView.animate(withDuration: 0.3) {
            self.collectionView.layoutIfNeeded()
        }
    }
    
    
    func openImagePicker(for type: UIImagePickerController.SourceType) {
        switch type {
        case .camera:
            openCamera()
        default:
            openPhotoLibrary()
        }
    }
    
    func textChanged(for type: NewPostTextType, text: String?) {
        switch type {
        case .title:
            self.titleText = text
        case .description:
            self.descriptionText = text
        case .link:
            self.url = text
        }
    }
    
    func showImage(_ image: UIImage?) {
        guard let image = image else {
            return
        }
        
        let pinchVC = PinchToZoomViewController()
        
        pinchVC.imageView.image = image
        self.navigationController?.pushViewController(pinchVC, animated: true)
    }
    
    func segmentControlChanged(to value: Int) {
        
        switch value {
        case 0:
            selectedOption = .thought
        case 1:
            selectedOption = .picture
        default:
            selectedOption = .link
        }
        collectionView.reloadData()
        // TODO: Hier muss noch irgendwas geschehen oder?
    }
    
    func removePictures() {
        removeImages()
    }
    
    func buttonTapped(newPostButton: NewPostButton) {
        switch newPostButton {
        case .meme:
            memeModeTapped()
        case .option:
            animateCellHeightChange()
        case .location:
            let vc = MapViewController()
            vc.locationDelegate = self
            vc.navigationItem.largeTitleDisplayMode = .never
            vc.hidesBottomBarWhenPushed = true
            
            navigationController?.pushViewController(vc, animated: true)
        case .linkInfo:
            if let tipView = self.postLinkTipView {
                tipView.dismiss()
                postLinkTipView = nil
            } else {
                self.postLinkTipView = EasyTipView(text: NSLocalizedString("postLinkTipViewText", comment: "What you can post and such"))
                // postLinkTipView!.show()
            }
        case .anonymousInfo:
            if let tipView = self.postAnonymousTipView {
                tipView.dismiss()
                postAnonymousTipView = nil
            } else {
                self.postAnonymousTipView = EasyTipView(text: Constants.texts.postAnonymousText)
                // postAnonymousTipView!.show(forView: optionView)
            }
        case .linkedCommunityInfo:
            if let tipView = self.linkedFactTipView {
                tipView.dismiss()
                linkedFactTipView = nil
            } else {
                self.linkedFactTipView = EasyTipView(text: NSLocalizedString("linked_fact_tip_view_text", comment: "how and why"))
                // linkedFactTipView!.show(forView: linkCommunityView)
            }
        case .linkCommunity:
            performSegue(withIdentifier: "searchFactsSegue", sender: nil)
        case .cancelLinkedCommunity:
            if let cell = getCell(for: .linkCommunity) as? NewPostLinkCommunityCell {
                cell.removeLinkedCommunity()
            }
        case .cancelLocation:
            self.location = nil
            if let cell = getCell(for: .location) as? NewPostLocationCell {
                cell.setLocation(location: nil)
            }
        }
    }
}


// MARK: - AddOnDelegate

extension NewPostVC: AddOnDelegate {
    func fetchCompleted() {
        print("Not needed")
    }
    
    func itemAdded(successfull: Bool) {
        // remove ActivityIndicator incl. backgroundView
        view.activityStopAnimating()
        sharingEnabled = true
        
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


// MARK: - BaseSegmentControl Delegate

extension NewPostVC: BaseSegmentControlDelegate {
    func segmentChanged(to index: Int, direction: UIPageViewController.NavigationDirection) {
        
        collectionView.performBatchUpdates {
            
            let indexPath = IndexPath(item: 1, section: 0)
            
            if selectedOption == .thought {
                collectionView.insertItems(at: [indexPath])
            } else {
                if index == 0 {
                    // Will be of type .thought
                    collectionView.deleteItems(at: [indexPath])
                } else {
                    collectionView.deleteItems(at: [indexPath])
                    collectionView.insertItems(at: [indexPath])
                }
            }
            
            switch index {
            case 0:
                selectedOption = .thought
            case 1:
                selectedOption = .picture
            default:
                selectedOption = .link
            }
        }
    }
}
