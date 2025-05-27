//
//  ChatViewController.swift
//  RealtimeKitUI
//
//  Created by Shaunak Jagtap on 21/01/23.
//

import UIKit
import RealtimeKit
import MobileCoreServices
import UniformTypeIdentifiers

public class RtkChatViewController: RtkBaseViewController, NSTextStorageDelegate, SetTopbar {
    
    public let topBar: RtkNavigationBar = {
        let topBar = RtkNavigationBar(title: "Chat")
        return topBar
    }()
    // MARK: - Properties
    public var shouldShowTopBar: Bool = true
    fileprivate var messages: [ChatMessage]?
    let messageTableView = UITableView()
    public let messageTextView = UITextView()
    var messageTextViewHeightConstraint: NSLayoutConstraint?
    var messageInfoErrorViewHeightConstraint: NSLayoutConstraint?
    var chatSelectorBaseViewHeightConstraint: NSLayoutConstraint?
    var messageTextViewBottomConstraint: NSLayoutConstraint?
    var textBoxBaseBottomConstraint: NSLayoutConstraint?
    var selectedParticipant: RtkRemoteParticipant?
    static let keyEveryOne = "everyone"
    private let everyOneText = "Everyone in meeting"
    let chatSelectorLabel = RtkUIUtility.createLabel(alignment: .left)
    public var notificationBadge = RtkNotificationBadgeView()
    private var isNewChatAvailable : Bool = false
    private var textBoxBaseView: UIView = { let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view }()
    private var textViewInfoLabel: RtkLabel = {
        let label =  RtkUIUtility.createLabel(alignment: .right)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 2
        label.backgroundColor = .green
        label.font = UIFont.systemFont(ofSize: 10)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    private let messageTextViewHeight = 48.0
    private let texInfoLabelViewHeight = 12.0
    
    private let minimumCharacterCountToShowWarning = 20
    
    private var enableMessageRateLimiting = false
    private var messageWithinMaxCharacterLimit = true
    
    private lazy var maxCharacterLimit: Int = {
        return Int(self.meeting.chat.characterLimit)
    }()
    
    let paddingTextBox = 8.0
    
    let sendFileButtonDisabledView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignLibrary.shared.color.background.shade1000
        view.alpha = 0.8
        return view
    }()
    
