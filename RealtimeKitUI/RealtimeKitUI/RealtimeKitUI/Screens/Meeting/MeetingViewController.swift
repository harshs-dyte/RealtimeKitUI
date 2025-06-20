//
//  MeetingViewController.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 21/12/22.
//

import RealtimeKit
import UIKit
import AVFAudio
import AVKit

public struct Animations {
    public static let gridViewAnimationDuration = 0.3
}

public protocol MeetingViewControllerDataSource {
    func getTopbar(viewController: MeetingViewController) -> RtkMeetingHeaderView?
    func getMiddleView(viewController: MeetingViewController) -> UIView?
    func getBottomTabbar(viewController: MeetingViewController) -> RtkMeetingControlBar?
}

open class RtkBaseMeetingViewController: RtkBaseViewController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        initialisePrivateChatNotificationLookup()
    }
    private func initialisePrivateChatNotificationLookup() {
        Shared.data.privateChatReadLookup[RtkChatViewController.keyEveryOne] = false
        for participant in self.meeting.participants.joined {
            if participant.userId != self.meeting.localUser.userId {
                if self.meeting.chat.getPrivateChatMessages(participant: participant).count > 0 {
                    Shared.data.privateChatReadLookup[participant.userId] = true
                }else {
                    Shared.data.privateChatReadLookup[participant.userId] = false
                    
                }
            }
        }
    }
}

public class MeetingViewController: RtkBaseMeetingViewController {
    
    private var gridView: GridView<RtkParticipantTileContainerView>!
    let pluginScreenShareView: RtkPluginsView
    let pinnedView = RtkParticipantTileContainerView()
    var pipController: RtkPipController?
    let gridBaseView = UIView()
    private let pluginPinnedScreenShareBaseView = UIView()
    private var fullScreenView: FullScreenView!
    
    let baseContentView = UIView()
    
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    public var dataSource: MeetingViewControllerDataSource?
    
    let fullScreenButton: RtkControlBarButton = {
        let button = RtkControlBarButton(image: RtkImage(image: ImageProvider.image(named: "icon_show_fullscreen")))
        button.setSelected(image:  RtkImage(image: ImageProvider.image(named: "icon_hide_fullscreen")))
        button.backgroundColor = rtkSharedTokenColor.background.shade800
        return button
    }()
    let viewModel: MeetingViewModel
    
    private var topBar: RtkMeetingHeaderView!
    private var bottomBar: RtkControlBar!
    
    internal let onFinishedMeeting: ()->Void
    private var viewWillAppear = false
    
    internal var moreButtonBottomBar: RtkControlBarButton?
    private var layoutContraintPluginBaseZeroHeight: NSLayoutConstraint!
    private var layoutPortraitContraintPluginBaseVariableHeight: NSLayoutConstraint!
    private var layoutLandscapeContraintPluginBaseVariableWidth: NSLayoutConstraint!
    private var layoutContraintPluginBaseZeroWidth: NSLayoutConstraint!
    
    private var waitingRoomView: WaitingRoomView?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    
    public init(meeting: RealtimeKitClient, completion:@escaping()->Void) {
        //TODO: Check the local user passed now
        self.pluginScreenShareView = RtkPluginsView(videoPeerViewModel:VideoPeerViewModel(meeting: meeting, participant: meeting.localUser, showSelfPreviewVideo: false, showScreenShareVideoView: true))
        self.onFinishedMeeting = completion
        self.viewModel = MeetingViewModel(rtkClient: meeting)
        super.init(meeting: meeting)
        notificationDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        self.topBar.containerView.get(.top)?.constant = self.view.safeAreaInsets.top
        if UIScreen.isLandscape() {
            self.bottomBar.setWidth()
        }else {
            self.bottomBar.setHeight()
        }
        setLeftPaddingContraintForBaseContentView()
    }
    
    private func setLeftPaddingContraintForBaseContentView() {
        if UIScreen.deviceOrientation == .landscapeLeft {
            self.baseContentView.get(.bottom)?.constant = -self.view.safeAreaInsets.bottom
            self.baseContentView.get(.leading)?.constant = self.view.safeAreaInsets.bottom
        }else if UIScreen.deviceOrientation == .landscapeRight {
            self.baseContentView.get(.bottom)?.constant = -self.view.safeAreaInsets.bottom
            self.baseContentView.get(.leading)?.constant = self.view.safeAreaInsets.right
        }
    }
    
    private func shouldShowNotificationBubble() -> Bool {
        let totalPollsAndChatCount = Shared.data.getTotalUnreadCountPollsAndChat(totalMessage: self.meeting.chat.messages.count, totalsPolls: self.meeting.polls.items.count)
        return (self.meeting.getPendingParticipantCount() > 0 || totalPollsAndChatCount > 0)
    }
    
    public func updateMoreButtonNotificationBubble() {
        if shouldShowNotificationBubble() {
            self.moreButtonBottomBar?.notificationBadge.isHidden = false
        }else {
            self.moreButtonBottomBar?.notificationBadge.isHidden = true
        }
    }
    
