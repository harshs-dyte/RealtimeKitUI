//
//  WebinarViewController.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 17/04/23.
//

import UIKit
import RealtimeKit

public enum WebinarStageStatus {
    case canJoinStage
    case joiningStage
    case alreadyOnStage
    case leavingFromStage
    case canRequestToJoinStage
    case requestingToJoinStage
    case inRequestedStateToJoinStage
    case viewOnly
}

public class WebinarViewController: MeetingViewController {
    private var waitingView : WaitingRoomView?
    var webinarViewModel : WebinarViewModel?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        webinarViewModel = WebinarViewModel(rtkClient: meeting)
        webinarViewModel?.stageDelegate = self
    }
    
    func createWaitingView(message: String) -> WaitingRoomView {
        let waitingView = WaitingRoomView(automaticClose: false, onCompletion: {})
        waitingView.backgroundColor = self.view.backgroundColor
        self.gridBaseView.addSubview(waitingView)
        waitingView.set(.fillSuperView(self.gridBaseView))
        waitingView.button.isHidden = true
        waitingView.show(message: message)
        return waitingView
    }
    
    public override func refreshMeetingGrid(forRotation: Bool = false) {
        super.refreshMeetingGrid(forRotation: forRotation)
        self.waitingView?.removeFromSuperview()
        let mediaPermission = meeting.localUser.permissions.media
        
        if (mediaPermission.audioPermission == MediaPermission.allowed || mediaPermission.video.permission == MediaPermission.allowed) && meeting.participants.active.isEmpty && StageStatus.getStageStatus(rtkClient: meeting) == .canJoinStage {
            self.waitingView = createWaitingView(message: "The stage is empty.\nYou are off stage. You can manage stage request from the participants tab.")
        } else if meeting.participants.active.isEmpty && meeting.localUser.stageStatus != .onStage {
            self.waitingView = createWaitingView(message: "Webinar has not yet been started")
        }
    }
    
    override func getBottomBar() -> RtkControlBar {
        return getTabBar()
    }
    
    func getTabBar() -> RtkControlBar {
        let controlBar = RtkWebinarControlBar(meeting: self.meeting, delegate: nil, dataSource: nil, presentingViewController: self) { button in
        } settingViewControllerCompletion: {
            [weak self] in
            guard let self = self else {return}
            self.refreshMeetingGridTile(participant: self.meeting.localUser)
        } onLeaveMeetingCompletion: {
            [weak self] in
            guard let self = self else {return}
            self.viewModel.clean()
            self.onFinishedMeeting()
        }
        return controlBar
    }
    
    func updateNotificationWithToast(message: String) {
        self.view.showToast(toastMessage: message, duration: 2.0, uiBlocker: false)
        updateMoreButtonNotificationBubble()
        NotificationCenter.default.post(name: Notification.Name("Notify_ParticipantListUpdate"), object: nil, userInfo: nil)
    }
}

extension WebinarViewController: RtkStageDelegate {
    func onPresentRequestAdded(participant: RtkRemoteParticipant) {
        updateNotificationWithToast(message: "\(participant.name) has requested to join stage")
    }
    
    func onPresentRequestWithdrawn(participant: RtkRemoteParticipant) {
        updateNotificationWithToast(message: "\(participant.name) has cancelled to join stage")
    }
}

