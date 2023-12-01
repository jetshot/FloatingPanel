//
//  NCCommentModalViewController.swift
//  aaa
//
//  Created by yawa on 12/1/23.
//

import UIKit

class NCCommentModalViewController: UIViewController {
    var commentView = CommentView()
    var commentViewBottomConstraint: NSLayoutConstraint?
    var keyboardFrameMinY: CGFloat = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowNotification(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideNotification(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        setupView()
    }
    
    private func setupView() {
        commentView = CommentView()
        commentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(commentView)
        commentView.commentViewBottomConstraint = commentViewBottomConstraint
        commentViewBottomConstraint = commentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        commentViewBottomConstraint?.isActive = true
        commentView.heightAnchor.constraint(equalToConstant: 144).isActive = true
        commentView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        commentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        commentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
    }

    @objc func keyboardWillShowNotification(notification: Notification) {
        let frameUserInfo: Any? = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
        if let keyboardFrame = (frameUserInfo as? NSValue)?.cgRectValue {
            keyboardFrameMinY = -keyboardFrame.height
            commentViewBottomConstraint?.constant = -keyboardFrame.minY - (UIDevice.current.userInterfaceIdiom == .phone ? 430 * PT : 760 * PT)
            UIView.animate(withDuration: 0.3) {
                self.commentView.layoutIfNeeded()
            }
        }
    }

    @objc func keyboardWillHideNotification(notification: Notification) {
        commentViewBottomConstraint?.constant = 50
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
}