    private func setUpBackgroundNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(appdidMoveTobackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc
    func appdidMoveTobackground() {
        requestBackgroundTime()
    }
    
    @objc
    func appWillMoveToForeground() {
        endBackgroundTask()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        self.view.accessibilityIdentifier = "Meeting_Base_View"
        self.view.backgroundColor = DesignLibrary.shared.color.background.shade1000
        createTopbar()
        createBottomBar()
        createSubView()
        applyConstraintAsPerOrientation()
        setInitialsConfiguration()
        setupNotifications()
        self.viewModel.delegate = self
        
        self.viewModel.selfEventListener.observeSelfMeetingEndForAll { [weak self]  success in
            guard let self = self else {return}
            
            func showWaitingRoom(status: ParticipantMeetingStatus, time:TimeInterval, onComplete:@escaping()->Void) {
                if status != .none {
                    let waitingView = WaitingRoomView(automaticClose: true, onCompletion: onComplete)
                    waitingView.backgroundColor = self.view.backgroundColor
                    self.view.addSubview(waitingView)
                    waitingView.set(.fillSuperView(self.view))
                    self.view.endEditing(true)
                    waitingView.show(status: status)
                }
            }
            //self.dismiss(animated: true)
            showWaitingRoom(status: .meetingEnded, time: 2) { [weak self] in
                guard let self = self else {return}
                self.viewModel.clean()
                self.onFinishedMeeting()
            }
        }
        
        self.viewModel.selfEventListener.observeSelfRemoved { [weak self] success in
            guard let self = self else {return}
            
            func showWaitingRoom(status: ParticipantMeetingStatus, time:TimeInterval, onComplete:@escaping()->Void) {
                if status != .none {
                    let waitingView = WaitingRoomView(automaticClose: true, onCompletion: onComplete)
                    waitingView.backgroundColor = self.view.backgroundColor
                    self.view.addSubview(waitingView)
                    waitingView.set(.fillSuperView(self.view))
                    self.view.endEditing(true)
                    waitingView.show(status: status)
                }
            }
            //self.dismiss(animated: true)
            showWaitingRoom(status: .kicked, time: 2) { [weak self] in
                guard let self = self else {return}
                self.viewModel.clean()
                self.onFinishedMeeting()
            }
        }
        self.viewModel.selfEventListener.observePluginScreenShareTabSync(update: { id in
            self.selectPluginOrScreenShare(id: id)
        })
        
        if self.meeting.localUser.permissions.waitingRoom.canAcceptRequests {
            self.viewModel.waitlistEventListener.participantJoinedCompletion = {[weak self] participant in
                guard let self = self else {return}
                self.view.showToast(toastMessage: "\(participant.name) has requested to join the call ", duration: 2.0, uiBlocker: false)
                updateMoreButtonNotificationBubble()
                NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
            }
            
            self.viewModel.waitlistEventListener.participantRequestRejectCompletion = {[weak self] participant in
                guard let self = self else {return}
                updateMoreButtonNotificationBubble()
                NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
            }
            self.viewModel.waitlistEventListener.participantRequestAcceptedCompletion = {[weak self] participant in
                guard let self = self else {return}
                updateMoreButtonNotificationBubble()
                NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
            }
            self.viewModel.waitlistEventListener.participantRemovedCompletion = {[weak self] participant in
                guard let self = self else {return}
                self.updateMoreButtonNotificationBubble()
                NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
            }
        }
        addWaitingRoom { [weak self] in
            guard let self = self else {return}
            self.viewModel.clean()
            self.onFinishedMeeting()
        }
        setUpReconnection { [weak self] in
            guard let self = self else {return}
            self.viewModel.clean()
            self.onFinishedMeeting()
        } success: {  [weak self] in
            guard let self = self else {return}
            self.refreshMeetingGrid()
            self.refreshPluginsScreenShareView()
        }
        // pipController = RtkPipController(renderingView: self.gridBaseView, localUser: meeting.localUser)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewWillAppear == false {
            viewWillAppear = true
            self.viewModel.refreshActiveParticipants()
            self.viewModel.trackOnGoingState()
            
            if shouldShowNotificationBubble() {
                self.moreButtonBottomBar?.notificationBadge.isHidden = false
            } else {
                self.moreButtonBottomBar?.notificationBadge.isHidden = true
            }
        }
    }
    
