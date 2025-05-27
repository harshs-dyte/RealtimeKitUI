//
//  RtkMeetingTitle.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import RealtimeKit

public class RtkMeetingTitleLabel: RtkLabel {
    private let meeting: RealtimeKitClient
    
    public init(meeting: RealtimeKitClient, appearance: RtkTextAppearance = AppTheme.shared.meetingTitleAppearance) {
        self.meeting = meeting
        super.init(appearance: appearance)
        self.text = self.meeting.meta.meetingTitle
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
