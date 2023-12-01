//
//  ViewController.swift
//  aaa
//
//  Created by yawa on 12/1/23.
//

import UIKit
import FloatingPanel
import WebKit
class NCSquareViewController: UIViewController, WKNavigationDelegate {
    private var webViewContainer: UIView?
    private var webView: WKWebView?
    private var panelController: FloatingPanelController?
    private var backBtn: UIBarButtonItem?
    private var isRoot = true
    private let vc = NCCommentModalViewController()
    var url: String = ""
    private var isFirstLoad = false
    private var topicID: String = ""
    private var loadingView: UIView?
    private var isPanelControllerSetup = false
    override func viewDidLoad() {
        super.viewDidLoad()
        showLoadingView()
        webViewSetup()
        notificationSetup()
        setPoints()
    }
    
    private func webViewSetup() {
        webView = WKWebView()
        webView?.navigationDelegate = self
        self.view = webView
        let url = URL(string: "https://www.hackingwithswift.com")!
        webView?.load(URLRequest(url: url))
        webView?.navigationDelegate = self
        webView?.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
        webView?.allowsBackForwardNavigationGestures = true
        
        let backButtonImage = UIImage(named: "navbar_back_round_button")
        let backButton = UIBarButtonItem(
            image: backButtonImage,
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
    }
    
    private func notificationSetup() {
        
    }
    
    private func panelControllerSetup() {
        panelController = FloatingPanelController()
        panelController?.delegate = self
    }
    
    private func panelControllerVCSetup() {
        panelController?.set(contentViewController: vc)
        panelController?.addPanel(toParent: self)
        panelController?.hide()
        vc.commentView.delegate = self
        isRoot = true
    }
    
    @objc func handleTopicIDNotification(_ notification: Notification) {
        if let userInfo = notification.object as? [String: Any],
           let topicID = userInfo["id"] as? String {
            self.topicID = topicID
            showKeyboard()
        }
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == #keyPath(WKWebView.url), let url = self.webView?.url  else {
            return
        }
        if isRoot == true && url.absoluteString.contains("message-board/detail") {
            isRoot = true
        } else {
            if url.absoluteString.contains("message-board?token=") || url.absoluteString.contains("tab=popular") {
                isRoot = true
                self.vc.commentView.clearTextView()
                self.vc.commentView.textViewDidChange(self.vc.commentView.commentTV)
            } else {
                isRoot = false
            }
        }
        
        if url.absoluteString.contains("message-board/detail") {
            if let match = url.absoluteString.range(of: "/detail/(\\d+)", options: .regularExpression) {
                let capturedNumber = String(url.absoluteString[match].dropFirst("/detail/".count))
                if self.topicID != capturedNumber {
                    self.vc.commentView.clearTextView()
                    self.vc.commentView.textViewDidChange(self.vc.commentView.commentTV)
                }
                self.topicID = capturedNumber
            }
            panelController?.show()
            panelController?.move(to: .tip, animated: false)
        } else {
            panelController?.hide()
        }
    }
    
    @objc private func backButtonTapped() {
        if isRoot == false  {
            panelController?.hide()
            self.webView?.goBack()
        }
        
        if self.webView?.canGoBack == true
        {
            self.webView?.goBack()
        }else
        {
            self.navigationController?.popViewController(animated: false)
        }
    }
    