    private func refreshPipViewWhenChangedInActiveParticipant() {
        if self.meeting.participants.active.count <= 1 {
            self.pipController?.setSecondaryUser(otherParticipant: nil)
        } else {
            if self.pipController?.otherUser != nil {
                // It must be part of activeParticipant, Participant shouldn't leave the meeting
                if self.meeting.participants.active.contains(self.pipController!.otherUser!) == false {
                    if  self.meeting.participants.active.count > 1 {
                        for participant in self.meeting.participants.active {
                            if participant.userId != self.meeting.localUser.userId {
                                self.pipController?.setSecondaryUser(otherParticipant: participant)
                                break;
                            }
                        }
                    }
                }
            }else {
                if  self.meeting.participants.active.count > 1 {
                    for participant in self.meeting.participants.active {
                        if participant.userId != self.meeting.localUser.userId {
                            self.pipController?.setSecondaryUser(otherParticipant: participant)
                            break;
                        }
                    }
                }
            }
        }
    }
    public func refreshMeetingGrid(forRotation: Bool = false) {
        self.refreshPipViewWhenChangedInActiveParticipant()
        if isDebugModeOn {
            print("Debug RtkUIKit | refreshMeetingGrid")
        }
        
        self.meetingGridPageBecomeVisible()
        
        let arrModels = self.viewModel.arrGridParticipants
        
        if isDebugModeOn {
            print("Debug RtkUIKIt | refreshing Finished")
        }
        
        func prepareGridViewsForReuse() {
            self.gridView.prepareForReuse { peerView in
                peerView.prepareForReuse()
            }
        }
        
        
        func loadGridAndPluginView(showPluginPinnedView: Bool, animation: Bool) {
            self.showHidePluginPinnedAndScreenShareView()
            self.loadGrid(fullScreen: !showPluginPinnedView, animation: !animation, completion: {
                if forRotation == false {
                    prepareGridViewsForReuse()
                    populateGridChildViews(models: arrModels)
                }
            })
        }
        
        if self.viewModel.pinOrPluginScreenShareModeIsActive() {
            loadGridAndPluginView(showPluginPinnedView: true, animation: false)
        } else {
            loadGridAndPluginView(showPluginPinnedView: false, animation: false)
        }
        
        if self.viewModel.pinOrPluginScreenShareModeIsActive() {
            self.refreshPluginsScreenShareView()
        }
        
        func populateGridChildViews(models: [GridCellViewModel]) {
            for i in 0..<models.count {
                if let peerContainerView = self.gridView.childView(index: i) {
                    let isSelf = models[i].participant.id == self.meeting.localUser.id
                    if(isSelf){
                        if let selfParticipant = models[i].participant as? RtkSelfParticipant {
                            peerContainerView.setParticipant(meeting: self.meeting, participant: selfParticipant)
                        }
                    }
                    else if let participant = models[i].participant as? RtkRemoteParticipant{
                        peerContainerView.setParticipant(meeting: self.meeting, participant: participant)
                    }
                }
            }
            if isDebugModeOn {
                print("Debug RtkUIKit | Iterating for Items \(arrModels.count)")
                for i in 0..<models.count {
                    if let peerContainerView = self.gridView.childView(index: i), let tileView = peerContainerView.tileView {
                        print("Debug RtkUIKit | Tile View Exists \(tileView) \nSuperView \(String(describing: tileView.superview))")
                    }
                }
            }
        }
    }
    
    internal func getBottomBar() -> RtkControlBar {
        let controlBar =  RtkMeetingControlBar(meeting: self.meeting, delegate: nil, presentingViewController: self) {
            [weak self] in
            guard let self = self else {return}
            self.refreshMeetingGridTile(participant: self.meeting.localUser)
        } onLeaveMeetingCompletion: {
            [weak self] in
            guard let self = self else {return}
            self.viewModel.clean()
            self.onFinishedMeeting()
        }
        controlBar.accessibilityIdentifier = "Meeting_ControlBottomBar"
        return controlBar
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("NotificationAllChatsRead"), object: nil)
        if isDebugModeOn {
            print("RtkUIKit | MeetingViewController Deinit is calling ")
        }
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.presentedViewController?.dismiss(animated: false)
        bottomBar.moreButton.hideBottomSheet()
        if UIScreen.isLandscape() {
            bottomBar.moreButton.superview?.isHidden = true
        }else {
            bottomBar.moreButton.superview?.isHidden = false
        }
        
        self.applyConstraintAsPerOrientation { [weak self] in
            guard let self = self else {return}
            self.fullScreenButton.isHidden = true
            self.closefullscreen()
        } onLandscape: { [weak self] in
            guard let self = self else {return}
            self.fullScreenButton.isSelected = false
            self.fullScreenButton.isHidden = false
        }
        
        self.showPinnedPluginViewAsPerOrientation(show: false)
        self.setLeftPaddingContraintForBaseContentView()
        DispatchQueue.main.async {
            self.refreshMeetingGrid(forRotation: true)
        }
    }
    
}

//Mark: Background extended time
extension MeetingViewController {
    private func requestBackgroundTime() {
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "WebRTCBackgroundTask") { [weak self] in
            print("*****Background task Tring for Finish \(UIApplication.shared.backgroundTimeRemaining)")
            
            self?.requestBackgroundTime()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
}
extension MeetingViewController: AVPictureInPictureControllerDelegate {
    
}
// Bottom bar related Methods
extension MeetingViewController {
    private func createBottomBar() {
        self.bottomBar = self.dataSource?.getBottomTabbar(viewController: self) ?? getBottomBar()
        self.moreButtonBottomBar = self.bottomBar.moreButton
        self.view.addSubview(self.bottomBar)
        addBottomBarConstraint()
    }
    
    
    private  func addBottomBarConstraint() {
        addPortraitContraintBottombar()
        addLandscapeContraintBottombar()
        if UIScreen.isLandscape() {
            self.moreButtonBottomBar?.superview?.isHidden = true
        }
    }
    
    private func addPortraitContraintBottombar() {
        self.bottomBar.set(.sameLeadingTrailing(self.view),
                           .bottom(self.view))
        portraitConstraints.append(contentsOf: [self.bottomBar.get(.leading)!,
                                                self.bottomBar.get(.trailing)!,
                                                self.bottomBar.get(.bottom)!])
        setPortraitContraintAsDeactive()
    }
    
    private func addLandscapeContraintBottombar() {
        self.bottomBar.set(.trailing(self.view),
                           .sameTopBottom(self.view))
        landscapeConstraints.append(contentsOf: [self.bottomBar.get(.trailing)!,
                                                 self.bottomBar.get(.top)!,
                                                 self.bottomBar.get(.bottom)!])
        setLandscapeContraintAsDeactive()
    }
    
    
}

private extension MeetingViewController {
    
    private func setInitialsConfiguration() {
        // self.topBar.setInitialConfiguration()
    }
    
