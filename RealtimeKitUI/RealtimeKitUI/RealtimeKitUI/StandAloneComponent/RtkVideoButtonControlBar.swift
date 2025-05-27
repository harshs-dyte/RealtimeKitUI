//
//  RtkVideoButton.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 10/04/23.
//

import RealtimeKit
import UIKit

open class  RtkVideoButtonControlBar: RtkControlBarButton {
    private let rtkClient: RealtimeKitClient
    private var rtkSelfListener: RtkEventSelfListener
    
    public init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
        self.rtkSelfListener = RtkEventSelfListener(rtkClient: rtkClient)
        super.init(image: RtkImage(image: ImageProvider.image(named: "icon_video_enabled")), title: "Video On")
        self.setSelected(image: RtkImage(image: ImageProvider.image(named: "icon_video_disabled")), title: "Video off")
        self.selectedStateTintColor = rtkSharedTokenColor.status.danger
        self.addTarget(self, action: #selector(onClick(button:)), for: .touchUpInside)
        self.isSelected = !rtkClient.localUser.videoEnabled
        self.rtkSelfListener.observeSelfVideo { [weak self] enabled in
            guard let self = self else {return}
            self.isSelected = !enabled
        }
       
    }
    
    public override var isSelected: Bool {
        didSet {
            if isSelected == true {
                self.accessibilityIdentifier = "Video_ControlBarButton_Selected"
            }else {
                self.accessibilityIdentifier = "Video_ControlBarButton_UnSelected"
            }
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    @objc open func onClick(button: RtkControlBarButton) {
        if rtkSelfListener.isCameraPermissionGranted() {
            button.showActivityIndicator()
            rtkSelfListener.toggleLocalVideo(completion: { enableVideo in
                button.isSelected = !enableVideo
                button.hideActivityIndicator()
            })
        }
    }
    deinit {
        self.rtkSelfListener.clean()
    }
}

