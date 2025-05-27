//
//  RtkMoreMenuBottomSheet.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import RealtimeKit
import ReplayKit

class RtkMoreMenuBottomSheet {
    private let presentingViewController: UIViewController
    private let settingViewControllerCompletion:(()->Void)?
    private let meeting: RealtimeKitClient
    
    init(menus: [MenuType], meeting: RealtimeKitClient, presentingViewController: UIViewController, settingViewControllerCompletion:(()->Void)? = nil) {
        self.settingViewControllerCompletion = settingViewControllerCompletion
        self.presentingViewController = presentingViewController
        self.meeting = meeting
        
        create(menus: menus)
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var moreMenu: RtkMoreMenu!
    
    func create(menus: [MenuType]) {
        moreMenu = RtkMoreMenu(features: menus, onSelect: { [weak self] menuType in
            guard let self = self else {return}
            switch menuType {
            case.muteAllAudio:
                self.muteAllAudio()
            case.muteAllVideo:
                self.muteAllVideo()
            case.shareMeetingUrl:
                self.shareMeetingUrl()
            case .chat:
                self.onChatTapped()
            case .startScreenShare:
                self.onScreenShareTapped()
            case .stopScreenShare:
                self.onStopScreenShareTapped()
            case .poll:
                self.launchPollsScreen()
            case .recordingStart:
                self.meeting.recording.start(){ _ in}
            case .recordingStop:
                self.meeting.recording.stop(){ _ in}
            case .settings:
                self.launchSettingScreen()
            case .plugins:
                self.onPluginTapped()
            case .particpants:
                self.launchParticipantScreen()
            default:
                print("Not Supported for now")
            }
        })
        moreMenu.accessibilityIdentifier = "MoreMenu_BottomSheet"
    }
    
    func reload(title:String? = nil, features: [MenuType]) {
        moreMenu.reload(title:title, features: features)
    }
    
    func show() {
        moreMenu.show(on: self.presentingViewController.view)
    }
    
    func hide() {
        moreMenu.hideSheet()
    }
}



private extension RtkMoreMenuBottomSheet {
    private func launchPollsScreen() {
        let controller = RtkShowPollsViewController(meeting: self.meeting)
        self.presentingViewController.present(controller, animated: true)
        Shared.data.setPollViewCount(totalPolls: self.meeting.polls.items.count)
    }
    
    private func launchSettingScreen() {
        let controller = RtkSettingViewController(nameTag: self.meeting.localUser.name, meeting: self.meeting, completion: self.settingViewControllerCompletion)
        controller.view.backgroundColor = self.presentingViewController.view.backgroundColor
        controller.modalPresentationStyle = .fullScreen
        self.presentingViewController.present(controller, animated: true)
    }
    
    private func shareMeetingUrl() {
        if let name = URL(string: "https://demo.dyte.io/v2/meeting?id=\(self.meeting.meta.meetingId)"), !name.absoluteString.isEmpty {
            let objectsToShare = [name]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.presentingViewController.present(activityVC, animated: true, completion: nil)
        } else {
            // show alert for not available
        }
    }
    
    private func muteAllAudio() {
        meeting.participants.disableAllAudio()
    }
    
    private func muteAllVideo() {
        meeting.participants.disableAllVideo()
    }
    
    private func launchParticipantScreen() {
        var controller: UIViewController  = ParticipantViewControllerFactory.getParticipantViewController(meeting: self.meeting)
        
        if self.meeting.meta.meetingType == RtkMeetingType.webinar {
            controller = WebinarParticipantViewController(viewModel: WebinarParticipantViewControllerModel(rtkClient: self.meeting))
        }
        controller.view.backgroundColor = self.presentingViewController.view.backgroundColor
        controller.modalPresentationStyle = .fullScreen
        self.presentingViewController.present(controller, animated: true)
    }
    
    private func onChatTapped() {
        let controller = RtkChatViewController(meeting: self.meeting)
        controller.modalPresentationStyle = .fullScreen
        self.presentingViewController.present(controller, animated: true, completion: nil)
        Shared.data.setChatReadCount(totalMessage: self.meeting.chat.messages.count)
    }
    
    private func onScreenShareTapped() {
        self.meeting.localUser.enableScreenShare()
    }
    
    private func onStopScreenShareTapped() {
        self.meeting.localUser.disableScreenShare()
    }
    
    private func onPluginTapped() {
        let controller = RtkPluginViewController(plugins: meeting.plugins.all)
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        presentingViewController.present(navigationController, animated: false, completion: nil)
    }
}