    private func createSubView() {
        self.view.addSubview(baseContentView)
        baseContentView.addSubview(pluginPinnedScreenShareBaseView)
        baseContentView.addSubview(gridBaseView)
        pluginPinnedScreenShareBaseView.accessibilityIdentifier = "Grid_Plugin_View"
        
        gridView = GridView(showingCurrently: 9, getChildView: {
            return RtkParticipantTileContainerView()
        })
        
        gridBaseView.addSubview(gridView)
        pluginPinnedScreenShareBaseView.addSubview(pluginScreenShareView)
        pluginPinnedScreenShareBaseView.addSubview(pinnedView)
        
        pluginScreenShareView.addSubview(fullScreenButton)
        
        fullScreenButton.set(.trailing(pluginScreenShareView, rtkSharedTokenSpace.space1),
                             .bottom(pluginScreenShareView,rtkSharedTokenSpace.space1))
        
        fullScreenButton.addTarget(self, action: #selector(buttonClick(button:)), for: .touchUpInside)
        self.fullScreenButton.isHidden = !UIScreen.isLandscape()
        fullScreenButton.isSelected = false
        addPortraitConstraintForSubviews()
        addLandscapeConstraintForSubviews()
        showPinnedPluginViewAsPerOrientation(show: false)
    }
    
    @objc func buttonClick(button: RtkButton) {
        if UIScreen.isLandscape() {
            if button.isSelected == false {
                pluginScreenShareView.removeFromSuperview()
                self.addFullScreenView(contentView: pluginScreenShareView)
            }else {
                closefullscreen()
            }
            button.isSelected = !button.isSelected
        }
    }
    
    private func closefullscreen() {
        if fullScreenView?.isVisible == true {
            self.pluginPinnedScreenShareBaseView.addSubview(self.pluginScreenShareView)
            self.pluginScreenShareView.set(.fillSuperView(self.pluginPinnedScreenShareBaseView))
            self.removeFullScreenView()
        }
    }
    
    private func showPinnedPluginViewAsPerOrientation(show: Bool) {
        layoutPortraitContraintPluginBaseVariableHeight.isActive = false
        layoutContraintPluginBaseZeroHeight.isActive = false
        layoutLandscapeContraintPluginBaseVariableWidth.isActive = false
        layoutContraintPluginBaseZeroWidth.isActive = false
        
        if UIScreen.isLandscape() {
            layoutLandscapeContraintPluginBaseVariableWidth.isActive = show
            layoutContraintPluginBaseZeroWidth.isActive = !show
        }else {
            layoutPortraitContraintPluginBaseVariableHeight.isActive = show
            layoutContraintPluginBaseZeroHeight.isActive = !show
        }
    }
    
    private func addPortraitConstraintForSubviews() {
        
        baseContentView.set(.sameLeadingTrailing(self.view),
                            .below(topBar),
                            .above(bottomBar))
        portraitConstraints.append(contentsOf: [baseContentView.get(.leading)!,
                                                baseContentView.get(.trailing)!,
                                                baseContentView.get(.top)!,
                                                baseContentView.get(.bottom)!])
        
        pluginPinnedScreenShareBaseView.set(.sameLeadingTrailing(baseContentView),
                                            .top(baseContentView))
        portraitConstraints.append(contentsOf: [pluginPinnedScreenShareBaseView.get(.leading)!,
                                                pluginPinnedScreenShareBaseView.get(.trailing)!,
                                                pluginPinnedScreenShareBaseView.get(.top)!])
        
        layoutPortraitContraintPluginBaseVariableHeight = NSLayoutConstraint(item: pluginPinnedScreenShareBaseView, attribute: .height, relatedBy: .equal, toItem: baseContentView, attribute: .height, multiplier: 0.7, constant: 0)
        layoutPortraitContraintPluginBaseVariableHeight.isActive = false
        
        layoutContraintPluginBaseZeroHeight = NSLayoutConstraint(item: pluginPinnedScreenShareBaseView, attribute: .height, relatedBy: .equal, toItem: baseContentView, attribute: .height, multiplier: 0.0, constant: 0)
        
        layoutContraintPluginBaseZeroHeight.isActive = false
        
        
        gridBaseView.set(.sameLeadingTrailing(baseContentView),
                         .below(pluginPinnedScreenShareBaseView),
                         .bottom(baseContentView))
        
        portraitConstraints.append(contentsOf: [gridBaseView.get(.leading)!,
                                                gridBaseView.get(.trailing)!,
                                                gridBaseView.get(.top)!,
                                                gridBaseView.get(.bottom)!])
        
        gridView.set(.fillSuperView(gridBaseView))
        portraitConstraints.append(contentsOf: [gridView.get(.leading)!,
                                                gridView.get(.trailing)!,
                                                gridView.get(.top)!,
                                                gridView.get(.bottom)!])
        pluginScreenShareView.set(.fillSuperView(pluginPinnedScreenShareBaseView))
        portraitConstraints.append(contentsOf: [pluginScreenShareView.get(.leading)!,
                                                pluginScreenShareView.get(.trailing)!,
                                                pluginScreenShareView.get(.top)!,
                                                pluginScreenShareView.get(.bottom)!])
        
        pinnedView.set(.fillSuperView(pluginPinnedScreenShareBaseView))
        portraitConstraints.append(contentsOf: [pinnedView.get(.leading)!,
                                                pinnedView.get(.trailing)!,
                                                pinnedView.get(.top)!,
                                                pinnedView.get(.bottom)!])
        setPortraitContraintAsDeactive()
    }
    
    private func addLandscapeConstraintForSubviews() {
        
        baseContentView.set(.leading(self.view),
                            .below(self.topBar),
                            .bottom(self.view),
                            .before(bottomBar))
        
        landscapeConstraints.append(contentsOf: [baseContentView.get(.leading)!,
                                                 baseContentView.get(.trailing)!,
                                                 baseContentView.get(.top)!,
                                                 baseContentView.get(.bottom)!])
        
        
        pluginPinnedScreenShareBaseView.set(.leading(baseContentView),
                                            .sameTopBottom(baseContentView))
        landscapeConstraints.append(contentsOf: [pluginPinnedScreenShareBaseView.get(.leading)!,
                                                 pluginPinnedScreenShareBaseView.get(.bottom)!,
                                                 pluginPinnedScreenShareBaseView.get(.top)!])
        
        layoutLandscapeContraintPluginBaseVariableWidth = NSLayoutConstraint(item: pluginPinnedScreenShareBaseView, attribute: .width, relatedBy: .equal, toItem: baseContentView, attribute: .width, multiplier: 0.75, constant: 0)
        layoutLandscapeContraintPluginBaseVariableWidth.isActive = false
        
        layoutContraintPluginBaseZeroWidth = NSLayoutConstraint(item: pluginPinnedScreenShareBaseView, attribute: .width, relatedBy: .equal, toItem: baseContentView, attribute: .width, multiplier: 0.0, constant: 0)
        
        layoutContraintPluginBaseZeroWidth.isActive = false
        
        
        gridBaseView.set(.sameTopBottom(baseContentView),
                         .after(pluginPinnedScreenShareBaseView),
                         .trailing(baseContentView))
        
        landscapeConstraints.append(contentsOf: [gridBaseView.get(.leading)!,
                                                 gridBaseView.get(.trailing)!,
                                                 gridBaseView.get(.top)!,
                                                 gridBaseView.get(.bottom)!])
        
        gridView.set(.fillSuperView(gridBaseView))
        landscapeConstraints.append(contentsOf: [gridView.get(.leading)!,
                                                 gridView.get(.trailing)!,
                                                 gridView.get(.top)!,
                                                 gridView.get(.bottom)!])
        pluginScreenShareView.set(.fillSuperView(pluginPinnedScreenShareBaseView))
        landscapeConstraints.append(contentsOf: [pluginScreenShareView.get(.leading)!,
                                                 pluginScreenShareView.get(.trailing)!,
                                                 pluginScreenShareView.get(.top)!,
                                                 pluginScreenShareView.get(.bottom)!])
        
        pinnedView.set(.fillSuperView(pluginPinnedScreenShareBaseView))
        landscapeConstraints.append(contentsOf: [pinnedView.get(.leading)!,
                                                 pinnedView.get(.trailing)!,
                                                 pinnedView.get(.top)!,
                                                 pinnedView.get(.bottom)!])
        
        setLandscapeContraintAsDeactive()
    }
    
}

// TopBar related Methods
extension MeetingViewController {
    private func createTopbar() {
        let topbar = RtkMeetingHeaderView(meeting: self.meeting)
        self.view.addSubview(topbar)
        topbar.accessibilityIdentifier = "Meeting_ControlTopBar"
        self.topBar = topbar
        addPotraitContraintTopbar()
        addLandscapeContraintTopbar()
    }
    
