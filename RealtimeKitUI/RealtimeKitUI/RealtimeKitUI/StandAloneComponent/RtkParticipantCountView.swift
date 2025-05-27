//
//  RtkParticipantCountView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import RealtimeKit

public class RtkParticipantCountView: RtkLabel {
    private let meeting: RealtimeKitClient
    
    public init(meeting: RealtimeKitClient, appearance: RtkTextAppearance = AppTheme.shared.participantCountAppearance) {
        self.meeting = meeting
        super.init(appearance: appearance)
        self.text = ""
        self.meeting.addParticipantsEventListener(participantsEventListener: self)
        self.meeting.addMeetingRoomEventListener(meetingRoomEventListener: self)
        update()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.meeting.removeParticipantsEventListener(participantsEventListener: self)
    }
    
    private func update() {
        let participantCount = self.meeting.participants.totalCount
        if participantCount <= 1 {
            self.text = "Only you"
        } else {
            self.text = "\(participantCount) participants"
        }
    }
    
}

extension RtkParticipantCountView: RtkMeetingRoomEventListener {
    public func onActiveTabUpdate(meeting: RealtimeKitClient, activeTab: ActiveTab) {
        
    }
    
    public func onMeetingEnded() {
        
    }
    
    public func onMeetingInitCompleted(meeting: RealtimeKitClient) {
        
    }
    
    public func onMeetingInitFailed(error: MeetingError) {
        
    }
    
    public func onMeetingInitStarted() {
        
    }
    
    public func onMeetingRoomJoinCompleted(meeting: RealtimeKitClient) {
        
    }
    
    public func onMeetingRoomJoinFailed(error: MeetingError) {
        
    }
    
    public func onMeetingRoomJoinStarted() {
        
    }
    
    public func onMeetingRoomLeaveCompleted() {
        
    }
    
    public func onMeetingRoomLeaveStarted() {
        
    }
    
    public func onMediaConnectionUpdate(update: MediaConnectionUpdate) {
        
    }
    
    public func onSocketConnectionUpdate(newState: SocketConnectionState) {
        if(newState.socketState==SocketState.connected){
            update()
        }
    }
}

extension RtkParticipantCountView: RtkParticipantsEventListener {
    public func onAllParticipantsUpdated(allParticipants: [RtkParticipant]) {
        
    }
    
    public func onUpdate(participants: RtkParticipants) {
        
    }
    
    public func onParticipantJoin(participant: RtkRemoteParticipant) {
        self.update()
    }
    
    public func onParticipantLeave(participant: RtkRemoteParticipant) {
        self.update()
    }
    
    public func onActiveParticipantsChanged(active: [RtkRemoteParticipant]) {
        
    }
    
    public func onActiveSpeakerChanged(participant: RtkRemoteParticipant?) {
        
    }
    
    public func onAudioUpdate(participant: RtkRemoteParticipant, isEnabled: Bool) {
        
    }
    
    public func onNewBroadcastMessage(type: String, payload: [String : Any]) {
        
    }
    
    public func onParticipantPinned(participant: RtkRemoteParticipant) {
        
    }
    
    public func onParticipantUnpinned(participant: RtkRemoteParticipant) {
        
    }
    
    public func onScreenShareUpdate(participant: RtkRemoteParticipant, isEnabled: Bool) {
        
    }
    
    public func onVideoUpdate(participant: RtkRemoteParticipant, isEnabled: Bool) {
        
    }
    
}
