//
//  File.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/02/23.
//

import RealtimeKit


class RtkMeetingEventListener  {
    
    private var selfAudioStateCompletion:((Bool)->Void)?
    private var recordMeetingStartCompletion:((Bool)->Void)?
    private var recordMeetingStopCompletion:((Bool)->Void)?
    private var selfJoinedStateCompletion:((Bool)->Void)?
    private var selfLeaveStateCompletion:((Bool)->Void)?
    private var participantLeaveStateCompletion:((RtkMeetingParticipant)->Void)?
    private var participantJoinStateCompletion:((RtkMeetingParticipant)->Void)?
    private var participantPinnedStateCompletion:((RtkMeetingParticipant)->Void)?
    private var participantUnPinnedStateCompletion:((RtkMeetingParticipant)->Void)?
    
    var rtkClient: RealtimeKitClient
    
    init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
        self.rtkClient.addRecordingEventListener(recordingEventListener: self)
        self.rtkClient.addParticipantsEventListener(participantsEventListener: self)
    }
    
    func clean() {
        self.rtkClient.removeParticipantsEventListener(participantsEventListener: self)
        self.rtkClient.removeRecordingEventListener(recordingEventListener: self)
    }
    
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    
    public func startRecordMeeting(completion:@escaping (_ success: Bool) -> Void) {
        self.recordMeetingStartCompletion = completion
        self.rtkClient.recording.start { _ in }
    }
    
    public func stopRecordMeeting(completion:@escaping (_ success: Bool) -> Void) {
        self.recordMeetingStopCompletion = completion
        self.rtkClient.recording.stop { _ in }
    }
    
    
    public func joinMeeting(completion:@escaping (_ success: Bool) -> Void) {
        self.selfJoinedStateCompletion = completion
        self.rtkClient.joinRoom(onSuccess: {}, onFailure: {_ in})
    }
    
    public func leaveMeeting(completion:@escaping(_ success: Bool)->Void) {
        self.selfLeaveStateCompletion = completion
        self.rtkClient.leaveRoom(onSuccess: {}, onFailure: {_ in})
    }
    
    
    public func observeParticipantJoin(update:@escaping(_ participant: RtkMeetingParticipant)->Void) {
        participantJoinStateCompletion = update
    }
    
    public func observeParticipantLeave(update:@escaping(_ participant: RtkMeetingParticipant)->Void) {
        participantLeaveStateCompletion = update
    }
    
    public func observeParticipantPinned(update:@escaping(_ participant: RtkMeetingParticipant)->Void) {
        participantPinnedStateCompletion = update
    }
    
    public func observeParticipantUnPinned(update:@escaping(_ participant: RtkMeetingParticipant)->Void) {
        participantUnPinnedStateCompletion = update
    }
    
    deinit{
        print("RtkMeetingEventListener deallocing")
    }
}

extension RtkMeetingEventListener: RtkRecordingEventListener {
    func onRecordingStateChanged(oldState: RecordingState, newState: RecordingState) {
        if(oldState != newState){
            switch newState {
            case .idle: if oldState == .stopping{
                onMeetingRecordingEnded()
            }
            case .recording: if oldState == .starting {
                onMeetingRecordingStarted()
            }
            default:
                break
            }
        }
    }
    
    func onMeetingRecordingEnded() {
        self.recordMeetingStopCompletion?(true)
        self.recordMeetingStopCompletion = nil
    }
    
    func onMeetingRecordingStarted() {
        self.recordMeetingStartCompletion?(true)
        self.recordMeetingStartCompletion = nil
    }
}

extension RtkMeetingEventListener: RtkParticipantsEventListener {
    func onActiveParticipantsChanged(active: [RtkRemoteParticipant]) {
        
    }
    
    func onActiveSpeakerChanged(participant: RtkRemoteParticipant?) {
        
    }
    
    func onAllParticipantsUpdated(allParticipants: [RtkParticipant]) {
        
    }
    
    func onAudioUpdate(participant: RtkRemoteParticipant, isEnabled: Bool) {
        
    }
    
    func onNewBroadcastMessage(type: String, payload: [String : Any]) {
        
    }
    
    func onScreenShareUpdate(participant: RtkRemoteParticipant, isEnabled: Bool) {
        
    }
    
    func onUpdate(participants: RtkParticipants) {
        
    }
    
    func onVideoUpdate(participant: RtkRemoteParticipant, isEnabled: Bool) {
        
    }
    
    
    func onParticipantPinned(participant: RtkRemoteParticipant) {
        self.participantPinnedStateCompletion?(participant)
    }
    
    func onParticipantUnpinned(participant: RtkRemoteParticipant) {
        self.participantUnPinnedStateCompletion?(participant)
    }
    
    func onParticipantJoin(participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | Delegate onParticipantJoin \(participant.audioEnabled) \(participant.name) totalCount \(self.rtkClient.participants.joined) participants")
        }
        self.participantJoinStateCompletion?(participant)
    }
    
    func onParticipantLeave(participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | Delegate onParticipantLeave \(self.rtkClient.participants.active.count)")
        }
        self.participantLeaveStateCompletion?(participant)
    }
    
}