    let sendTextViewDisabledView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = DesignLibrary.shared.color.background.shade1000
        view.alpha = 0.2
        return view
    }()
    
    let sendTextPermissionDisabledView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignLibrary.shared.color.background.shade1000
        view.alpha = 0.4
        return view
    }()
    
    let sendFileButton = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_chat_add"))), rtkButtonState: .focus)
    let sendImageButton = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_image"))), rtkButtonState: .active)
    let sendMessageButton = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_chat_send"))), rtkButtonState: .active)
    
    var documentsViewController: DocumentsViewController?
    let imagePicker = UIImagePickerController()
    let backgroundColor = DesignLibrary.shared.color.background.shade1000
    
    let spaceToken = DesignLibrary.shared.space
    let colorToken = DesignLibrary.shared.color
    
    let lblNoPollExist: RtkLabel = {
        let label = RtkUIUtility.createLabel(text: "No messages! \n\n Chat messages will appear here")
        label.accessibilityIdentifier = "No_Chat_Message_Label"
        label.numberOfLines = 0
        return label
    }()
    
    let activityIndicator = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = DesignLibrary.shared.color.brand.shade500
        indicator.startAnimating()
        return indicator
    }()
    
    var viewDidAppear = false
    var messageLoaded = false
    let meetingObserver: RtkMeetingEventListener
    private var participantSelectionController: ChatParticipantSelectionViewController?
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        topBar.set(.top(self.view, self.view.safeAreaInsets.top))
    }
    
    override public init(meeting: RealtimeKitClient) {
        meetingObserver = RtkMeetingEventListener(rtkClient: meeting)
        super.init(meeting: meeting)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        meeting.addChatEventListener(chatEventListener: self)
        self.view.accessibilityIdentifier = "Chat_Screen"
        sendMessageButton.accessibilityIdentifier = "Send_Chat_Button"
        messageTextView.accessibilityIdentifier = "Input_Message_TextView"
        sendFileButton.accessibilityIdentifier = "Select_FileType_Button"
        setupViews()
        addWaitingRoom {}
        setUpReconnection(failed: {}, success: {})
        loadChatMessages()
        addPermissionUpdateObserver()
        meetingObserver.observeParticipantLeave { [weak self] participant in
            guard let self = self else{ return }
            self.removeParticipant(participantUserId: participant.userId)
        }
        
        meetingObserver.observeParticipantJoin { [weak self] participant in
            guard let self = self else { return }
            if let cont = self.participantSelectionController {
                var participants = meeting.participants.joined
                participants.removeAll { participant in
                    participant.id == self.meeting.localUser.id
                }
                cont.setParticipants(participants: participants)
                cont.onParticipantJoin(userId: participant.userId)
            }
        }
        
        showNotiificationBadge()
        showWarning(characterUsed: 0, maxCharacter: maxCharacterLimit)
    }
    
    
    @objc func showChatParticipantSelectionOverlay() {
        let controller = ChatParticipantSelectionViewController()
        var participants = meeting.participants.joined
        participants.removeAll { participant in
            participant.id == meeting.localUser.id
        }
        controller.setParticipants(participants: participants)
        controller.delegate = self
        controller.selectedParticipant = selectedParticipant
        controller.view.backgroundColor = self.view.backgroundColor
        self.view.addSubview(controller.view)
        controller.view.set(.top(self.topBar), .sameLeadingTrailing(self.view), .bottom(self.view))
        controller.addTopBar(dismissAnimation: true) { [weak self]  in
            guard let self = self else {return}
            self.participantSelectionController?.view.removeFromSuperview()
            self.participantSelectionController = nil
            self.didSelectChat(withParticipant: self.selectedParticipant)
        }
        
        self.participantSelectionController = controller
    }
    
    private func selectParticipant(withParticipant participant: RtkRemoteParticipant) {
        self.selectedParticipant = participant
    }
    
    func addPermissionUpdateObserver() {
        rtkSelfListener.observeSelfPermissionChanged { [weak self] in
            guard let self = self else {
                return
            }
            self.refreshPermission()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppear = true
        loadMessageToUI()
    }
    
    private func loadChatMessages() {
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.set(.centerView(self.view))
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            if let participant = selectedParticipant {
                self.messages = meeting.chat.getPrivateChatMessages(participant: participant)
            } else {
                self.messages = self.meeting.chat.messages
            }
            self.messageLoaded = true
            self.loadMessageToUI()
        }
    }
    
    private func loadMessageToUI() {
        DispatchQueue.main.async {
            if self.viewDidAppear && self.messageLoaded {
                self.messageTextView.placeholder = "Message.."
                self.reloadMessageTableView()
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        chatSelectorBaseViewHeightConstraint?.constant = 0
        chatSelectorLabel.superview?.isHidden = true
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            let bottomOffset = UIScreen.main.bounds.height  - CGRectGetMaxY(self.view.frame)
            textBoxBaseBottomConstraint?.constant = -(keyboardHeight - view.safeAreaInsets.bottom - bottomOffset + paddingTextBox)
            textBoxBaseBottomConstraint?.isActive = true
            
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        chatSelectorLabel.superview?.isHidden = false
        chatSelectorBaseViewHeightConstraint?.constant = messageTextViewHeight
        textBoxBaseBottomConstraint?.constant = 0
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Setup Views
    private func setupViews() {
        // configure messageTableView
        textViewInfoLabel.backgroundColor = backgroundColor
        messageTableView.backgroundColor = backgroundColor
        messageTableView.separatorStyle = .none
        self.view.backgroundColor = backgroundColor
        messageTableView.delegate = self
        messageTableView.keyboardDismissMode = .onDrag
        messageTableView.dataSource = self
        messageTableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        messageTableView.register(FileMessageCell.self, forCellReuseIdentifier: "FileMessageCell")
        messageTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lblNoPollExist)
        lblNoPollExist.set(.centerView(view), .leading(view, spaceToken.space5))
        view.addSubview(messageTableView)
        // configure messageTextField
        messageTableView.rowHeight = UITableView.automaticDimension
        messageTextView.textStorage.delegate = self
        messageTextView.font = UIFont.boldSystemFont(ofSize: 14)
        messageTextView.isScrollEnabled = true
        messageTextView.backgroundColor = DesignLibrary.shared.color.background.shade900
        let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypeNameTextField ?? .rounded
        messageTextView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one,
                                                                                         radius: borderRadiusType)
        messageTextView.clipsToBounds = true
        messageTextView.delegate = self
        messageTextView.textColor = .black
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self.textBoxBaseView)
        textBoxBaseView.addSubview(textViewInfoLabel)
        textBoxBaseView.addSubview(messageTextView)
        self.addTopBar(dismissAnimation: true) { [weak self] in
            self?.goBack()
        }
        
        // configure sendButton
        let fileIcon = ImageProvider.image(named: "icon_chat_add")
        sendFileButton.setImage(fileIcon, for: .normal)
        sendFileButton.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
        textBoxBaseView.addSubview(sendFileButton)
        sendFileButton.set(.width(messageTextViewHeight))
        sendFileButton.addSubview(sendFileButtonDisabledView)
        sendFileButtonDisabledView.set(.fillSuperView(sendFileButton))
        sendMessageButton.set(.width(messageTextViewHeight))
        sendMessageButton.backgroundColor = rtkSharedTokenColor.brand.shade500
        sendMessageButton.clipsToBounds = true
        sendMessageButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        textBoxBaseView.addSubview(sendMessageButton)
        let chatSelectorView = UIView()
        chatSelectorView.backgroundColor = DesignLibrary.shared.color.background.shade900
        let imageView = RtkUIUtility.createImageView(image: RtkImage(image:ImageProvider.image(named: "icon_up_arrow")))
        chatSelectorLabel.text = everyOneText
        chatSelectorLabel.adjustsFontSizeToFitWidth = true
        chatSelectorView.addSubview(chatSelectorLabel)
        chatSelectorView.addSubview(imageView)
        view.addSubViews(chatSelectorView)
        let padding: CGFloat = 16
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.showChatParticipantSelectionOverlay))
        chatSelectorView.addGestureRecognizer(tap)
        // Disable autoresizing mask constraints
        chatSelectorView.translatesAutoresizingMaskIntoConstraints = false
        chatSelectorLabel.translatesAutoresizingMaskIntoConstraints = false
        chatSelectorView.addSubview(notificationBadge)
        let notificationBadgeHeight = rtkSharedTokenSpace.space4
        notificationBadge.set(.centerY(imageView),
                              .after(chatSelectorLabel, padding, .greaterThanOrEqual),
                              .height(notificationBadgeHeight),
                              .width(notificationBadgeHeight*2.5, .lessThanOrEqual))
        notificationBadge.layer.cornerRadius = notificationBadgeHeight/2.0
        notificationBadge.layer.masksToBounds = true
        notificationBadge.backgroundColor = rtkSharedTokenColor.brand.shade500
        notificationBadge.isHidden = true
        imageView.set(.centerY(chatSelectorView),
                      .trailing(chatSelectorView, padding),
                      .width(rtkSharedTokenSpace.space5),
                      .after(notificationBadge, padding*0.6, .greaterThanOrEqual))
        // add constraints
        let constraints = [
            chatSelectorView.leadingAnchor.constraint(equalTo: textBoxBaseView.leadingAnchor),
            chatSelectorView.trailingAnchor.constraint(equalTo: textBoxBaseView.trailingAnchor),
            chatSelectorView.bottomAnchor.constraint(equalTo: textBoxBaseView.topAnchor, constant: -paddingTextBox),
            
            chatSelectorLabel.leadingAnchor.constraint(equalTo: chatSelectorView.leadingAnchor, constant: padding),
            chatSelectorLabel.topAnchor.constraint(equalTo: chatSelectorView.topAnchor, constant: padding),
            chatSelectorLabel.bottomAnchor.constraint(equalTo: chatSelectorView.bottomAnchor, constant: -padding),
            
            messageTableView.topAnchor.constraint(equalTo: self.topBar.bottomAnchor),
            messageTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageTableView.bottomAnchor.constraint(equalTo: chatSelectorView.topAnchor, constant: -paddingTextBox),
            
            textBoxBaseView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: paddingTextBox),
            textBoxBaseView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -paddingTextBox),
            
            messageTextView.trailingAnchor.constraint(equalTo: sendMessageButton.leadingAnchor, constant: -paddingTextBox),
            messageTextView.topAnchor.constraint(equalTo: textBoxBaseView.topAnchor),
            messageTextView.leadingAnchor.constraint(equalTo: sendFileButton.trailingAnchor, constant: paddingTextBox),
            
            textViewInfoLabel.leadingAnchor.constraint(equalTo: messageTextView.leadingAnchor),
            textViewInfoLabel.trailingAnchor.constraint(equalTo: messageTextView.trailingAnchor),
            
            textViewInfoLabel.bottomAnchor.constraint(equalTo: textBoxBaseView.bottomAnchor),
            
            sendFileButton.leadingAnchor.constraint(equalTo: textBoxBaseView.leadingAnchor),
            sendFileButton.bottomAnchor.constraint(equalTo: textBoxBaseView.bottomAnchor),
            
            sendMessageButton.trailingAnchor.constraint(equalTo: textBoxBaseView.trailingAnchor),
            sendMessageButton.bottomAnchor.constraint(equalTo: textBoxBaseView.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        chatSelectorBaseViewHeightConstraint = chatSelectorView.heightAnchor.constraint(equalToConstant: messageTextViewHeight)
        chatSelectorBaseViewHeightConstraint?.isActive = true
        messageTextViewBottomConstraint = messageTextView.bottomAnchor.constraint(equalTo: textViewInfoLabel.topAnchor, constant: -paddingTextBox/2.0)
        messageTextViewBottomConstraint?.isActive = true
        textBoxBaseBottomConstraint = textBoxBaseView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        textBoxBaseBottomConstraint?.isActive = true
        messageTextViewHeightConstraint = messageTextView.heightAnchor.constraint(equalToConstant: getMessageTextViewHeight())
        messageTextViewHeightConstraint?.isActive = true
        messageInfoErrorViewHeightConstraint = textViewInfoLabel.heightAnchor.constraint(equalToConstant: 0)
        messageInfoErrorViewHeightConstraint?.isActive = true
        textBoxBaseView.addSubview(sendTextPermissionDisabledView)
        sendTextPermissionDisabledView.set(.top(messageTextView),
                                           .bottom(sendMessageButton),
                                           .leading(messageTextView),
                                           .trailing(sendMessageButton))
        
        textBoxBaseView.addSubview(sendTextViewDisabledView)
        
        sendTextViewDisabledView.set(.top(messageTextView),
                                     .bottom(sendMessageButton),
                                     .leading(messageTextView),
                                     .trailing(sendMessageButton))
        refreshPermission()
    }
    
    
    private func showWarning(characterUsed: Int, maxCharacter: Int) {
        let characterLeft = maxCharacter - characterUsed
        if characterLeft <= minimumCharacterCountToShowWarning {
            makeMessageInfoLabel(hidden: false)
            if characterLeft < 0 {
                messageWithinMaxCharacterLimit = false
                showErrorOnCharacterCount(max:maxCharacter)
            } else {
                messageWithinMaxCharacterLimit = true
                if characterLeft == 0 {
                    textViewInfoLabel.text = "No character left"
                }else {
                    textViewInfoLabel.text = "Only \(characterLeft) characters left"
                }
                textViewInfoLabel.textColor = colorToken.status.warning
                messageCharacterLimit(enable: false)
            }
        }else {
            makeMessageInfoLabel(hidden: true)
            messageWithinMaxCharacterLimit = true
            messageCharacterLimit(enable: false)
        }
    }
    
    private func makeMessageInfoLabel(hidden: Bool) {
        guard let messageTextViewHeightConstraint =  self.messageTextViewHeightConstraint,
              let messageTextViewBottomConstraint =  self.messageTextViewBottomConstraint else {return}
        messageTextViewHeightConstraint.constant = getMessageTextViewHeight()
        if hidden {
            textViewInfoLabel.text = nil
            messageTextViewBottomConstraint.constant = 0
        }else {
            messageTextViewBottomConstraint.constant = -paddingTextBox/2.0
        }
        calculateTextInfoHeight()
    }
    
    private func showMessageToMessageInfoLabel(text: String) {
        textViewInfoLabel.text = text
        textViewInfoLabel.textColor = colorToken.textColor.onBackground.shade1000
        calculateTextInfoHeight()
    }
    
    private func showErrorOnCharacterCount(max: Int) {
        textViewInfoLabel.textColor = colorToken.status.danger
        textViewInfoLabel.text = "Max \(max) characters allowed"
        messageCharacterLimit(enable: true)
        calculateTextInfoHeight()
        
    }
    
    private func messageCharacterLimit(enable: Bool) {
        self.sendMessageButton.isEnabled = !enable
    }
    
    private func enableRateLimitButton(sendText: Bool, sendFile: Bool) {
        self.sendTextViewDisabledView.isHidden = !sendText
        self.sendFileButtonDisabledView.isHidden = !sendFile
        self.sendMessageButton.isEnabled = !sendText
    }
    
    private var timerCoolOfTimeForSendMessage: Timer?
    
    private func handleRateLimitError(error: ChatTextError?) -> Bool {
        if error?.code == .rateLimitBreached {
            if let textError = error as? ChatTextError.RateLimitBreached {
                showRateLimitText(coolDownTimeLeft: textError.secondsUntilReset)
            }
            return true
        }
        return false
    }
    
    private func handleRateLimitError(error: ChatFileError?) -> Bool {
        if error?.code == .rateLimitBreached {
            if let fileError = error as? ChatFileError.RateLimitBreached {
                showRateLimitText(coolDownTimeLeft: fileError.secondsUntilReset)
            }
            return true
        }
        return false
    }
    
    private func showRateLimitText(coolDownTimeLeft: Int64) {
        self.enableMessageRateLimiting = true
        messageTextView.resignFirstResponder()
        var timeLeft = coolDownTimeLeft
        self.timerCoolOfTimeForSendMessage = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {return}
            if timeLeft > 0 {
                self.showRateLimitError(coolDownTime: Int(timeLeft))
            }else {
                timer.invalidate()
            }
            timeLeft -= 1
        }
    }
    
    private func showRateLimitError(coolDownTime: Int) {
        textViewInfoLabel.textColor = colorToken.status.danger
        textViewInfoLabel.text = "Message limit reached, try again after \(coolDownTime) seconds"
        enableRateLimitButton(sendText: true, sendFile: true)
        calculateTextInfoHeight()
    }
    
    private func calculateTextInfoHeight() {
        var requiredLines = textViewInfoLabel.numberOfLinesRequired()
        if requiredLines > textViewInfoLabel.numberOfLines {
            requiredLines = textViewInfoLabel.numberOfLines
        }
        messageInfoErrorViewHeightConstraint?.constant = texInfoLabelViewHeight * Double(requiredLines)
    }
    
    private func removeParticipant(participantUserId: String) {
        if selectedParticipant?.userId == participantUserId {
            Shared.data.privateChatReadLookup.removeValue(forKey: participantUserId)
            setDefaultParticipantToEveryOne()
        }
        if let cont = self.participantSelectionController {
            var participants = meeting.participants.joined
            participants.removeAll { participant in
                participant.id == meeting.localUser.id
            }
            cont.setParticipants(participants: participants)
            cont.onRemove(userId: participantUserId)
        }
        
    }
    
    private func refreshPermission() {
        var canSendFiles = self.meeting.localUser.permissions.chat.canSendFiles
        var canSendText = self.meeting.localUser.permissions.chat.canSendText
        if self.meeting.localUser.permissions.chat.canSend == false {
            canSendText = false
            canSendFiles = false
        }
        showPermissionView(sendButton: canSendText, fileButton: canSendFiles)
        messageTextView.resignFirstResponder()
    }
    
    private func showPermissionView(sendButton: Bool, fileButton: Bool) {
        self.sendTextPermissionDisabledView.isHidden = sendButton
        self.sendFileButtonDisabledView.isHidden = fileButton
    }
    
    private func refreshPrivatePermission() {
        let canSendFiles = self.meeting.localUser.permissions.privateChat.canSendFiles
        let canSendText = self.meeting.localUser.permissions.privateChat.canSendText
        showPermissionView(sendButton: canSendText, fileButton: canSendFiles)
        messageTextView.resignFirstResponder()
    }
    
    private func createMoreMenu() {
        var menus = [MenuType]()
        menus.append(contentsOf: [.files, .images, .cancel])
        
        let moreMenu = RtkMoreMenu(features: menus, onSelect: { [weak self] menuType in
            switch menuType {
            case.images:
                self?.addImageButtonTapped()
            case .files:
                self?.addFileButtonTapped()
            default:
                print("Not Supported for now")
            }
        })
        moreMenu.accessibilityIdentifier = "Chat_File_Type_BottomSeet"
        moreMenu.show(on: view)
    }
    
    // MARK: - Actions
    
    @objc func goBack() {
        meeting.removeChatEventListener(chatEventListener: self)
        self.dismiss(animated: true)
    }
    
    @objc func menuTapped() {
        messageTextView.resignFirstResponder()
        createMoreMenu()
    }
    
    @objc func addFileButtonTapped() {
        var filePicker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            filePicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .plainText, .audio, .video, .movie, .image, .livePhoto], asCopy: false)
        } else {
            filePicker = UIDocumentPickerViewController(documentTypes: [], in: .import)
        }
        messageTextView.resignFirstResponder()
        filePicker.delegate = self
        present(filePicker, animated: true, completion: nil)
    }
    
    @objc func addImageButtonTapped() {
        messageTextView.resignFirstResponder()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    @objc func sendButtonTapped() {
        if !messageTextView.text.isEmpty {
            let spacing = CharacterSet.whitespacesAndNewlines
            let message = messageTextView.text.trimmingCharacters(in: spacing)
            
            var error: ChatTextError?
            if let id = selectedParticipant?.id, !id.isEmpty {
                error = meeting.chat.sendTextMessage(message: message, peerIds: [id])
            } else {
                error = meeting.chat.sendTextMessage(message: message)
            }
            
            if handleRateLimitError(error: error) {
                return
            }
            messageTextView.resignFirstResponder()
            messageTextView.text = ""
            showWarning(characterUsed: 0, maxCharacter: maxCharacterLimit)
            messageTextViewHeightConstraint?.constant = getMessageTextViewHeight()
            sendMessageButton.isEnabled = false
        }
    }
    private func getMessageTextViewHeight() -> CGFloat {
        
        return messageTextViewHeight
    }
    
    private func reloadMessageTableView() {
        if let participant = selectedParticipant {
            self.messages = meeting.chat.getPrivateChatMessages(participant: participant)
        } else {
            self.messages = self.meeting.chat.messages
        }
        lblNoPollExist.isHidden = (messages?.count ?? 0) > 0 ? true : false
        messageTableView.isHidden = !lblNoPollExist.isHidden
        if (messages?.count ?? 0) > 0 {
            messageTableView.reloadData(completion: {
                DispatchQueue.main.async { [weak self] in
                    let indexPath = IndexPath(row: (self?.messages?.count ?? 1)-1, section: 0)
                    self?.messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            })
        }
    }
}

extension RtkChatViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: - UITableViewDelegate, UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (messages?.count ?? 0) > indexPath.row, messages?[indexPath.row].type == .file
        {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "FileMessageCell", for: indexPath) as? FileMessageCell, let msg = messages?[indexPath.row] as? FileMessage {
                cell.fileTitleLabel.text =  msg.name
                cell.nameLabel.attributedText = MessageUtil().getTitleText(msg: msg)
                cell.fileSizeLabel.text = ByteCountFormatter.string(fromByteCount: msg.size, countStyle: .file)
                cell.fileTypeLabel.text = (URL(fileURLWithPath: msg.name).pathExtension).uppercased()
                if let fileURL = URL(string: msg.link) {
                    cell.downloadButtonAction = { [weak self] in
                        self?.messageTextView.resignFirstResponder()
                        DispatchQueue.main.async {
                            cell.downloadButton.showActivityIndicator()
                        }
                        self?.documentsViewController = DocumentsViewController(documentURL: fileURL)
                        if let vc = self?.documentsViewController {
                            vc.downloadFinishAction = {
                                DispatchQueue.main.async {
                                    cell.downloadButton.hideActivityIndicator()
                                }
                            }
                            self?.present(vc, animated: true, completion: nil)
                        }
                    }
                }
                return cell
            }
            
        } else if messages?[indexPath.row].type == .image {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as? MessageCell, let msg = messages?[indexPath.row] as? ImageMessage {
                if let fileURL = URL(string: msg.link) {
                    cell.message = messages?[indexPath.row]
                    cell.downloadButtonAction = { [weak self] in
                        self?.messageTextView.resignFirstResponder()
                        DispatchQueue.main.async {
                            cell.downloadButton.showActivityIndicator()
                        }
                        self?.documentsViewController = DocumentsViewController(documentURL: fileURL)
                        if let vc = self?.documentsViewController {
                            vc.downloadFinishAction = {
                                DispatchQueue.main.async {
                                    cell.downloadButton.hideActivityIndicator()
                                }
                            }
                            self?.present(vc, animated: true, completion: nil)
                        }
                    }
                }
                return cell
            }
        } else if let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as? MessageCell {
            cell.message = messages?[indexPath.row]
            return cell
        }
        
        return UITableViewCell(frame: .zero)
    }
}

