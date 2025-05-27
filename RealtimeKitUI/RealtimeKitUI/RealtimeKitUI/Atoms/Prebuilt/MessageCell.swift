//
//  MessageCell.swift
//  RealtimeKitUI
//
//  Created by Shaunak Jagtap on 21/01/23.
//

import UIKit
import RealtimeKit

class MessageUtil {
    func getTitleText(msg: ChatMessage) -> NSAttributedString {
        let displayName = msg.displayName
        let time = msg.time
        
        // Define the attributes for display name
        let displayNameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.white
        ]
        
        // Define the attributes for time
        let timeAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.gray
        ]
        
        // Create attributed string for display name
        let displayNameAttributedString = NSAttributedString(string: displayName, attributes: displayNameAttributes)
        
        // Create attributed string for time
        let timeAttributedString = NSAttributedString(string: time, attributes: timeAttributes)
        
        // Create a mutable attributed string to combine display name and time
        let attributedString = NSMutableAttributedString()
        attributedString.append(displayNameAttributedString)
        attributedString.append(NSAttributedString(string: "  "))
        attributedString.append(timeAttributedString)
        return attributedString
    }
}

class MessageCell: UITableViewCell {
    
    // MARK: - Properties
    var downloadButtonAction: (() -> Void)?
    var message: ChatMessage? {
        didSet {
            updateUI()
        }

    }
    
    var downloadButton: RtkButton = {
        let button = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_down_arrow"))), rtkButtonState: .active)
        button.isUserInteractionEnabled = false
        button.tintColor = .white
        // Set additional button properties if needed
        return button
    }()
    
    class ImageView: UIImageView {
        var task: URLSessionTask?
    }
    
    var messageImageView: ImageView = {
        let imageView = ImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one, radius: AppTheme.shared.cornerRadiusTypeImageView)
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    
    let nameLabel: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .left)
        label.font = UIFont.boldSystemFont(ofSize: 12)
        return label
    }()
    let tokenColor = DesignLibrary.shared.color
    
    let tokenSpace = DesignLibrary.shared.space
    let messageLabel: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .left)
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(downloadButtonTapped))
        contentView.addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        nameLabel.text = nil
        messageLabel.attributedText = nil
        messageLabel.text = nil
        messageImageView.image = nil
    }

    
    @objc private func downloadButtonTapped() {
        // Call the download button action closure
        downloadButtonAction?()
    }
    
    private func getUrlString(message: TextMessage) -> NSAttributedString? {
        let attributedString = NSMutableAttributedString(string: message.message)
        
        let urlDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = urlDetector.matches(in: message.message, options: [], range: NSRange(location: 0, length: message.message.utf16.count))
        
        if matches.isEmpty {
            return nil
        }
        
        for match in matches {
            let range = match.range
            let url = (message.message as NSString).substring(with: range)
            attributedString.addAttribute(.link, value: url, range: range)
        }
        
        return attributedString
    }
    
    @objc func labelTapped(gesture: UITapGestureRecognizer) {
        guard let textView = gesture.view as? UILabel else {
            return
        }
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: textView.attributedText!)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        let textContainerSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        textContainer.size = textContainerSize
        
        let locationOfTouchInLabel = gesture.location(in: textView)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInLabel, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if indexOfCharacter < textStorage.length {
            var range = NSRange(location: 0, length: indexOfCharacter + 1)
            let attributes = textStorage.attributes(at: indexOfCharacter, effectiveRange: &range)
            
            if let link = attributes[.link] as? String {
                var formattedLink = link
                
                // Check if the link starts with "www." and doesn't have a protocol prefix
                if link.hasPrefix("www.") && !link.hasPrefix("http://") && !link.hasPrefix("https://") {
                    formattedLink = "http://" + link
                } else if !link.hasPrefix("http://") && !link.hasPrefix("https://") && link.contains(".") {
                    formattedLink = "http://www." + link
                }
                
                if let url = URL(string: formattedLink) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }


    
    func updateUI() {
        if let msg = message {
            
            // Set the attributed string to the nameLabel
            self.nameLabel.attributedText = MessageUtil().getTitleText(msg: msg)
            messageImageView.superview!.isHidden = true
            self.messageLabel.isHidden = true
            switch msg.type {
            case .text:
                messageLabel.numberOfLines = 0

                if let textMsg = msg as? TextMessage {
                    if let attributedString = getUrlString(message: textMsg) {
                        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(gesture:)))
                        self.messageLabel.attributedText = attributedString
                        messageLabel.addGestureRecognizer(tapGesture)
                        messageLabel.isUserInteractionEnabled = true
                    } else {
                        self.messageLabel.text = textMsg.message
                    }
                    self.messageLabel.isHidden = false
                }
            case .file:
                if let fileMsg = msg as? FileMessage {
                    self.messageLabel.text = fileMsg.name
                    self.messageLabel.isHidden = false
                }
            case .image:
                if let task = self.messageImageView.task {
                    task.cancel()
                }
                if let imgMsg = msg as? ImageMessage {
                   let result =  ImageUtil.shared.obtainImageWithPath(imagePath: imgMsg.link , completionHandler: { [weak self] image, url in
                       self?.messageImageView.superview!.isHidden = false
                       self?.messageImageView.image = image
                       self?.contentView.layoutIfNeeded()
                    })
                    
                    if let image = result.0 {
                        self.messageImageView.superview!.isHidden = false
                        self.messageImageView.image = image
                        if let task = result.1 {
                            self.messageImageView.task = task
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Setup Views
    func setupView() {
        contentView.backgroundColor = tokenColor.background.shade1000
        contentView.addSubview(nameLabel)
        nameLabel.set(.sameLeadingTrailing(contentView, tokenSpace.space3),
                      .top(contentView, tokenSpace.space2))
        
        let stackView = RtkUIUtility.createStackView(axis: .vertical, spacing: tokenSpace.space2)
        let baseImageView = UIView()
        baseImageView.addSubview(messageImageView)
        messageImageView.set(.leading(baseImageView),
                             .width(200),
                             .top(baseImageView),
                             .height(200),
                             .bottom(baseImageView))
        messageImageView.addSubview(downloadButton)
        downloadButton.backgroundColor = tokenColor.background.shade800
        downloadButton.set(.trailing(messageImageView),
                             .width(48),
                             .top(messageImageView),
                             .height(48))
        
        stackView.addArrangedSubviews(messageLabel, baseImageView)
        contentView.addSubview(stackView)
        stackView.set(.sameLeadingTrailing(contentView, tokenSpace.space3),
                      .below(nameLabel, tokenSpace.space2)
                      ,.bottom(contentView,tokenSpace.space2))
    }
}

