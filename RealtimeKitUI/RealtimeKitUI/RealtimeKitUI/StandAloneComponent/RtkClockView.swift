//
//  RtkClockView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import RealtimeKit



public class RtkClockView: RtkLabel {
    private let meeting: RealtimeKitClient
    var meetingTimer: Timer?

    public init(meeting: RealtimeKitClient, appearance: RtkTextAppearance = AppTheme.shared.clockViewAppearance) {
        self.meeting = meeting
        super.init(appearance: appearance)
        self.showMeetingTime()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   private func showMeetingTime() {
        let dateFormatter = DateFormatter()
               dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        if let startDate =  dateFormatter.date(from: self.meeting.meta.meetingStartedTimestamp)   {
            self.meetingTimer?.invalidate()
            self.meetingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                let timeInSeconds = Int64(Date().timeIntervalSince(startDate))
                let timeToDisplay = self.getTime(second: timeInSeconds)
                self.text = timeToDisplay
            }
        }
    }
    
   private func getTime(second:Int64) -> String {
        let hours = second / 3600
        let secondsLeftAfterHour = second % 3600
        let minutes = secondsLeftAfterHour/60
        let secondsLeftAfterMinute = secondsLeftAfterHour % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secondsLeftAfterMinute)
    }
}