    private func addPotraitContraintTopbar() {
        self.topBar.set(.sameLeadingTrailing(self.view), .top(self.view))
        portraitConstraints.append(contentsOf: [self.topBar.get(.leading)!,
                                                self.topBar.get(.trailing)!,
                                                self.topBar.get(.top)!])
        setPortraitContraintAsDeactive()
    }
    
    private func addLandscapeContraintTopbar() {
        self.topBar.set(.sameLeadingTrailing(self.view) , .top(self.view))
        
        self.topBar.set(.height(0))
        landscapeConstraints.append(contentsOf: [self.topBar.get(.leading)!,
                                                 self.topBar.get(.trailing)!,
                                                 self.topBar.get(.top)!,
                                                 self.topBar.get(.height)!])
        setLandscapeContraintAsDeactive()
    }
    
}



extension MeetingViewController : MeetingViewModelDelegate {
    
    func newPollAdded(createdBy: String) {
        if Shared.data.notification.newPollArrived.showToast {
            self.view.showToast(toastMessage: "New poll created by \(createdBy)", duration: 2.0, uiBlocker: false)
        }
    }
    
    func participantJoined(participant: RtkMeetingParticipant) {
        self.topBar.refreshNextPreviouButtonState()
        if Shared.data.notification.participantJoined.showToast {
            self.view.showToast(toastMessage: "\(participant.name) just joined", duration: 2.0, uiBlocker: false)
        }
    }
    
    func participantLeft(participant: RtkMeetingParticipant) {
        self.topBar.refreshNextPreviouButtonState()
        if Shared.data.notification.participantLeft.showToast {
            self.view.showToast(toastMessage: "\(participant.name) left", duration: 2.0, uiBlocker: false)
        }
    }
    
    
    func activeSpeakerChanged(participant: RtkMeetingParticipant) {
        //For now commenting out the functionality of Active Speaker, It's Not working as per our expectation
        // showAndHideActiveSpeaker()
        if let participant = participant as? RtkRemoteParticipant {
            if participant.userId != self.meeting.localUser.userId {
                self.pipController?.setSecondaryUser(otherParticipant: participant)
            }
        }
    }
    