    func showKeyboard() {
        vc.commentView.showKeyboard()
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if url.absoluteString.contains("nativecamp://messageboard-comment?id") {
                decisionHandler(.cancel)
                let urlString = url.absoluteString.split(separator: "=")
                let topicID = urlString[1]
                self.topicID = String(topicID)
                showKeyboard()
            } else if url.absoluteString.contains("nativecamp://messageboard-comment-hide") {
                decisionHandler(.cancel)
                panelController?.hide()
            } else if url.absoluteString.contains("nativecamp://messageboard-comment-show") {
                decisionHandler(.cancel)
                panelController?.show()
                panelController?.move(to: .tip, animated: true)
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideLoadingView()
        webView.evaluateJavaScript("document.title") { (result, error) in
            if let title = result as? String {
                self.title = title
            }
        }
        // Check if setup has already been performed
        if !isPanelControllerSetup {
            // Set up FloatingPanelController and its content view controller
            panelControllerSetup()
            panelControllerVCSetup()

            // Move FloatingPanelController to the desired state
            panelController?.move(to: .tip, animated: true)

            // Update the flag to indicate that setup has been performed
            isPanelControllerSetup = true
        }

        // Hide loading view when web content is fully loaded
        hideLoadingView()
    }
    
    private func showLoadingView() {
        loadingView = UIView(frame: view.bounds)
        loadingView?.backgroundColor = UIColor(white: 0, alpha: 0.5)
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = loadingView!.center
        activityIndicator.startAnimating()
        
        loadingView?.addSubview(activityIndicator)
        view.addSubview(loadingView!)
    }

    private func hideLoadingView() {
        loadingView?.removeFromSuperview()
        loadingView = nil
    }
    
    func setPoints() {
        let screenBounds = UIScreen.main.bounds
        let nativeBounds = UIScreen.main.nativeBounds
        let nativeScale = UIScreen.main.nativeScale
        let pxScreenWidth:CGFloat = nativeBounds.width;
        let ptScreenWidth:CGFloat = screenBounds.width;
        PT = pxScreenWidth/ptScreenWidth/nativeScale;
    }
}

extension NCSquareViewController: CommentViewDelegate {
    func saveComment(comment: String) {
        showLoadingView()
        let script = "js_savecomment('\(self.topicID)', '\(comment)');"
        self.webView?.evaluateJavaScript(script) { (result, error) in
            self.hideLoadingView()
            if let error = error {
                print("Error calling JavaScript function: \(error)")
            } else {
                self.vc.commentView.clearTextView()
                self.panelController?.move(to: .tip, animated: true)
                self.hideKeyboard()
            }
        }
    }
    
    func updateState(_ state: FloatingPanelState) {
        self.panelController?.show()
        var newState: FloatingPanelState = state
        if newState == .half && UIDevice.current.userInterfaceIdiom == .phone{
            newState = .lastQuart
        }
        if newState == .lastQuart && UIDevice.current.userInterfaceIdiom == .pad {
            newState = .half
        }
        self.panelController?.move(to: newState, animated: true)
    }
}

extension NCSquareViewController: FloatingPanelControllerDelegate {
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        return FloatingPanelLayoutWithCustomState()
    }
    
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        if fpc.state == .full {
            vc.commentViewBottomConstraint?.constant = vc.keyboardFrameMinY * PT
            UIView.animate(withDuration: 0.3) {
                self.vc.commentView.layoutIfNeeded()
            }
        }
        
        if fpc.state == .lastQuart {
            vc.commentViewBottomConstraint?.constant = vc.keyboardFrameMinY - (UIDevice.current.userInterfaceIdiom == .phone ? 430 * PT : 760 * PT)
            UIView.animate(withDuration: 0.3) {
                self.vc.commentView.layoutIfNeeded()
            }
        }
        
        if fpc.state == .half && UIDevice.current.userInterfaceIdiom == .phone{
            self.panelController?.move(to: .lastQuart, animated: true)
        }
        if fpc.state == .lastQuart && UIDevice.current.userInterfaceIdiom == .pad {
            self.panelController?.move(to: .half, animated: true)
        }
    }
    
}

extension FloatingPanelState {
    @objc(lastQuart) static let lastQuart: FloatingPanelState = FloatingPanelState(rawValue: "lastQuart", order: 750)
}

class FloatingPanelLayoutWithCustomState: FloatingPanelBottomLayout {
    override var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 18.0, edge: .top, referenceGuide: .safeArea),
            .lastQuart: FloatingPanelLayoutAnchor(fractionalInset: UIDevice.current.userInterfaceIdiom == .phone ? 0.6 : 0.5 * PT, edge: .bottom, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(fractionalInset: 0.4 * PT, edge: .bottom, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 69.0, edge: .bottom, referenceGuide: .safeArea),
        ]
    }
}

public var PT: CGFloat = 0


