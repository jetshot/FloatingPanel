//
//  CommentView.swift
//  aaa
//
//  Created by yawa on 12/1/23.
//
import UIKit
import FloatingPanel

protocol CommentViewDelegate: AnyObject {
    func saveComment(comment: String)
    func updateState(_ state: FloatingPanelState)
}
class CommentView: UIView, UITextViewDelegate {
    @IBOutlet private weak var label: UILabel!
    @IBOutlet weak var commentTV: UITextView!
    @IBOutlet weak var submitBtn: UIButton!
    weak var delegate: CommentViewDelegate?
    // Add a placeholder label
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter comment"
        label.textColor = UIColor.lightGray
        return label
    }()

    @IBOutlet weak var bottom: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    var commentViewBottomConstraint: NSLayoutConstraint!
    var currentBottomConstraint: CGFloat = 0
    override init(frame: CGRect) {
        super.init(frame: frame)
        let view = loadNib()
        setup()
        setupTextView()
        setupPlaceholder()
    }

    init() {
        super.init(frame: .zero)
        let view = loadNib()
        setup()
        setupTextView()
        setupPlaceholder()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        setupTextView()
        setupPlaceholder()
    }
    
    private func setup() {
        if bottomConstraint?.constant != nil {
            currentBottomConstraint = bottomConstraint.constant
        }
        submitBtn.tintColor = UIColor.blue
    }
    
    @discardableResult func loadNib() -> UIView {
       let view = Bundle.main.loadNibNamed("CommentView", owner: self, options: nil)?.first as? UIView
       view?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
       view?.frame = bounds
       addSubview(view!)
       return view!
   }

    private func setupTextView() {
        commentTV.delegate = self
    }

    private func setupPlaceholder() {
        addSubview(placeholderLabel)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: commentTV.leadingAnchor, constant: 5),
            placeholderLabel.topAnchor.constraint(equalTo: commentTV.topAnchor, constant: 8)
        ])
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.delegate?.updateState(.lastQuart)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        self.delegate?.updateState(.tip)
    }

    func textViewDidChange(_ textView: UITextView) {
        let maxCharCount = 1000
        let currentCharCount = textView.text.count
        let remainingCharCount = maxCharCount - currentCharCount

        if remainingCharCount >= 0 {
            label.text = "残り\(remainingCharCount)文字"
        } else {
            // Limit the text to the maximum character count
            let newText = String(textView.text.prefix(maxCharCount))
            textView.text = newText
            label.text = "残り0文字"
        }

        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    @IBAction func submitTapped(_ sender: Any) {
        guard let comment = self.commentTV.text else {
            return
        }
        self.clearTextView()
        self.textViewDidChange(self.commentTV)

        self.delegate?.saveComment(comment: comment)
    }
    
    func showKeyboard() {
        self.commentTV.becomeFirstResponder()
    }
    
    func clearTextView() {
        self.commentTV.text = ""
    }
}
