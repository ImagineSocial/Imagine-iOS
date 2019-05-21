//
//  WebViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    var post = Post()
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
        
        if let url = URL(string: post.linkURL) {
            webView.load(URLRequest(url: url))
        }

    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
            if webView.estimatedProgress == 1 {
                progressView.isHidden = true
            }
        } else if keyPath == "title" {
            if let title = webView.title {
                progressView.isHidden = false
            }
        }
        
        
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toLastSite(_ sender: Any) {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @IBAction func toNextSite(_ sender: Any) {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    @IBAction func refresh(_ sender: Any) {
        webView.reload()
    }
    
}
