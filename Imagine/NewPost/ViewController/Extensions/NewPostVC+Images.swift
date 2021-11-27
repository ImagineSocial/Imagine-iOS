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

extension NewPostViewController {
    
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
        
        self.multiImageAssets.removeAll()
        
        //TODo: change the selection
        self.presentImagePicker(multiImagePicker, select: { (asset) in
            
            self.multiImageAssets.append(asset)
        }, deselect: { (asset) in
            //Remove asset from array
            self.multiImageAssets = self.multiImageAssets.filter{ $0 != asset}
        }, cancel: { (asset) in
            self.multiImageAssets.removeAll()
        }, finish: { (asset) in
            self.previewPictures.removeAll()
            self.getImages(forPreview: true) { (_) in }
            self.increasePictureUI()
        })
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
                        
        }
//        else if let videoURL = info[.mediaURL] as? NSURL{
//            print("#We got a video")
//            uploadVideo(videoURL: videoURL)
//            testVideo(videoURL: videoURL)
//        }
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
        
        // Change the presenting style to allow the cropViewController to be displayed when MemeView ist there, normal NewPostVC and NewPostVC inside a community
        if let _ = memeView {
            self.present(cropViewController, animated: true, completion: nil)
        } else {
            self.navigationController?.pushViewController(cropViewController, animated: true)
        }
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        
        // Change the presenting style to allow the cropViewController to be displayed when MemeView ist there, normal NewPostVC and NewPostVC inside a community
        if let cropVC = self.cropViewController {
            if let _ = memeView {
                cropVC.dismiss(animated: false, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
            
            if let memeView = self.memeView {
                memeView.imageSelected(image: image)
            } else {
                self.setImageAndShowPreviewImage(image: image)
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
        
        pictureView.showPicture(image: image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Prepare for Upload
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
            options.isNetworkAccessAllowed = true
            
            options.progressHandler = {  (progress, error, stop, info) in
                print("progress: \(progress)")
            }
            
            // Request the maximum size. If you only need a smaller size make sure to request that instead.
            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (image, info) in
                if let image = image {
                    
                    if forPreview {
                        self.previewPictures.append(image)
                        
                        if self.previewPictures.count == self.multiImageAssets.count {
                            self.pictureView.showPicture(image: nil)
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
                    self.shareButton.isEnabled = true
                }
            }
        }
    }
}
