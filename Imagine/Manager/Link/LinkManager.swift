//
//  LinkManager.swift
//  Imagine
//
//  Created by Don Malte on 11.06.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import Foundation
import SwiftLinkPreview

class LinkManager {
    
    private static let slp = SwiftLinkPreview(session: URLSession.shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, cache: InMemoryCache())

    
    static func getLink(url: String?, completion: @escaping (Link?, PostType) -> Void) {
        
        guard let url = url else {
            completion(nil, .link)
            return
        }
        
        switch url {
        case let string where string.contains(".mp4"):
            let size = string.getURLVideoSize()

            let fullLink = Link(url: url, mediaHeight: size.height, mediaWidth: size.width)
            completion(fullLink, .GIF)
        case let string where string.contains("music.apple.com") || string.contains("open.spotify.com") || string.contains("deezer.page.link"):
            getSongwhipLink(urlString: url) { link in
                guard let link = link else {
                    completion(nil, .link)
                    return
                }

                completion(link, .music)
            }
        case let string where string.youtubeID != nil:
            getSongwhipLink(urlString: url) { link in
                guard let link = link else {
                    
                    self.getLinkPreview(urlString: url) { link in
                        completion(link, .youTubeVideo)
                    }
                    return
                }

                completion(link, .music)
            }
        default:
            getLinkPreview(urlString: url) { link in
                completion(link, .link)
            }
        }
        
        completion(nil, .link)
    }
    
    static func getSongwhipLink(urlString: String, completion: @escaping (Link?) -> Void) {
        
        guard let url = URL(string: "https://songwhip.com/") else {
            
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = "{\"url\":\"\(urlString)\"}"
        request.httpBody = body.data(using: .utf8)
        
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                      let type = json["type"] as? String,
                      let name = json["name"] as? String,
                      let releaseDate = json["releaseDate"] as? String,
                      let url = json["url"] as? String,
                      let musicImage = json["image"] as? String,
                      let artistData = json["artists"] as? [[String: Any]],
                      let date = self.getReleaseDate(stringDate: releaseDate),
                      let artistInfo = artistData.first,
                      let artistName = artistInfo["name"] as? String,
                      let artistImage = artistInfo["image"] as? String
                else {
                    print("Couldnt get the jsonData from Songwhip API Call")
                    completion(nil)
                    return
                }
                
                let songwhip = Songwhip(title: name, musicType: type, releaseDate: date, artist: SongwhipArtist(name: artistName, image: artistImage), musicImage: musicImage)
                
                self.getLinkPreview(urlString: url) { link in
                    guard var link = link else {
                        completion(nil)
                        return
                    }
                    
                    link.songwhip = songwhip

                    completion(link)
                }
                
            } catch {
                print("Couldnt get the jsonData from Songwhip API Call")
                completion(nil)
            }
            
        }.resume()
    }
    
    //MARK: Get LinkPreview
    
    static func getLinkPreview(urlString: String, completion: @escaping (Link?) -> Void) {
        guard urlString.isValidURL else {
            completion(nil)
            return
        }
        
        slp.preview(urlString, onSuccess: { response in
            let link = Link(url: urlString, shortURL: response.canonicalUrl, imageURL: response.image, linkTitle: response.title, description: response.description)
            
            completion(link)
        }) { error in
            print("We have an error: \(error.localizedDescription)")
            
            completion(nil)
        }
    }
    
    //MARK: Get Music Release Date
    static func getReleaseDate(stringDate: String) -> Date? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let date = dateFormatter.date(from: stringDate)
        
        return date
    }
}
