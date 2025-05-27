//
//  RtkMeetingNameTag.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import RealtimeKit

public class RtkMeetingNameTag: RtkNameTag {
    private let meeting: RealtimeKitClient
    private var participant: RtkMeetingParticipant
    
    public init(meeting: RealtimeKitClient, participant: RtkMeetingParticipant, appearance: RtkNameTagAppearance = AppTheme.shared.nameTagAppearance) {
        self.participant = participant
        self.meeting = meeting
        super.init(image: RtkImage(image: ImageProvider.image(named: "icon_mic_enabled")), appearance: appearance, title: "")
        refresh()
    }
    
    public func set(participant: RtkMeetingParticipant) {
        self.participant = participant
        refresh()
    }
    
    public func refresh() {
        let name = self.participant.name
        if self.meeting.localUser.userId == self.participant.userId {
            self.lblTitle.text = "\(name) (you)"
        }else {
            self.lblTitle.text = name
        }
        self.setAudio(isEnabled: self.participant.audioEnabled)
    }
    
    private func setAudio(isEnabled: Bool) {
        if isEnabled {
            self.imageView.accessibilityIdentifier = "NameTag_Mic_Enabled"
            self.imageView.image = ImageProvider.image(named: "icon_mic_enabled")?.withRenderingMode(.alwaysTemplate)
            self.imageView.tintColor = appearance.desingLibrary.color.textColor.onBackground.shade1000
        }else {
            self.imageView.accessibilityIdentifier = "NameTag_Mic_Disabled"
            self.imageView.image = ImageProvider.image(named: "icon_mic_disabled")?.withRenderingMode(.alwaysTemplate)
            self.imageView.tintColor = appearance.desingLibrary.color.status.danger
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