extension RtkChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let url = info[UIImagePickerController.InfoKey.imageURL] as? URL {
            sendMessageButton.showActivityIndicator()
            
            if let id = selectedParticipant?.id, !id.isEmpty {
                self.meeting.chat.sendImageMessage(imageURL: url, peerIds: [id]) { [weak self] error in
                    guard let self = self else {return}
                    if handleRateLimitError(error: error) {
                        sendMessageButton.hideActivityIndicator()
                    }
                }
            } else {
                self.meeting.chat.sendImageMessage(imageURL: url) { [weak self] error in
                    guard let self = self else {return}
                    if handleRateLimitError(error: error) {
                        sendMessageButton.hideActivityIndicator()
                    }
                }
            }
        }
        dismiss(animated: true, completion: nil)
    }
}

extension RtkChatViewController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        sendMessageButton.showActivityIndicator()
        if let id = selectedParticipant?.id, !id.isEmpty {
            self.meeting.chat.sendFileMessage(fileURL: selectedFileURL, peerIds: [id]) { [weak self] error in
                guard let self = self else {return}
                if handleRateLimitError(error: error) {
                    sendMessageButton.hideActivityIndicator()
                }
            }
        } else {
            self.meeting.chat.sendFileMessage(fileURL: selectedFileURL) { [weak self] error in
                guard let self = self else {return}
                if handleRateLimitError(error: error) {
                    sendMessageButton.hideActivityIndicator()
                }
            }
        }
    }
}