    func pinnedChanged(participant: RtkMeetingParticipant) {
        if !self.viewModel.pinOrPluginScreenShareModeIsActive() {
            //move to page 0 forcefully as we need to show pin view
            //large pin view functionality only exists on page 0
            self.meeting.participants.setPage(pageNumber: 0)
        } else {
            if self.viewModel.pluginScreenShareModeIsActive() == false {
                self.pinnedView.setParticipant(meeting: self.meeting, participant: participant)
            }
        }
    }
    
    func activeSpeakerRemoved() {
        //For now commenting out the functionality of Active Speaker, It's Not working as per our expectation
        //showAndHideActiveSpeaker()
    }
    
    private func showAndHideActiveSpeaker() {
        if let pinned = self.meeting.participants.pinned {
            self.pluginScreenShareView.showPinnedView(participant: pinned)
        }else {
            self.pluginScreenShareView.hideActiveSpeaker()
        }
    }
    
    private func getScreenShareTabButton(participants: [ParticipantsShareControl]) -> [RtkPluginScreenShareTabButton] {
        var arrButtons = [RtkPluginScreenShareTabButton]()
        for participant in participants {
            var image: RtkImage?
            if let _ = participant as? ScreenShareModel {
                //For
                image = RtkImage(image: ImageProvider.image(named: "icon_screen_share"))
            }else {
                if let strUrl = participant.image , let imageUrl = URL(string: strUrl) {
                    image = RtkImage(url: imageUrl)
                }
            }
            
            let button = RtkPluginScreenShareTabButton(image: image, title: participant.name, id: participant.id)
            // TODO:Below hardcoding is not needed, We also need to scale down the image as well.
            button.btnImageView?.set(.height(20),
                                     .width(20))
            arrButtons.append(button)
        }
        return arrButtons
    }
    
    private func handleClicksOnPluginsTab(model: PluginButtonModel, at index: Int) {
        if let pluginView = model.plugin.getPluginView() {
            self.pluginScreenShareView.show(pluginView: pluginView)
        }
        self.viewModel.screenShareViewModel.selectedIndex = (UInt(index), model.id)
    }
    
    private func handleClicksOnScreenShareTab(model: ScreenShareModel, index: Int) {
        self.pluginScreenShareView.showVideoView(participant: model.participant)
        self.pluginScreenShareView.pluginVideoView.viewModel.refreshNameTag()
        self.viewModel.screenShareViewModel.selectedIndex = (UInt(index), model.id)
    }
    
    public func selectPluginOrScreenShare(id: String) {
        var index: Int = -1
        for button in self.pluginScreenShareView.activeListView.buttons {
            index = index + 1
            if button.id == id {
                self.pluginScreenShareView.selectForAutoSync(button: button)
                break
            }
        }
    }
    
    func refreshPluginsButtonTab(pluginsButtonsModels: [ParticipantsShareControl], arrButtons: [RtkPluginScreenShareTabButton])  {
        if arrButtons.count >= 1 {
            var selectedIndex: Int?
            if let index = self.viewModel.screenShareViewModel.selectedIndex?.0 {
                selectedIndex = Int(index)
            }
            self.pluginScreenShareView.setButtons(buttons: arrButtons, selectedIndex: selectedIndex) { [weak self] button, isUserClick in
                guard let self = self else {return}
                if let plugin = pluginsButtonsModels[button.index] as? PluginButtonModel {
                    if self.pluginScreenShareView.syncButton?.isSelected == false && isUserClick {
                        //This is send only when Syncbutton is on and Visible
                        self.meeting.meta.syncTab(id: plugin.id, tabType: .plugin)
                    }
                    self.handleClicksOnPluginsTab(model: plugin, at: button.index)
                    
                }else if let screenShare = pluginsButtonsModels[button.index] as? ScreenShareModel {
                    if self.pluginScreenShareView.syncButton?.isSelected == false && isUserClick {
                        //This is send only when Syncbutton is on and Visible
                        self.meeting.meta.syncTab(id: screenShare.id, tabType: .screenshare)
                    }
                    self.handleClicksOnScreenShareTab(model: screenShare, index: button.index)
                }
                for (index, element) in arrButtons.enumerated() {
                    element.isSelected = index == button.index ? true : false
                }
            }
            
            self.pluginScreenShareView.observeSyncButtonClick { syncButton in
                if syncButton.isSelected == false {
                    if let selectedIndex = self.viewModel.screenShareViewModel.selectedIndex {
                        let model = self.viewModel.screenShareViewModel.arrScreenShareParticipants[Int(selectedIndex.0)]
                        if let model = model as? ScreenSharePluginsProtocol {
                            self.meeting.meta.syncTab(id: model.id, tabType: .screenshare)
                        }else if let model = model as? PluginsButtonModelProtocol {
                            self.meeting.meta.syncTab(id: model.id, tabType: .plugin)
                        }
                    }
                }
            }
        }
    }
    
    private func showHidePluginPinnedAndScreenShareView() {
        if self.viewModel.pinOrPluginScreenShareModeIsActive() {
            self.showPinnedPluginView(show: true, animation: true)
            if self.viewModel.pluginScreenShareModeIsActive() {
                self.showPluginView(show: true)
            }
            else if self.viewModel.pinModeIsActive {
                self.showPinnedView(show: true)
            }
        }else {
            self.showPinnedPluginView(show: false, animation: true)
        }
    }
    
