//
//  RtkWebinarControlBar.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 15/01/24.
//

import UIKit
import RealtimeKit


public protocol RtkWebinarControlBarDataSource {
    func getMicControlBarButton(for stageStatus: WebinarStageStatus) ->  RtkControlBarButton?
    func getVideoControlBarButton(for stageStatus: WebinarStageStatus) ->  RtkControlBarButton?
    func getStageActionControlBarButton(for stageStatus: WebinarStageStatus) ->  RtkStageActionButtonControlBar?
}

open class RtkWebinarControlBar: RtkControlBar {
    private let meeting: RealtimeKitClient
    private let onRequestButtonClick: (RtkControlBarButton)->Void
    private let presentingViewController: UIViewController
    private let selfListener: RtkEventSelfListener
    private weak var stageActionControlButton: RtkStageActionButtonControlBar?
    private let dataSource: RtkWebinarControlBarDataSource?
   
    init(meeting: RealtimeKitClient, delegate: RtkTabBarDelegate?, dataSource: RtkWebinarControlBarDataSource?, presentingViewController: UIViewController, appearance: RtkControlBarAppearance = RtkControlBarAppearanceModel(), onRequestButtonClick:@escaping(RtkControlBarButton)->Void, settingViewControllerCompletion:(()->Void)? = nil, onLeaveMeetingCompletion: (()->Void)? = nil) {
        self.meeting = meeting
        self.dataSource = dataSource
        self.presentingViewController = presentingViewController
        self.onRequestButtonClick = onRequestButtonClick
        self.selfListener = RtkEventSelfListener(rtkClient: meeting, identifier: "Webinar Control Bar")
    
        super.init(meeting: meeting, delegate: delegate, presentingViewController: presentingViewController, settingViewControllerCompletion: settingViewControllerCompletion, onLeaveMeetingCompletion: onLeaveMeetingCompletion)
        self.refreshBar()
        self.selfListener.observeWebinarStageStatus { status in
            self.refreshBar()
            self.stageActionControlButton?.updateButton(stageStatus: status)
        }
        self.selfListener.observeRequestToJoinStage { [weak self] in
            guard let self = self else {return}
            self.stageActionControlButton?.handleRequestToJoinStage()
        }
    }
    
    override func onRotationChange() {
        super.onRotationChange()
        self.setTabBarButtonTitles(numOfLines: UIScreen.isLandscape() ? 2 : 1)
    }
    
    private func getStageStatus() -> WebinarStageStatus {
        let state = self.meeting.stage.stageStatus
        switch state {
        case .offStage:
            // IN off Stage three condition is possible whether
            // 1 He can send request(Permission to join Stage) for approval.(canRequestToJoinStage)
            // 2 He is only in view mode, means can't do anything expect watching.(viewOnly)
            // 3 He is already have permission to join stage and if this is true then stage.stageStatus == acceptedToJoinStage (canJoinStage)
            let videoPermission = self.meeting.localUser.permissions.media.video.permission
            let audioPermission = self.meeting.localUser.permissions.media.audioPermission
            if videoPermission == MediaPermission.allowed || audioPermission == .allowed {
                // Person can able to join on Stage, It means he/she already have permission to join stage.
                return .canJoinStage
            }
            else if videoPermission == MediaPermission.canRequest || audioPermission == .canRequest {
                return .canRequestToJoinStage
            } else if videoPermission == MediaPermission.notAllowed && audioPermission == .notAllowed {
                return .viewOnly
            }
            return .viewOnly
        case .acceptedToJoinStage:
            return .canJoinStage
        case .onStage:
            return .alreadyOnStage
        case .requestedToJoinStage:
            return .inRequestedStateToJoinStage
        }
    }

    deinit {
        self.selfListener.clean()
    }
    
    private func refreshBar() {
        self.refreshBar(stageStatus: self.getStageStatus())
        if UIScreen.isLandscape() {
            self.moreButton.superview?.isHidden = true
        }
        self.setTabBarButtonTitles(numOfLines: UIScreen.isLandscape() ? 2 : 1)
    }
    
    private func refreshBar(stageStatus: WebinarStageStatus) {
        
        var arrButtons = [RtkControlBarButton]()
        
        if stageStatus == .alreadyOnStage {
            let micButton = self.dataSource?.getMicControlBarButton(for: stageStatus) ?? RtkAudioButtonControlBar(meeting: meeting)
            arrButtons.append(micButton)
            let videoButton = self.dataSource?.getVideoControlBarButton(for: stageStatus) ?? RtkVideoButtonControlBar(rtkClient: meeting)
            arrButtons.append(videoButton)
        }
        
        var stageButton: RtkStageActionButtonControlBar?
        if stageStatus != .viewOnly {
            let button = self.dataSource?.getStageActionControlBarButton(for: stageStatus) ?? RtkStageActionButtonControlBar(rtkClient: meeting, buttonState: stageStatus, presentingViewController: self.presentingViewController)
            arrButtons.append(button)
            stageButton = button
        }
        self.setButtons(arrButtons)
            //This is done so that we will get the notification after releasing the old stageButton, Now we will receive one notification
        stageButton?.addObserver()
        self.stageActionControlButton = stageButton
    }
        
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   
}