extension RtkChatViewController: UITextViewDelegate {
    public func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.black {
            textView.text = nil
            textView.textColor = .lightGray
        }
    }
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.isEmpty, range.length >= 1 {
            // We should enable deleting of character when max character is reached
            return !enableMessageRateLimiting
        }
        return !enableMessageRateLimiting && messageWithinMaxCharacterLimit
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
        let messageTextViewHeight = getMessageTextViewHeight()
        if size.height > messageTextViewHeight {
            textBoxBaseBottomConstraint?.isActive = true
        }
        let topSpace = CGRectGetMaxY(textBoxBaseView.frame) - CGRectGetMaxY(self.topBar.frame) -  getMessageTextViewHeight()
        var height = size.height
        if size.height >= topSpace {
            height = topSpace
        }
        self.showWarning(characterUsed: textView.text.count, maxCharacter: maxCharacterLimit)
        messageTextViewHeightConstraint?.constant = height > messageTextViewHeight ? height : messageTextViewHeight
        view.layoutIfNeeded()
    }
}

extension RtkChatViewController: ChatParticipantSelectionDelegate {
    
    func didSelectChat(withParticipant participant: RtkRemoteParticipant?) {
        if let remoteParticipant = participant {
            selectedParticipant = remoteParticipant
            chatSelectorLabel.text = "To \(remoteParticipant.name) (Direct)"
            setReadFor(remoteParticipant)
            refreshPrivatePermission()
        } else {
            setDefaultParticipantToEveryOne()
        }
        
        showNotiificationBadge()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.reloadMessageTableView()
        })
        
        self.participantSelectionController?.view.removeFromSuperview()
        self.participantSelectionController = nil
    }
    
    private func showNotiificationBadge() {
        var showNotificationBadge = false
        for (_, value) in Shared.data.privateChatReadLookup {
            if value == true {
                showNotificationBadge =  true
                break;
            }
        }
        notificationBadge.isHidden = !showNotificationBadge
    }
    private func setDefaultParticipantToEveryOne() {
        selectedParticipant = nil
        Shared.data.privateChatReadLookup[Self.keyEveryOne] = false
        chatSelectorLabel.text = everyOneText
        refreshPermission()
    }
}

