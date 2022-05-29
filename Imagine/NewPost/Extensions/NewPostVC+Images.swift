//
//  NewPostVC+Images.swift
//  Imagine
//
//  Created by Don Malte on 22.09.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit
import BSImagePicker
import Photos
import CropViewController

extension NewPostVC: UIImagePickerControllerDelegate {
    
    func removeImages() {
        selectedImagesFromPicker.removeAll()
        self.previewPictures.removeAll()
        
        animateCellHeightChange()
    }
    
    // MARK: - Select Images
    
    func openMultiPictureImagePicker() {
        let multiImagePicker = ImagePickerController()
        let options = multiImagePicker.settings
        options.selection.max = 3
        let fetchOptions = options.fetch.album.options
        
        options.fetch.album.fetchResults = [
            PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumRecentlyAdded, options: fetchOptions),
            PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: fetchOptions),
        ]
        
        multiImageAssets.removeAll()
        
        
        presentImagePicker(multiImagePicker, select: { asset in
            
            self.multiImageAssets.append(asset)
        }, deselect: { asset in
            //Remove asset from array
            self.multiImageAssets = self.multiImageAssets.filter{ $0 != asset}
        }, cancel: { _ in
            self.multiImageAssets.removeAll()
        }, finish: { _ in
            self.previewPictures.removeAll()
            self.getImages(forPreview: true) { (_) in }
        })
    }
    
    //MARK: - Image Picker
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        imagePicker.dismiss(animated: memeView == nil)
        
        savePictureAfterwards = picker.sourceType == .camera
        
        if let originalImage = info[.originalImage] as? UIImage {
            showCropView(image: originalImage)
        }
    }
    
    func setImagesAndShowPreview(images: [UIImage]) {
        
        if let firstImage = images.first {
            selectedImageFromPicker = firstImage
            selectedImageHeight = firstImage.size.height
            selectedImageWidth = firstImage.size.width
        }
        
        self.previewPictures = images
        
        showImagesAndIncreaseUI(images: images)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    
    // MARK: - Prepare for Upload
    func getPictureInCompressedQuality(image: UIImage) -> Data? {
        guard let originalImage = image.jpegData(compressionQuality: 1) else { return nil }
        let data = NSData(data: originalImage)
        
        let imageSize = data.count / 1000
        
        var compression = 0.0
        
        if imageSize <= 500 {   // When the imageSize is under 500kB it wont be compressed, because you can see the difference
            // No compression
            return originalImage
        } else if imageSize <= 1000 {
            compression = 0.4
        } else if imageSize <= 2000 {
            compression = 0.25
        } else {
            compression = 0.1
        }
        
        return image.jpegData(compressionQuality: compression)
    }
    
    func getImages(forPreview: Bool, images: @escaping ([Data]) -> Void)  {
        self.selectedImagesFromPicker.removeAll()
        
        multiImageAssets.forEach { asset in
            
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (image, info) in
                if let image = image {
                    
                    if forPreview {
                        self.previewPictures.append(image)
                        
                        if self.previewPictures.count == self.multiImageAssets.count {
                            self.setImagesAndShowPreview(images: self.previewPictures)
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
                        }
                    }
                } else {
                    self.alert(message: NSLocalizedString("error_uploading_multiple_pictures_message", comment: "werid bug"), title: NSLocalizedString("error_title", comment: "we have error"))
                    self.view.activityStopAnimating()
                    self.sharingEnabled = true
                }
            }
        }
    }
    
    func showImagePicker() {
        self.imagePicker.sourceType = .photoLibrary
        self.imagePicker.mediaTypes = ["public.image"]
        
        self.selectedOption = .picture
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
    func removePictureTapped() {
        
        self.multiImageAssets.removeAll()
        self.previewPictures.removeAll()
        self.collectionView.reloadData()
    }
    
    
    //MARK: - Picture Post Actions
    
    func openCamera() {
        if AuthenticationManager.shared.isLoggedIn {
            
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
            
            var goAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            if UIApplication.shared.canOpenURL(URL(string: UIApplication.openSettingsURLString)!) {
                alertText = NSLocalizedString("newPost_camera_error_text", comment: "CANT ACCESS    what to do")
                                
                goAction = UIAlertAction(title: "Go", style: .default, handler: {(alert: UIAlertAction!) -> Void in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                })
            }
            
            let alert = UIAlertController(title: "Error", message: alertText, preferredStyle: .alert)
            alert.addAction(goAction)
            self.present(alert, animated: true)
        }
    }
    
    func showCamera() {
        DispatchQueue.main.async {
            
            self.imagePicker.sourceType = .camera
            self.imagePicker.cameraCaptureMode = .photo
            self.imagePicker.cameraDevice = .rear
            self.imagePicker.cameraFlashMode = .off
            self.imagePicker.showsCameraControls = true
            
            self.present(self.imagePicker, animated: true)
        }
    }
    
    func openPhotoLibrary() {
        if AuthenticationManager.shared.isLoggedIn {
            
            switch PHPhotoLibrary.authorizationStatus() {
            case .notDetermined:
                //Not yet decided - ask the user for authorization
                PHPhotoLibrary.requestAuthorization { status in
                    self.openPhotoLibrary()
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
    
    
    func showImagesAndIncreaseUI(images: [UIImage]) {
        if let cell = getCell(for: .picture) as? NewPostPictureCell {
            cell.presentImages(images: images)
        }
        
        animateCellHeightChange()
    }
}

extension NewPostVC: CropViewControllerDelegate {
    
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
        
        // Change the presenting style to allow the cropViewController to be displayed when MemeView ist there, normal NewPostVC and NewPostVC inside a community
        if let _ = memeView {
            self.present(cropViewController, animated: true)
        } else {
            self.navigationController?.pushViewController(cropViewController, animated: true)
        }
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        
        // Change the presenting style to allow the cropViewController to be displayed when MemeView ist there, normal NewPostVC and NewPostVC inside a community
        if let cropVC = self.cropViewController {
            if memeView != nil {
                cropVC.dismiss(animated: false)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
            
            if let memeView = self.memeView {
                memeView.imageSelected(image: image)
            } else {
                self.setImagesAndShowPreview(images: [image])
            }
        }
    }
}