    func refreshPluginsScreenShareView() {
        self.showHidePluginPinnedAndScreenShareView()
        if self.viewModel.pluginScreenShareModeIsActive() {
            let participants = self.viewModel.screenShareViewModel.arrScreenShareParticipants
            let arrButtons = self.getScreenShareTabButton(participants: participants)
            self.refreshPluginsButtonTab(pluginsButtonsModels: participants, arrButtons: arrButtons)
            if arrButtons.count >= 1 {
                var selectedIndex: Int?
                if let index = self.viewModel.screenShareViewModel.selectedIndex?.0 {
                    selectedIndex = Int(index)
                }
                if let index = selectedIndex {
                    if let pluginModel = participants[index] as? PluginButtonModel, let pluginModelView = pluginModel.plugin.getPluginView() {
                        self.pluginScreenShareView.show(pluginView: pluginModelView)
                    }
                    else if let screenShare = participants[index] as? ScreenShareModel {
                        self.pluginScreenShareView.showVideoView(participant: screenShare.participant)
                    }
                    self.loadGrid(fullScreen: false, animation: false, completion: {})
                }
            }
        } else {
            self.closefullscreen()
            if UIScreen.isLandscape() == false {
                self.fullScreenButton.isHidden = true
            }
            
            if self.viewModel.pinModeIsActive {
                self.pluginScreenShareView.setButtons(buttons: [RtkPluginScreenShareTabButton](), selectedIndex: nil) {_,_  in}
                let pinnedParticipant : RtkMeetingParticipant = self.meeting.participants.pinned == nil ? self.meeting.localUser : self.meeting.participants.pinned! as RtkMeetingParticipant
                self.pinnedView.setParticipant(meeting: self.meeting, participant: pinnedParticipant)
                self.loadGrid(fullScreen: false, animation: false, completion: {})
            } else {
                self.loadGrid(fullScreen: true, animation: false, completion: {})
            }
        }
        
        self.meetingGridPageBecomeVisible()
    }
    
    private func showPluginView(show: Bool) {
        self.pluginScreenShareView.isHidden = !show
        self.pinnedView.isHidden = true
    }
    
    private func showPinnedView(show: Bool) {
        self.pinnedView.isHidden = !show
        self.pluginScreenShareView.isHidden = true
    }
    
    private func showPinnedPluginView(show: Bool, animation: Bool) {
        self.showPinnedPluginViewAsPerOrientation(show: show)
        pluginPinnedScreenShareBaseView.isHidden = !show
        if animation {
            UIView.animate(withDuration: Animations.gridViewAnimationDuration) {
                self.view.layoutIfNeeded()
            }
        }else {
            self.view.layoutIfNeeded()
        }
    }
    
    private func loadGrid(fullScreen: Bool, animation: Bool, completion:@escaping()->Void) {
        let arrModels = self.viewModel.arrGridParticipants
        if fullScreen == false {
            if UIScreen.isLandscape() {
                self.gridView.settingFramesForPluginsActiveInLandscapeMode(visibleItemCount: UInt(arrModels.count), animation: animation) { finish in
                    completion()
                }
            }else {
                self.gridView.settingFramesForPluginsActiveInPortraitMode(visibleItemCount: UInt(arrModels.count), animation: animation) { finish in
                    completion()
                }
            }
            
        }else {
            if UIScreen.isLandscape() {
                self.gridView.settingFramesForLandScape(visibleItemCount: UInt(arrModels.count), animation: animation) { finish in
                    completion()
                }
            }else {
                self.gridView.settingFrames(visibleItemCount: UInt(arrModels.count), animation: animation) { finish in
                    completion()
                }
            }
            
        }
    }
    
    internal func refreshMeetingGridTile(participant: RtkMeetingParticipant) {
        let arrModels = self.viewModel.arrGridParticipants
        var index = -1
        for model in arrModels {
            index += 1
            if model.participant.userId == participant.userId {
                if let peerContainerView = self.gridView.childView(index: index) {
                    let isSelf = arrModels[index].participant.id == self.meeting.localUser.id
                    if isSelf {
                        if let selfParticipant = arrModels[index].participant as? RtkSelfParticipant {
                            peerContainerView.setParticipant(meeting: self.meeting, participant: selfParticipant)
                        }
                    } else {
                        if let remoteParticipant = arrModels[index].participant as? RtkRemoteParticipant{
                            peerContainerView.setParticipant(meeting: self.meeting, participant: remoteParticipant)
                        }
                    }
                }
            }
        }
    }
    
    private func meetingGridPageBecomeVisible() {
        if let participant = meeting.participants.pinned {
            self.refreshMeetingGridTile(participant: participant)
        }
        self.topBar.refreshNextPreviouButtonState()
    }
}



extension MeetingViewController: RtkNotificationDelegate {
    