extension RtkChatViewController: RtkChatEventListener {
    
    public func onMessageRateLimitReset() {
        self.enableMessageRateLimiting = false
        timerCoolOfTimeForSendMessage?.invalidate()
        enableRateLimitButton(sendText: false, sendFile: false)
        showMessageToMessageInfoLabel(text: "You are allowed to send message again")
    }
    
    public func onNewChatMessage(message: ChatMessage) {
        notificationBadge.isHidden = true
        if let targetUserIds = message.targetUserIds {
            let forEveryOne =  targetUserIds.isEmpty
            if forEveryOne {
                if selectedParticipant == nil {
                    // Mean current selected is Everyone only, So don't do anything
                    if self.participantSelectionController != nil {
                        Shared.data.privateChatReadLookup[Self.keyEveryOne] = true
                    }
                }else {
                    // Message is for everone , but current selected user is different , so showing blue dot
                    notificationBadge.isHidden = false
                    Shared.data.privateChatReadLookup[Self.keyEveryOne] = true
                }
            } else {
                let localUserId = meeting.localUser.userId
                let messageReceiverIDs = targetUserIds
                    .filter { $0 != localUserId }
                messageReceiverIDs.forEach {
                    if selectedParticipant?.userId != $0 {
                        // If current selected user is not same then show blue dot
                        Shared.data.privateChatReadLookup[$0] = true
                        notificationBadge.isHidden = false
                    }else {
                        if self.participantSelectionController != nil {
                            Shared.data.privateChatReadLookup[$0] = true
                        }
                    }
                }
            }
            self.participantSelectionController?.newChatReceived(message: message)
        }
    }
    
