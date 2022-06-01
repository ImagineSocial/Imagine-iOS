//
//  AddOnPlaylistCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 17.11.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

enum StreamingService {
    case AppleMusic
    case Spotify
}

class AddOnPlaylistCollectionViewCell: BaseAddOnCollectionViewCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var albumImageViewOuterStackView: UIStackView!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var firstAlbumImageView: UIImageView!
    @IBOutlet weak var secondAlbumImageView: UIImageView!
    @IBOutlet weak var thirdAlbumImageView: UIImageView!
    @IBOutlet weak var fourthAlbumImageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var thanksButton: DesignableButton!
    @IBOutlet weak var addPostButton: UIButton!
    
    @IBOutlet weak var trackTableView: UITableView!
    @IBOutlet weak var appleMusicPlaylistButton: UIButton!
    @IBOutlet weak var spotifyPlaylistButton: UIButton!
    
    //MARK:- Variables
    var openTrackIndexPath: IndexPath?
    weak var delegate: AddOnCellDelegate?
    
    private let trackTableViewCellIdentifier = "AddOnPlaylistTrackTableViewCell"
    private let db = FirestoreRequest.shared.db
    
    var tracks = [Post]()
    
    var info: AddOn? {
        didSet {
            if let info = info {
                getTracks()
                info.delegate = self
                titleLabel.text = info.headerTitle
                descriptionLabel.text = info.description
                
                if let _ = info.appleMusicPlaylistURL {
                    appleMusicPlaylistButton.isHidden = false
                }
                if let _ = info.spotifyPlaylistURL {
                    spotifyPlaylistButton.isHidden = false
                }
            }
        }
    }
    
    //MARK:- Cell Lifecycle
    override func awakeFromNib() {
        trackTableView.delegate = self
        trackTableView.dataSource = self
        trackTableView.tableFooterView = UIView()   //to remove the empty cell's separators
        
        trackTableView.register(UINib(nibName: "AddOnPlaylistTrackTableViewCell", bundle: nil), forCellReuseIdentifier: trackTableViewCellIdentifier)
       
        //DesignStuff
        albumImageViewOuterStackView.layer.cornerRadius = 4
        containerView.layer.cornerRadius = cornerRadius
        contentView.layer.cornerRadius = cornerRadius
    }
    
    override func prepareForReuse() {
        appleMusicPlaylistButton.isHidden = true
        spotifyPlaylistButton.isHidden = true
        self.tracks.removeAll()
        
        let imageViews = [firstAlbumImageView, secondAlbumImageView, thirdAlbumImageView, fourthAlbumImageView]
        for view in imageViews {
            view!.image = nil
        }
    }
    
    //MARK:- Get Data
    func getTracks() {
        if let info = info {
            info.items.removeAll()  //When you added a new one and the former were still in
            info.getItems(postOnly: true)
        }
    }
    
    //MARK:- Set UI
    func setHeaderAlbumImages() {
        var index = 0
        let maxImages = tracks.count
        let imageViews = [firstAlbumImageView, secondAlbumImageView, thirdAlbumImageView, fourthAlbumImageView]
        
        let maxCount: Int!
        if maxImages < 4 {
            maxCount = maxImages
        } else {
            maxCount = 4
        }
        
        while index < maxCount {
            let track = tracks[index]
            let imageView = imageViews[index]
            
            if let music = track.music {
                if let url = URL(string: music.musicImageURL) {
                    imageView!.sd_setImage(with: url, completed: nil)
                }
            }
            
            index+=1
        }
    }
    
    //MARK:- Change UI
    func openMusicPlaylist(type: StreamingService) {
        if let info = info {
            var url: URL?
            switch type {
            case .AppleMusic:
                if let urlString = info.appleMusicPlaylistURL {
                    if let appleUrl = URL(string: urlString) {
                        url = appleUrl
                    }
                }
            case .Spotify:
                if let urlString = info.spotifyPlaylistURL {
                    if let spotifyUrl = URL(string: urlString) {
                        url = spotifyUrl
                    }
                }
            }
            
            if let url = url {
                UIApplication.shared.open(url)
            }
        }
    }
    
    //MARK:- IBACtions
    @IBAction func addPostTapped(_ sender: Any) {
        if let info = info {
            delegate?.newPostTapped(addOn: info)
        }
    }
    
    @IBAction func thanksButtonTapped(_ sender: Any) {
        if let info = info {
            delegate?.thanksTapped(info: info)
        }
    }
    
    @IBAction func appleMusicPlaylistButtonTapped(_ sender: Any) {
        openMusicPlaylist(type: .AppleMusic)
    }
    
    @IBAction func spotifyPlaylistButtonTapped(_ sender: Any) {
        openMusicPlaylist(type: .Spotify)
    }
}

//MARK:- AddOnDelegate
extension AddOnPlaylistCollectionViewCell: AddOnDelegate {
    
    func fetchCompleted() {
        if let info = info {
            for item in info.items {
                if let track = item.item as? Post {
                    self.tracks.append(track)
                }
            }
            
            self.setHeaderAlbumImages()
            self.trackTableView.reloadData()
        }
    }
    
    func itemAdded(successfull: Bool) {
        print("not needed")
    }
    
    
}

//MARK:- TableView DataSource / Delegate
extension AddOnPlaylistCollectionViewCell: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = tracks[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: trackTableViewCellIdentifier, for: indexPath) as? AddOnPlaylistTrackTableViewCell {
            
            if let _ = track.music {
                cell.track = track
            }
            cell.delegate = self
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let openIndexPath = self.openTrackIndexPath {
            if let cell = tableView.cellForRow(at: openIndexPath) as? AddOnPlaylistTrackTableViewCell {
                cell.closeWebView()
            }
            if openIndexPath == indexPath {
                updateTableViewCellHeights()
                openTrackIndexPath = nil
                return
            }
        }
        
        if let cell = tableView.cellForRow(at: indexPath) as? AddOnPlaylistTrackTableViewCell {
            //Make the webView bigger and load the songwhip website link
            cell.expandWebView()
            
            openTrackIndexPath = indexPath
            updateTableViewCellHeights()
        }
    }
    
    func updateTableViewCellHeights() {
        trackTableView.beginUpdates()
        trackTableView.endUpdates()
    }
    
}

extension AddOnPlaylistCollectionViewCell: PlaylistTrackDelegate {
    func closeWebView() {
        updateTableViewCellHeights()
    }
}