    public func didReceiveNotification(type: RtkNotificationType) {
        switch type {
        case .Chat(let message):
            if Shared.data.notification.newChatArrived.playSound == true {
                viewModel.rtkNotification.playNotificationSound(type: type)
            }
            if Shared.data.notification.newChatArrived.showToast && message.isEmpty == false {
                self.view.showToast(toastMessage: message, duration: 2.0, uiBlocker: false, showInBottom: true, bottomSpace: self.bottomBar.bounds.height)
            }
            NotificationCenter.default.post(name: Notification.Name("Notify_NewChatArrived"), object: nil, userInfo: nil)
            self.moreButtonBottomBar?.notificationBadge.isHidden = false
            
            let totalMessage = self.meeting.chat.messages.count
            self.moreButtonBottomBar?.notificationBadge.setBadgeCount(Shared.data.getTotalUnreadCountPollsAndChat(totalMessage: totalMessage, totalsPolls: self.meeting.polls.items.count))
            
        case .Poll:
            NotificationCenter.default.post(name: Notification.Name("Notify_NewPollArrived"), object: nil, userInfo: nil)
            if Shared.data.notification.newPollArrived.playSound == true {
                viewModel.rtkNotification.playNotificationSound(type: .Poll)
            }
            self.moreButtonBottomBar?.notificationBadge.isHidden = false
            self.moreButtonBottomBar?.notificationBadge.setBadgeCount(Shared.data.getTotalUnreadCountPollsAndChat(totalMessage: self.meeting.chat.messages.count, totalsPolls: self.meeting.polls.items.count))
            
        case .Joined:
            if Shared.data.notification.participantJoined.playSound == true {
                viewModel.rtkNotification.playNotificationSound(type: .Joined)
            }
        case .Leave:
            if Shared.data.notification.participantLeft.playSound == true {
                viewModel.rtkNotification.playNotificationSound(type: .Leave)
            }
        }
    }
    
    @objc
    public  func clearChatNotification() {
        self.moreButtonBottomBar?.notificationBadge.isHidden = true
    }
}

extension MeetingViewController: RtkLivestreamEventListener {
    public func onLivestreamError(message: String) {
        
    }
    
    public func onLivestreamStateChanged(oldState: RealtimeKit.LivestreamState, newState: RealtimeKit.LivestreamState) {
        
    }
    
    public func onLivestreamUpdate(data: RtkLivestreamData) {
        
    }
        
    public func onStageCountUpdated(count: Int32) {
        if meeting.stage.stageStatus == StageStatus.offStage {
//            let controller = LivestreamViewController(rtkClient: meeting, completion: self.onFinishedMeeting)
//            controller.view.backgroundColor = self.view.backgroundColor
//            controller.modalPresentationStyle = .fullScreen
//            self.present(controller, animated: true)
//            notificationDelegate?.didReceiveNotification(type: .Joined)
        }
    }
    
    public func onViewerCountUpdated(count: Int32) {
        
    }
}

extension MeetingViewController: RtkChatEventListener {
    
    public func onMessageRateLimitReset() {
        
    }
    
    public func onChatUpdates(messages: [ChatMessage]) {
        
    }
    
    public func onNewChatMessage(message: ChatMessage) {
        if message.userId != meeting.localUser.userId {
            var chat = ""
            if  let textMessage = message as? TextMessage {
                chat = "\(textMessage.displayName): \(textMessage.message)"
            }else {
                if message.type == ChatMessageType.image {
                    chat = "\(message.displayName): Send you an Image"
                } else if message.type == ChatMessageType.file {
                    chat = "\(message.displayName): Send you an File"
                }
            }
            notificationDelegate?.didReceiveNotification(type: .Chat(message:chat))
        }
        
        if let targetUserIds = message.targetUserIds {
            
            if !targetUserIds.isEmpty {
                let localUserId = meeting.localUser.userId
                targetUserIds
                    .filter { $0 != localUserId }
                    .forEach {
                        Shared.data.privateChatReadLookup[$0] = true
                    }
            }
        }
    }
}

// Notification Related Methods
extension MeetingViewController {
    func setupNotifications() {
        meeting.addChatEventListener(chatEventListener: self)
        NotificationCenter.default.addObserver(self, selector: #selector(self.clearChatNotification), name: Notification.Name("NotificationAllChatsRead"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onEndMettingForAllButtonPressed), name: RtkLeaveDialog.onEndMeetingForAllButtonPress, object: nil)
    }
    // MARK: Notification Setup Functionality
    @objc private func onEndMettingForAllButtonPressed(notification: Notification) {
        self.viewModel.selfEventListener.observeSelfRemoved(update: nil)
    }
}


extension MeetingViewController {
    func addFullScreenView(contentView: UIView) {
        if fullScreenView == nil {
            fullScreenView =  FullScreenView()
            self.view.addSubview(fullScreenView)
            fullScreenView.set(.fillSuperView(self.view))
        }
        fullScreenView.backgroundColor = self.view.backgroundColor
        fullScreenView.isUserInteractionEnabled = true
        fullScreenView.set(contentView: contentView)
    }
    
    func removeFullScreenView() {
        fullScreenView.backgroundColor = .clear
        fullScreenView.isUserInteractionEnabled = false
        fullScreenView.removeContentView()
    }
}


class FullScreenView: UIView {
    let containerView = UIView()
    var isVisible: Bool = false
    init() {
        super.init(frame: CGRect.zero)
        self.addSubview(self.containerView)
        self.containerView.set(.fillSuperView(self))
        self.setEdgeConstants()
    }
    
    func set(contentView: UIView) {
        isVisible = true
        containerView.addSubview(contentView)
        contentView.set(.fillSuperView(containerView))
    }
    
    func removeContentView() {
        isVisible = true
        for subview in containerView.subviews {
            subview.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setEdgeConstants()
    }
    
    private func setEdgeConstants() {
        self.containerView.get(.leading)?.constant = self.safeAreaInsets.left
        self.containerView.get(.trailing)?.constant = -self.safeAreaInsets.right
        self.containerView.get(.top)?.constant = self.safeAreaInsets.top
        self.containerView.get(.bottom)?.constant = -self.safeAreaInsets.bottom
    }
    
}



