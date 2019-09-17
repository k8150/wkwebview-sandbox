//
//  ViewController.swift
//  wkwebview-sandbox
//
//  Created by haigo koji on 2019/09/15.
//  Copyright © 2019 haigo koji. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    var webView: WKWebView!
    
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //
        let userController = WKUserContentController()
        userController.add(self, name: "showAlert")
        userController.add(self, name: "showImage")
        //
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = userController
        
        let frame = CGRect(
            x: 0,
            y: self.statBarHeight(),
            width: self.viewWidth(),
            height: self.viewHeight() - self.statBarHeight()
        )
        
        webView = WKWebView(
            frame: frame,
            configuration: webConfiguration
        )
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        self.view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        //
        guard let path: String = Bundle.main.path(forResource: "index", ofType: "html") else { return }
        let localHTMLUrl = URL(fileURLWithPath: path, isDirectory: false)
        webView.loadFileURL(localHTMLUrl, allowingReadAccessTo: localHTMLUrl)
    }
}

extension ViewController: WKNavigationDelegate {
}

extension ViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        switch message.name {
            case "showAlert":
                let alert = UIAlertController(title: message.name, message: body, preferredStyle: .alert)
                present(alert, animated: true, completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        alert.dismiss(animated: true, completion: nil)
                    })
                })
            
            case "showImage":
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                guard let viewController = storyboard.instantiateViewController(withIdentifier: "ImageViewController") as? ImageViewController else { return }
                viewController.currentPage = Int(message.body as! String)!
                present(viewController, animated: true)
            
            default: break
        }
    }
}

extension ViewController: WKUIDelegate {
}

extension UIViewController {
    func viewWidth() -> CGFloat { return self.view.frame.width }
    func viewHeight() -> CGFloat { return self.view.frame.height }
    func navBarWidth() -> CGFloat { return self.navigationController?.navigationBar.frame.size.width ?? 0 }
    func navBarHeight() -> CGFloat { return self.navigationController?.navigationBar.frame.size.height ?? 0}
    func statBarWidth() -> CGFloat { return UIApplication.shared.statusBarFrame.width }
    func statBarHeight() -> CGFloat { return UIApplication.shared.statusBarFrame.height }
}