    func setReadFor(_ participant: RtkRemoteParticipant) {
        Shared.data.privateChatReadLookup[participant.userId] = false
    }
    
    public  func onChatUpdates(messages: [ChatMessage]) {
        if isOnScreen {
            NotificationCenter.default.post(name: Notification.Name("NotificationAllChatsRead"), object: nil)
        }
        Shared.data.setChatReadCount(totalMessage: self.meeting.chat.messages.count)
        sendMessageButton.hideActivityIndicator()
        reloadMessageTableView()
    }
}

public extension UITableView {
    
    func reloadData(completion: @escaping () -> ()) {
        UIView.animate(withDuration: 0, animations: {
            self.reloadData()
        }, completion: { _ in
            completion()
        })
    }
    
    func scrollToFirstCell() {
        if numberOfSections > 0 {
            if numberOfRows(inSection: 0) > 0 {
                scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }
    
    func scrollToLastCell(animated: Bool) {
        if numberOfSections > 0 {
            let nRows = numberOfRows(inSection: numberOfSections - 1)
            if nRows > 0 {
                scrollToRow(at: IndexPath(row: nRows - 1, section: numberOfSections - 1), at: .bottom, animated: animated)
            }
        }
    }
    
    func stopScrolling() {
        
        guard isDragging else {
            return
        }
        
        var offset = self.contentOffset
        offset.y -= 1.0
        setContentOffset(offset, animated: false)
        
        offset.y += 1.0
        setContentOffset(offset, animated: false)
    }
    
    func scrolledToBottom() -> Bool {
        return contentOffset.y >= (contentSize.height - bounds.size.height)
    }
}

extension UITextView {
    
    private class PlaceholderLabel: UILabel { }
    
    private var placeholderLabel: RtkLabel {
        if let label = subviews.compactMap( { $0 as? RtkLabel }).first {
            return label
        } else {
            let label = RtkUIUtility.createLabel(alignment: .left)
            label.font = UIFont.boldSystemFont(ofSize: 14)
            label.textColor = rtkSharedTokenColor.textColor.onBackground.shade700
            label.numberOfLines = 0
            label.font = font
            addSubview(label)
            return label
        }
    }
    
    @IBInspectable
    var placeholder: String {
        get {
            return subviews.compactMap( { $0 as? PlaceholderLabel }).first?.text ?? ""
        }
        set {
            let placeholderLabel = self.placeholderLabel
            placeholderLabel.text = newValue
            placeholderLabel.numberOfLines = 0
            let width = frame.width - textContainer.lineFragmentPadding * 2
            let size = placeholderLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            placeholderLabel.frame.size.height = size.height
            placeholderLabel.frame.size.width = width
            placeholderLabel.frame.origin = CGPoint(x: textContainer.lineFragmentPadding, y: textContainerInset.top)
            
            textStorage.delegate = self
        }
    }
    
}

extension UITextView: NSTextStorageDelegate {
    
    public func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        if editedMask.contains(.editedCharacters) {
            placeholderLabel.isHidden = !text.isEmpty
        }
    }
}



