//
//  WebVC.swift
//  Imagine
//
//  Created by Don Malte on 27.02.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit
import WebKit

class WebVC: UIViewController {

    var post: Post?
    var link: String?
    
    let webView = WKWebView()
    let progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        return progressView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupConstraints()
        setupToolbar()
        setUpLink()
        
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
    }
    
    private func setupNavigationBar() {
        let barButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissView))
        navigationItem.rightBarButtonItem = barButton
        navigationController?.navigationBar.backgroundColor = .systemBackground
    }
    
    private func setupConstraints() {
        view.addSubview(webView)
        view.addSubview(progressView)
        
        webView.constrain(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        progressView.constrain(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, height: 2)
    }
    
    private func setupToolbar() {
        let backButton = UIBarButtonItem(image: UIImage(systemName: "arrowtriangle.left"), style: .plain, target: self, action: #selector(toLastSite))
        backButton.width = 80
        
        let forwardButton = UIBarButtonItem(image: UIImage(systemName: "arrowtriangle.right"), style: .plain, target: self, action: #selector(toNextSite))
        forwardButton.width = 80
        
        let refreshButton = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain,  target: self, action: #selector(refreshSite))
        refreshButton.width = 80
                        
        let items = [backButton, forwardButton, refreshButton]
        let toolbar = UIToolbar(frame: .zero)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.isTranslucent = false
        toolbar.items = items
        
        view.addSubview(toolbar)
        toolbar.constrain(leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor, height: 44)
    }
    
    func setUpLink() {
        var linkURL = ""
        
        if let post = post, let url = post.link?.url {
            linkURL = url
        } else if let link = link {
            linkURL = link
        }
                
        let validUrlString = linkURL.hasPrefix("http") ? linkURL : "https://\(linkURL)"
        
        if let url = URL(string: validUrlString) {
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
            if let _ = webView.title {
                progressView.isHidden = false
            }
        }
    }
    
    @objc func dismissView() {
        dismiss(animated: true)
    }
    
    @objc func toLastSite() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @objc func toNextSite() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    @objc func refreshSite() {
        webView.reload()
    }
    
}
