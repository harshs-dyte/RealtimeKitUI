//
//  RtkSwitchCameraButtonControlBar.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import RealtimeKit

open class  RtkSwitchCameraButtonControlBar: RtkControlBarButton {
    private let meeting: RealtimeKitClient
    private var rtkSelfListener: RtkEventSelfListener
    
    public init(meeting: RealtimeKitClient) {
        self.meeting = meeting
        self.rtkSelfListener = RtkEventSelfListener(rtkClient: meeting)
        super.init(image: RtkImage(image: ImageProvider.image(named: "icon_flipcamera_topbar")))
        self.addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
        if meeting.localUser.permissions.media.canPublishVideo {
            self.isHidden = !meeting.localUser.videoEnabled
            self.rtkSelfListener.observeSelfVideo { enabled in
                self.isHidden = !enabled
            }
        }
        else {
            self.isHidden = false
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    @objc open func onClick(button: RtkControlBarButton) {
        rtkSelfListener.toggleCamera()
    }
    
    deinit {
        self.rtkSelfListener.clean()
    }
}

