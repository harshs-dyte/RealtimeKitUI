//
//  RtkLeaveDialog.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import RealtimeKit




public class RtkLeaveDialog {
    public static let onEndMeetingForAllButtonPress: Notification.Name = Notification.Name("onEndMeetingForAllButtonPress")
    public  enum RtkLeaveDialogAlertButtonType {
        case willLeaveMeeting
        case didLeaveMeeting
        
        case willEndMeetingForAll
        case didEndMeetingForAll

        case cancel
        case nothing
    }
    private let meeting: RealtimeKitClient
    private var rtkSelfListener: RtkEventSelfListener
    private let onClick: ((RtkLeaveDialogAlertButtonType)->Void)?

    public init(meeting: RealtimeKitClient, onClick:((RtkLeaveDialogAlertButtonType)->Void)? = nil) {
        self.meeting = meeting
        self.rtkSelfListener = RtkEventSelfListener(rtkClient: meeting)
        self.onClick = onClick
    }
    
    deinit {
        self.rtkSelfListener.clean()
    }
    
    public func show(on viewController: UIViewController) {
        self.showEndCallAlert(title: "Leave call?", message: "Do you really want to leave this call?", presentingController: viewController)
    }
    
    private func showEndCallAlert(title: String, message: String, presentingController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Leave", style: .default, handler: { action in
            self.onClick?(.willLeaveMeeting)
            self.rtkSelfListener.leaveMeeting(kickAll: false, completion: { success in
                // We have not used weak self, Because we want Delayed deallocation of UIAlertController in memory
                self.onClick?(.didLeaveMeeting)
            })
        }))
        
        if self.meeting.localUser.permissions.host.canKickParticipant {
            alert.addAction(UIAlertAction(title: "End Meeting for all", style: .default, handler: { action in
                self.onClick?(.willEndMeetingForAll)
                NotificationCenter.default.post(name: Self.onEndMeetingForAllButtonPress, object: nil)
                
                self.rtkSelfListener.leaveMeeting(kickAll: true, completion: { success in
                    self.onClick?(.didEndMeetingForAll)
                })
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            self.onClick?(.cancel)
        }))
        alert.view.accessibilityIdentifier = "Leave_Meeting_Alert"
        presentingController.present(alert, animated: true, completion: nil)
    }

}
