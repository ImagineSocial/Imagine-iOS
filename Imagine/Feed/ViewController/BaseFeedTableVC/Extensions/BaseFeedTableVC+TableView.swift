//
//  BaseFeedTableVC+TableView.swift
//  Imagine
//
//  Created by Don Malte on 22.09.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit
import SDWebImage
import AVFoundation

extension BaseFeedTableViewController {
    
    func setupTableView() {
        tableView.register(UINib(nibName: "MultiPictureCell", bundle: nil), forCellReuseIdentifier: MultiPictureCell.identifier)
        tableView.register(UINib(nibName: "RePostTableViewCell", bundle: nil), forCellReuseIdentifier: RePostCell.identifier)
        tableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: PictureCell.identifier)
        tableView.register(UINib(nibName: "LinkCell", bundle: nil), forCellReuseIdentifier: LinkCell.identifier)
        tableView.register(UINib(nibName: "ThoughtPostCell", bundle: nil), forCellReuseIdentifier: ThoughtCell.identifier)
        tableView.register(UINib(nibName: "YouTubeCell", bundle: nil), forCellReuseIdentifier: YouTubeCell.identifier)
        tableView.register(UINib(nibName: "BlankContentCell", bundle: nil), forCellReuseIdentifier: BlankContentCell.identifier)
        tableView.register(UINib(nibName: "GifCell", bundle: nil), forCellReuseIdentifier: GifCell.identifier)
        tableView.register(UINib(nibName: "SurveyCell", bundle: nil), forCellReuseIdentifier: SurveyCell.identifier)
        tableView.register(UINib(nibName: "MusicCell", bundle: nil), forCellReuseIdentifier: MusicCell.identifier)
        tableView.register(UINib(nibName: "FeedSingleTopicCell", bundle: nil), forCellReuseIdentifier: FeedSingleTopicCell.identifier)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.layer.zPosition = CGFloat(tableView.numberOfRows(inSection: 0) - indexPath.row)    // So the shadow isnt clipped
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 6 {
            self.presentInfoView()
        }
        
        let post = posts[indexPath.row]
        
        if let _ = post.survey {
            if let cell = tableView.dequeueReusableCell(withIdentifier: SurveyCell.identifier, for: indexPath) as? SurveyCell {
                
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
        case .multiPicture, .panorama:
            if let cell = tableView.dequeueReusableCell(withIdentifier: MultiPictureCell.identifier, for: indexPath) as? MultiPictureCell {
                
                cell.ownProfile = isOwnProfile
                cell.delegate = self
                cell.post = post
                
                if post.type == .multiPicture, let image = post.images?.first {
                    let imageHeight = image.height
                    let imageWidth = image.width
                    
                    let ratio = imageWidth / imageHeight
                    let width = self.view.frame.width - 20  // 5+5 from contentView and 5+5 from inset
                    var newHeight = width / ratio
                    
                    if newHeight >= 500 {
                        newHeight = 500
                    }
                    
                    if imageHeight == 0 {
                        newHeight = 300
                    }
                    
                    cell.multiPictureCollectionViewHeightConstraint.constant = newHeight
                } else {    // Panorama
                    let newHeight: CGFloat = 300
                    
                    cell.multiPictureCollectionViewHeightConstraint.constant = newHeight
                }
                
                return cell
            }
        case .repost, .translation:
            if let repostCell = tableView.dequeueReusableCell(withIdentifier: RePostCell.identifier, for: indexPath) as? RePostCell {
                
                repostCell.ownProfile = isOwnProfile
                repostCell.delegate = self
                repostCell.post = post
                
                return repostCell
            }
        case .picture:            
            if let cell = tableView.dequeueReusableCell(withIdentifier: PictureCell.identifier, for: indexPath) as? PictureCell, let image = post.image {
                
                cell.ownProfile = isOwnProfile
                cell.delegate = self
                cell.post = post
                
                let imageHeight = image.height
                let imageWidth = image.width
                
                let ratio = imageWidth / imageHeight
                let width = self.view.frame.width - 20  // 5+5 from contentView and 5+5 from inset
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
            if let cell = tableView.dequeueReusableCell(withIdentifier: ThoughtCell.identifier, for: indexPath) as? ThoughtCell {
                
                cell.ownProfile = isOwnProfile
                cell.delegate = self
                cell.post = post
                
                return cell
            }
        case .GIF:
            if let cell = tableView.dequeueReusableCell(withIdentifier: GifCell.identifier, for: indexPath) as? GifCell {
                
                cell.ownProfile = isOwnProfile
                cell.post = post
                cell.delegate = self
                
                if let linkURL = post.link?.url, let url = URL(string: linkURL) {
                    cell.videoPlayerItem = AVPlayerItem.init(url: url)
                    cell.startPlayback()
                }
                
                return cell
            }
        case .music:
            if let cell = tableView.dequeueReusableCell(withIdentifier: MusicCell.identifier, for: indexPath) as? MusicCell {
                
                cell.ownProfile = isOwnProfile
                cell.post = post
                cell.delegate = self
                cell.musicPostDelegate = self
                
                return cell
            }
        case .link:
            if let cell = tableView.dequeueReusableCell(withIdentifier: LinkCell.identifier, for: indexPath) as? LinkCell {
                
                cell.ownProfile = isOwnProfile
                cell.delegate = self
                cell.post = post
                
                return cell
            }
        case .youTubeVideo:
            if let cell = tableView.dequeueReusableCell(withIdentifier: YouTubeCell.identifier, for: indexPath) as? YouTubeCell {
                
                cell.ownProfile = isOwnProfile
                cell.delegate = self
                cell.post = post
                
                return cell
            }
        case .nothingPostedYet:
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: BlankContentCell.identifier, for: indexPath) as? BlankContentCell {
                
                cell.type = noPostsType
                cell.contentView.backgroundColor = self.tableView.backgroundColor
                
                return cell
            }
        case .singleTopic:
            if let cell = tableView.dequeueReusableCell(withIdentifier: FeedSingleTopicCell.identifier, for: indexPath) as? FeedSingleTopicCell {
                
                cell.post = post
                cell.delegate = self
                
                return cell
            }
        }
        
        
        return UITableViewCell()
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
        
        let post = posts[indexPath.row]
        let postType = post.type
        
        if post.title == "ad" {
            return UITableView.automaticDimension
        }
        
        if let _ = post.survey {
            return UITableView.automaticDimension
        }
        
        switch postType {
        case .nothingPostedYet:
            return self.view.frame.height-150
        default:
            return UITableView.automaticDimension
        }
        
    }
}
