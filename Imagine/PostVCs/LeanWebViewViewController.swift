//
//  LeanWebViewViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 26.06.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import WebKit

class LeanWebViewViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    @IBOutlet weak var webView: WKWebView!
    
    var link: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        if let link = link {
            let request = URLRequest(url: link)
            webView.load(request)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url, let host = url.host, !host.hasPrefix("songwhip.com") && !host.hasPrefix("vars.hotjar.com")  {
          
          UIApplication.shared.open(url)
          decisionHandler(.cancel)
            self.dismiss(animated: true) {
                print("Dismissed")
            }
        } else {
            decisionHandler(.allow)
        }
        
//        if navigationAction.navigationType == .linkActivated  {
//
//        }
    }
    
    @IBAction func dismissButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
