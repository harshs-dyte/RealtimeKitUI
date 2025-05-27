//
//  SetupViewController.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 24/11/22.
//

import UIKit
import AVFoundation
import RealtimeKit


public class MicToggleButton: RtkButton {

    lazy var rtkSelfListener: RtkEventSelfListener = {
        return RtkEventSelfListener(rtkClient: self.meeting)
    }()
    
    let completion: ((MicToggleButton)->Void)?
    
    private let meeting: RealtimeKitClient
    private weak var alertController: UIViewController!

    init(meeting: RealtimeKitClient, alertController: UIViewController, onClick:((MicToggleButton)->Void)? = nil, appearance: RtkButtonAppearance = AppTheme.shared.buttonAppearance) {
        self.meeting = meeting
        self.alertController = alertController
        self.completion = onClick
        super.init(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_mic_enabled"))), rtkButtonState: .active)
        self.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        self.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        self.accessibilityIdentifier = "Mic_Toggle_Button"

        self.setImage(ImageProvider.image(named: "icon_mic_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        self.addTarget(self, action: #selector(clickMic(button:)), for: .touchUpInside)
        setState()
    }

    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   private func setState() {
       let mediaPermission = self.meeting.localUser.permissions.media
       self.isEnabled = mediaPermission.canPublishAudio
       if self.getPermission() == false {
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
               self.isSelected = true
           }
       }
      
       
   }
    
    private func getPermission() -> Bool {
       let state = AVCaptureDevice.authorizationStatus(for: .audio)
        if state == .denied {
            return false
        }
        return true
    }
       
    @objc func clickMic(button: RtkButton) {
        if rtkSelfListener.isMicrophonePermissionGranted() {
            self.showActivityIndicator()
            self.rtkSelfListener.toggleLocalAudio(completion: { [weak self] isEnabled in
                guard let self = self else {return}
                button.hideActivityIndicator()
                button.isSelected = !isEnabled
                self.completion?(self)
            })
        }
    }
    
    public func clean() {
        rtkSelfListener.clean()
    }
    
    deinit {
        clean()
    }
    
}

public class VideoToggleButton: RtkButton {

    lazy var rtkSelfListener: RtkEventSelfListener = {
        return RtkEventSelfListener(rtkClient: self.meeting)
    }()
    
    let completion: ((VideoToggleButton)->Void)?
    
    private let meeting: RealtimeKitClient
    private weak var alertController: UIViewController!
    
    init(meeting: RealtimeKitClient, alertController: UIViewController, onClick:((VideoToggleButton)->Void)? = nil, appearance: RtkButtonAppearance = AppTheme.shared.buttonAppearance) {
        self.meeting = meeting
        self.alertController = alertController
        self.completion = onClick
        super.init(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_video_enabled"))), rtkButtonState: .active)
        self.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        self.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        self.accessibilityIdentifier = "Video_Toggle_Button"
        self.setImage(ImageProvider.image(named: "icon_video_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        self.addTarget(self, action: #selector(clickVideo(button:)), for: .touchUpInside)
        setState()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   private func setState() {
        let mediaPermission = self.meeting.localUser.permissions.media
        self.isEnabled = mediaPermission.canPublishVideo
       if self.getPermission() == false {
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
               self.isSelected = true
           }
       }
    }
    
    private func getPermission() -> Bool {
       let state = AVCaptureDevice.authorizationStatus(for: .video)
        if state == .denied {
            return false
        }
        return true
    }
       
    @objc func clickVideo(button: RtkButton) {
        if rtkSelfListener.isCameraPermissionGranted() {
            self.showActivityIndicator()
            self.rtkSelfListener.toggleLocalVideo(completion: { [weak self] isEnabled in
                guard let self = self else {return}
                button.hideActivityIndicator()
                button.isSelected = !isEnabled
                self.completion?(self)
            })
        }
    }
    
    public func clean() {
        rtkSelfListener.clean()
    }
    
    deinit {
        clean()
    }
    
}

public protocol SetupViewControllerDataSource : UIViewController {
    var delegate: SetupViewControllerDelegate? {get set}
}

public protocol SetupViewControllerDelegate: AnyObject {
    func userJoinedMeetingSuccessfully(sender: UIViewController)
}

public class RtkSetupViewController: RtkBaseViewController, KeyboardObservable, SetupViewControllerDataSource {
    
    var keyboardObserver: KeyboardObserver?
    let baseView: BaseView = BaseView()
    private var selfPeerView: RtkParticipantTileView!
    let borderRadius = DesignLibrary.shared.borderRadius
    public weak var delegate: SetupViewControllerDelegate?
    let btnsStackView: BaseStackView = {
        return RtkUIUtility.createStackView(axis: .horizontal, spacing: DesignLibrary.shared.space.space6)
    }()
    
   lazy var btnMic: MicToggleButton = {
       let button = MicToggleButton(meeting: self.rtkClient, alertController: self) { [weak self] button in
           guard let self = self else {return}
           self.selfPeerView.nameTag.refresh()
       }
        return button
    }()
    
   lazy var btnVideo: VideoToggleButton = {
       let button = VideoToggleButton(meeting: self.rtkClient, alertController: self) { [weak self] button in
           guard let self = self else {return}
           self.loadSelfVideoView()
       }
        return button
    }()
    
    let btnSetting: RtkButton = {
        let button = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_setting"))), rtkButtonState: .active)
        return button
    }()
    
    let lblJoinAs: RtkLabel = {return RtkUIUtility.createLabel(text: "Join in as")}()
    
    let textFieldBottom: RtkTextField = {
        let textField = RtkTextField()
        textField.setPlaceHolder(text: "Insert your name")
        return textField
    }()
    
    var btnBottom: RtkJoinButton!
    
    let lblBottom: RtkLabel = { return RtkUIUtility.createLabel(text: "24 people Present")}()
    
    let spaceToken = DesignLibrary.shared.space
    
    let backgroundColor = DesignLibrary.shared.color.background.shade1000
    
    private let completion: ()->Void
    
    private let meetinInfoV2: RtkMeetingInfo?
    private let rtkClient: RealtimeKitClient
    private var waitingRoomView: WaitingRoomView?
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let peerViewBaseView = UIView()

    public init(meetingInfo: RtkMeetingInfo, meeting: RealtimeKitClient, completion:@escaping()->Void) {
        self.rtkClient = meeting
        self.meetinInfoV2 = meetingInfo
        self.completion = completion
        super.init(meeting: meeting)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        self.view.backgroundColor = backgroundColor
    }

    private var viewModel: SetupViewModel!
    private var btnStackView: UIStackView!
    private var bottomStackView: UIStackView!
    
    private func rtkClientInit() {
        if let info = self.meetinInfoV2 {
            self.viewModel = SetupViewModel(rtkClient: self.rtkClient, delegate: self, meetingInfo: info)
        }
    }

   
    
    deinit {
        print("RtkUIKit | SetupViewController deinit is calling")
    }
    
}

//Mark: Public methods
extension RtkSetupViewController {
     func loadSelfVideoView() {
        selfPeerView.refreshVideo()
    }
    
     func setTag(name: String) {
        selfPeerView.viewModel.refreshNameTag()
        selfPeerView.viewModel.refreshInitialName()
    }
}

extension RtkSetupViewController: MeetingDelegate {

    internal func onMeetingInitCompleted() {
        self.setupUIAfterMeetingInit()
        let mediaPermission = self.rtkClient.localUser.permissions.media
        if mediaPermission.canPublishAudio == false {
            btnMic.isHidden = true
        }

        if mediaPermission.canPublishVideo == false {
            btnVideo.isHidden = true
        }

        loadSelfVideoView()
    }
    
    func onMeetingInitFailed(message: String?) {
        showInitFailedAlert(title: message ?? "", retry: { [weak self] in
            guard let self = self else {return}
            self.rtkClientInit()
        })
    }
    
    private func showInitFailedAlert(title: String, retry:@escaping()->Void) {
        let alert = UIAlertController(title: "Error", message: title, preferredStyle: .alert)
        // Add "OK" Button to alert, pressing it will bring you to the settings app
        alert.addAction(UIAlertAction(title: "retry", style: .default, handler: { action in
            retry()
        }))
        alert.addAction(UIAlertAction(title: "exit", style: .default, handler: { action in
            self.completion()
        }))
        // Show the alert with animation
        self.present(alert, animated: true)
    }
}

extension RtkSetupViewController {
    
    func setupView() {
        createSubviews()
        rtkClientInit()
    }
    
    private func setCallBacksForViewModel() {
        self.viewModel.rtkSelfListener.waitListStatusUpdate = { [weak self] status in
            guard let self = self else {return}
            self.showWaitingRoom(status: status)
        }
    }
    
    private func setupKeyboard() {
        self.startKeyboardObserving { [weak self] keyboardFrame in
            guard let self = self else {return}
            let frame = self.baseView.convert(self.bottomStackView.frame, to: self.view.coordinateSpace)
            self.view.frame.origin.y = keyboardFrame.origin.y - frame.maxY
        } onHide: { [weak self] in
            guard let self = self else {return}
            self.view.frame.origin.y = 0 // Move view to original position
        }
    }
    
    private func createSubviews() {
        self.view.addSubview(baseView)
        setUpActivityIndicator(baseView: baseView)
        addConstraintForBaseView()
        applyConstraintAsPerOrientation()
    }
    
    private func addConstraintForBaseView() {
        addPortaitConstraintsForBaseView()
        setPortraitContraintAsDeactive()
        addLandscapeConstraintForBaseView()
        setLandscapeContraintAsDeactive()
    }
    
    private func addPortaitConstraintsForBaseView() {
        baseView.set(.sameLeadingTrailing(self.view , spaceToken.space8),
                     .centerY(self.view),
                     .top(self.view, spaceToken.space8, .greaterThanOrEqual))
        portraitConstraints.append(contentsOf: [baseView.get(.leading)!,
                                                baseView.get(.trailing)!,
                                                baseView.get(.top)!,
                                                baseView.get(.centerY)!])
    }
    
    private func addLandscapeConstraintForBaseView() {
        baseView.set(.leading(self.view, spaceToken.space8, .greaterThanOrEqual),
                     .centerX(self.view),
                     .bottom(self.view, spaceToken.space8),
                     .top(self.view, spaceToken.space8))
        landscapeConstraints.append(contentsOf: [baseView.get(.top)!,
                                                 baseView.get(.bottom)!,
                                                 baseView.get(.leading)!,
                                                 baseView.get(.centerX)!])
    }
    
    private func setUpActivityIndicator(baseView: UIView) {
        baseView.addSubview(activityIndicator)
        activityIndicator.set(.centerView(baseView))
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
    }
    
    private func setupUIAfterMeetingInit() {
        createMeetingSetupUI()
        setupKeyboard()
        setupButtonActions()
        if self.viewModel.rtkClient.localUser.permissions.miscellaneous.canEditDisplayName {
            textFieldBottom.addTarget(self, action: #selector(textFieldEditingDidChange), for: .editingChanged)
            textFieldBottom.delegate = self
        }
        textFieldBottom.text = self.viewModel.rtkClient.localUser.name
        self.setTag(name: "")

        setCallBacksForViewModel()
    }
    
    private func createMeetingSetupUI() {
        activityIndicator.stopAnimating()
        baseView.addSubview(peerViewBaseView)

        selfPeerView = RtkParticipantTileView(viewModel: VideoPeerViewModel(meeting: rtkClient, participant: self.rtkClient.localUser, showSelfPreviewVideo: true))
        
        peerViewBaseView.addSubview(selfPeerView)

        selfPeerView.clipsToBounds = true
        
        let btnStackView = createBtnView()
        peerViewBaseView.addSubview(btnStackView)
        self.btnStackView = btnStackView
       
        let bottomStackView = createBottomButtonStackView()
        baseView.addSubview(bottomStackView)
        self.bottomStackView = bottomStackView

        lblBottom.isHidden = true
        addConstraintForCreatingMeetingSetUpUI()
        applyConstraintAsPerOrientation()
    }
    
    private func addConstraintForCreatingMeetingSetUpUI() {
        addPortraintConstraintForCreateMeetingSetupUI()
        setPortraitContraintAsDeactive()
        addLandscapeConstraintForCreateMeetingSetupUI()
        setLandscapeContraintAsDeactive()
    }
    
    private func addPortraintConstraintForCreateMeetingSetupUI() {
        peerViewBaseView.set(.top(baseView),
                         .sameLeadingTrailing(baseView))
        
        portraitConstraints.append(contentsOf: [peerViewBaseView.get(.top)!,
                                                peerViewBaseView.get(.leading)!,
                                                peerViewBaseView.get(.trailing)!])
        
        
        selfPeerView.set(.top(peerViewBaseView),
                         .leading(peerViewBaseView, spaceToken.space6, .greaterThanOrEqual),
                         .centerX(peerViewBaseView))
        
        portraitConstraints.append(contentsOf: [selfPeerView.get(.top)!,
                                                selfPeerView.get(.leading)!,
                                                selfPeerView.get(.centerX)!])
        
        let portraitPeerViewWidth =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: baseView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.70).getConstraint(for: selfPeerView)
        portraitConstraints.append(portraitPeerViewWidth)
        let portraitPeerViewHeight =  ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: baseView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.85).getConstraint(for: selfPeerView)
        portraitConstraints.append(portraitPeerViewHeight)

        

        btnStackView.set(.below(selfPeerView, spaceToken.space4),
                         .leading(peerViewBaseView, 0.0, .greaterThanOrEqual),
                         .centerX(peerViewBaseView),
                         .bottom(peerViewBaseView))
        portraitConstraints.append(contentsOf: [btnStackView.get(.top)!,
                                                btnStackView.get(.centerX)!,
                                                btnStackView.get(.leading)!,
                                                btnStackView.get(.bottom)!])

        bottomStackView.set(.below(peerViewBaseView, spaceToken.space6),
                            .sameLeadingTrailing(baseView),
                            .bottom(baseView))
        portraitConstraints.append(contentsOf: [bottomStackView.get(.top)!,
                                                bottomStackView.get(.bottom)!,
                                                bottomStackView.get(.leading)!,
                                                bottomStackView.get(.trailing)!])

    }
    
    private func addLandscapeConstraintForCreateMeetingSetupUI() {

        let equalWidthConstraintPeerView =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: baseView, toViewAttribute: .height, relation: .equal, constant: 0, multiplier: 0.8).getConstraint(for: selfPeerView)
        landscapeConstraints.append(equalWidthConstraintPeerView)
        
        let equalHeightConstraintPeerView =  ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: baseView, toViewAttribute: .height, relation: .equal, constant: 0, multiplier: 0.6).getConstraint(for: selfPeerView)
        landscapeConstraints.append(equalHeightConstraintPeerView)
       
        peerViewBaseView.set(.top(baseView, 0, .greaterThanOrEqual),
                         .leading(baseView),
                         .centerY(baseView))
                
        landscapeConstraints.append(contentsOf: [peerViewBaseView.get(.top)!,
                                                 peerViewBaseView.get(.leading)!,
                                                 peerViewBaseView.get(.centerY)!])
       
        selfPeerView.set(.top(peerViewBaseView),
                         .sameLeadingTrailing(peerViewBaseView))
                
        landscapeConstraints.append(contentsOf: [selfPeerView.get(.top)!,
                                                 selfPeerView.get(.leading)!,
                                                 selfPeerView.get(.trailing)!])

        btnStackView.set(.below(selfPeerView, spaceToken.space4),
                         .centerX(selfPeerView),
                         .bottom(peerViewBaseView, spaceToken.space8))
       
        landscapeConstraints.append(contentsOf: [btnStackView.get(.top)!,
                                                 btnStackView.get(.centerX)!,
                                                 btnStackView.get(.bottom)!])
        
        // Right part
        bottomStackView.set(.after(peerViewBaseView, spaceToken.space6),
                            .centerY(baseView),
                            .trailing(baseView, spaceToken.space6))
        let equalWidthBottomStackView =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: selfPeerView, toViewAttribute: .height, relation: .equal, constant: 0, multiplier: 1.0).getConstraint(for: bottomStackView)
        equalWidthBottomStackView.priority = .defaultHigh
        landscapeConstraints.append(equalWidthBottomStackView)
        landscapeConstraints.append(contentsOf: [bottomStackView.get(.leading)!,
                                                 bottomStackView.get(.centerY)!,
                                                 bottomStackView.get(.trailing)!])
    }
    
    private func setupButtonActions() {
        btnSetting.addTarget(self, action: #selector(clickSetting(button:)), for: .touchUpInside)
    }
    
    @objc func textFieldEditingDidChange(_ sender: Any) {
        if !((textFieldBottom.text?.trimmingCharacters(in: .whitespaces).isEmpty) ?? false) {
            if let text = textFieldBottom.text {
                self.viewModel?.rtkClient.localUser.name = text
                self.setTag(name: text)
            }
        }
    }
    
    private  func createBtnView() -> BaseStackView {
        let stackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: DesignLibrary.shared.space.space6)
        
        if let info = self.meetinInfoV2 {
            btnMic.isSelected = !info.enableAudio
            btnVideo.isSelected = !info.enableVideo
        }
        stackView.addArrangedSubviews(btnMic,btnVideo,btnSetting)
        return stackView
    }
    
    private func createBottomButtonStackView() -> BaseStackView {
        let stackView = RtkUIUtility.createStackView(axis: .vertical, spacing: spaceToken.space2)
        stackView.addArrangedSubviews(lblJoinAs, createBottomJoinButton(), lblBottom)
        return stackView
    }
    
    private func createBottomJoinButton() -> BaseView {
        let view = BaseView()
        view.addSubview(textFieldBottom)
        textFieldBottom.set(.sameLeadingTrailing(view), .top(view))
        btnBottom = addJoinButton(on: view)
        btnBottom.accessibilityIdentifier = "Join Button"
        return view
    }
    
    private func addJoinButton(on view: UIView) -> RtkJoinButton {
        let joinButton = RtkJoinButton(meeting: self.rtkClient) { [weak self] button, success in
            guard let self = self else {return}
            if success {
                self.delegate?.userJoinedMeetingSuccessfully(sender: self)
            }
        }
        
        view.addSubview(joinButton)
        joinButton.set(.sameLeadingTrailing(view), .bottom(view), .below(textFieldBottom, spaceToken.space6))
        return joinButton
    }
    
    private func showWaitingRoom(status: WaitListStatus) {
        waitingRoomView?.removeFromSuperview()
        if status != .none {
            let waitingView = WaitingRoomView(automaticClose: false, onCompletion: { [weak self] in
                guard let self = self else {return}
                self.completion()
                self.meeting.leaveRoom(onSuccess: {}, onFailure: {_ in})
            })
            waitingView.accessibilityIdentifier = "WaitingRoom_View"
            waitingView.backgroundColor = self.view.backgroundColor
            self.view.addSubview(waitingView)
            waitingView.set(.fillSuperView(self.view))
            self.view.endEditing(true)
            waitingRoomView = waitingView
            waitingView.show(status: ParticipantMeetingStatus.getStatus(status: status))
        }
    }
}

extension RtkSetupViewController : UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}


extension RtkSetupViewController {
    
    @objc func clickSetting(button: RtkButton) {
        if !rtkClient.localUser.videoEnabled && !rtkClient.localUser.audioEnabled {
            self.view.showToast(toastMessage: "Microphone/Camera needs to be enabled to access settings", duration: 1)
            return
        }
        
        if let rtkClient = self.viewModel?.rtkClient {
            rtkClient.localUser.setDisplayName(name: textFieldBottom.text ?? "")
            let controller = RtkSettingViewController(nameTag: textFieldBottom.text ?? "", meeting: rtkClient)
            controller.view.backgroundColor = self.view.backgroundColor
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true)
        }
    }
}
