//
//  StorageManager.swift
//  Imagine
//
//  Created by Don Malte on 11.06.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseStorage
import BSImagePicker
import Photos

class StorageManager {
    
    // MARK: - MultiPicture
    
    static func getImagesForMultiPicture(assets: [PHAsset], documentID: String, completion: @escaping ([PostImage]?) -> Void) {
        
        getMultipleUploadImages(assets: assets) { images in
            guard let images = images else {
                completion(nil)
                return
            }
            
            self.uploadMultipleImages(images: images, documentID: documentID) { images in
                completion(images)
            }
        }
    }
    
    private static func getMultipleUploadImages(assets: [PHAsset], completion: @escaping ([UploadImage]?) -> Void)  {
        var images = [UploadImage]()
        
        assets.forEach { asset in
            
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
                
                guard let image = image, let imageData = image.compressedData() else {
                    
                    completion(nil)
                    return
                }
                
                
                let uploadImage = UploadImage(imageData: imageData, width: image.size.width, height: image.size.height)
                images.append(uploadImage)
                
                if images.count == assets.count {
                    completion(images)
                }
            }
        }
    }
    
    private static func uploadMultipleImages(images: [UploadImage], documentID: String, completion: @escaping ([PostImage]?) -> Void) {
        
        var postImages = [PostImage]()
        
        for (index, image) in images.enumerated() {
            
            let storageID = "\(documentID)-\(index)"
                        
            let storageRef = Storage.storage().reference().child("postPictures").child("\(storageID).png")
            
            storageRef.putData(image.imageData) { data, error in
                guard error == nil else {
                    print("We have an error: \(error?.localizedDescription ?? "")")
                    completion(nil)
                    return
                }
                
                storageRef.downloadURL { url, error in
                    guard let url = url, error == nil else {
                        print("We have an error: \(error?.localizedDescription ?? "")")
                        completion(nil)
                        return
                    }
                    
                    let postImage = PostImage(url: url.absoluteString, height: image.height, width: image.width)
                    postImages.append(postImage)
                    
                    if postImages.count == images.count {
                        completion(postImages)
                    }
                }
            }
        }
    }
    
    // MARK: - Picture
    
    // MARK: Prepare Picture
    static func getImageForSinglePicture(image: UploadImage, documentID: String, completion: @escaping (PostImage?) -> Void) {

        let uploadImage = UploadImage(imageData: image.imageData, width: image.width, height: image.height)
        uploadSingleImage(image: uploadImage, documentID: documentID) { image in
            self.uploadThumbnail(image: uploadImage, documentID: documentID) { thumbnailURL in
                guard var image = image else {
                    completion(nil)
                    return
                }

                image.thumbnailUrl = thumbnailURL
                completion(image)
            }
        }
    }
    
    private static func uploadSingleImage(image: UploadImage, documentID: String, completion: @escaping (PostImage?) -> Void) {
                
        let storageRef = Storage.storage().reference().child("postPictures").child("\(documentID).png")
        
        storageRef.putData(image.imageData) { data, error in
            guard error == nil else {
                print("We have an error: \(error?.localizedDescription ?? "")")
                completion(nil)
                
                return
            }
            
            storageRef.downloadURL { url, error in  // Download url and save it
                guard let url = url, error == nil else {
                    print("We have an error: \(error?.localizedDescription ?? "")")
                    completion(nil)
                    
                    return
                }
                
                let postImage = PostImage(url: url.absoluteString, height: image.height, width: image.width)
                completion(postImage)
            }
        }
    }
    
    private static func uploadThumbnail(image: UploadImage, documentID: String, completion: @escaping (String?) -> Void) {
        
        let storageID = "\(documentID)-thumbnail"
        
        let storageRef = Storage.storage().reference().child("postPictures").child("\(storageID).png")
        
        storageRef.putData(image.imageData) { data, error in
            guard error == nil else {
                print("We have an error: \(error?.localizedDescription ?? "")")
                completion(nil)
                
                return
            }
            
            storageRef.downloadURL { url, error in  // Download url and save it
                guard let url = url, error == nil else {
                    print("We have an error: \(error?.localizedDescription ?? "")")
                    completion(nil)
                    
                    return
                }
                
                completion(url.absoluteString)
            }
        }
    }
}
