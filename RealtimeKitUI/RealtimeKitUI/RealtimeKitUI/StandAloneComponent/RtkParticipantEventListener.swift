//
//  RtkParticipantEventListener.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/02/23.
//

import RealtimeKit
import UIKit

class RtkParticipantUpdateEventListener  {
    private var participantAudioStateCompletion:((Bool)->Void)?
    private var participantVideoStateCompletion:((Bool)->Void)?
    
    private var participantObserveAudioStateCompletion:((Bool,RtkParticipantUpdateEventListener)->Void)?
    private var participantObserveVideoStateCompletion:((Bool,RtkParticipantUpdateEventListener)->Void)?
    private var participantPinStateCompletion:((Bool)->Void)?
    private var participantUnPinStateCompletion:((Bool)->Void)?
    private var participantObservePinStateCompletion:((Bool,RtkParticipantUpdateEventListener)->Void)?
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    
    let participant: RtkMeetingParticipant
    
    init(participant: RtkMeetingParticipant) {
        self.participant = participant
        participant.addParticipantUpdateListener(participantUpdateListener: self)
    }
    
    public func observeAudioState(update:@escaping(_ isEnabled: Bool,_ observer: RtkParticipantUpdateEventListener)->Void) {
        participantObserveAudioStateCompletion = update
    }
    
    public func observePinState(update:@escaping(_ isPinned: Bool,_ observer: RtkParticipantUpdateEventListener)->Void) {
        participantObservePinStateCompletion = update
    }
    
    public func observeVideoState(update:@escaping(_ isEnabled: Bool,_ observer: RtkParticipantUpdateEventListener)->Void){
        participantObserveVideoStateCompletion = update
    }
    
    public func muteAudio(completion:@escaping(_ isEnabled: Bool)->Void) {
        self.participantAudioStateCompletion = completion
        if let remoteParticipant = self.participant as? RtkRemoteParticipant {
            remoteParticipant.disableAudio()
        }
    }
    
    public func muteVideo(completion:@escaping(_ isEnabled: Bool)->Void) {
        self.participantVideoStateCompletion = completion
        if let remoteParticipant = self.participant as? RtkRemoteParticipant {
            remoteParticipant.disableVideo()
        }
    }
    
    public func pin(completion:@escaping(Bool)->Void) {
        self.participantPinStateCompletion = completion
        self.participant.pin()
    }
    
    public func unPin(completion:@escaping(Bool)->Void) {
        self.participantUnPinStateCompletion = completion
        self.participant.unpin()
    }
    
    
    public func clean() {
        self.participant.removeParticipantUpdateListener(participantUpdateListener: self)
    }
}

extension RtkParticipantUpdateEventListener: RtkParticipantUpdateListener {
    func onAudioUpdate(participant: RtkMeetingParticipant, isEnabled: Bool) {
        self.participantObserveAudioStateCompletion?(isEnabled, self)
        self.participantAudioStateCompletion?(isEnabled)
        self.participantAudioStateCompletion = nil
    }
    
    func onPinned(participant: RtkMeetingParticipant) {
        self.participantPinStateCompletion?(true)
        self.participantPinStateCompletion = nil
        self.participantObservePinStateCompletion?(true, self)
    }
    
    func onUnpinned(participant: RtkMeetingParticipant) {
        self.participantUnPinStateCompletion?(true)
        self.participantUnPinStateCompletion = nil
        self.participantObservePinStateCompletion?(false, self)
    }
    
    func onUpdate(participant: RtkMeetingParticipant) {
        
    }
    
    func onScreenShareUpdate(participant: RtkMeetingParticipant, isEnabled: Bool) {
        
    }
    
    func onVideoUpdate(participant: RtkMeetingParticipant, isEnabled: Bool) {
        self.participantObserveVideoStateCompletion?(isEnabled,self)
        self.participantVideoStateCompletion?(isEnabled)
        self.participantVideoStateCompletion = nil
    }
}


public class RtkWaitListParticipantUpdateEventListener  {
    
    public var participantJoinedCompletion:((RtkMeetingParticipant)->Void)?
    public var participantRemovedCompletion:((RtkMeetingParticipant)->Void)?
    public var participantRequestAcceptedCompletion:((RtkMeetingParticipant)->Void)?
    public var participantRequestRejectCompletion:((RtkMeetingParticipant)->Void)?
    
    let rtkClient: RealtimeKitClient
    
    public init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
        self.rtkClient.addWaitlistEventListener(waitlistEventListener: self)
    }
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    
    public func clean() {
        removeRegisterListener()
    }
    public func acceptWaitingRequest(participant: RtkRemoteParticipant) {
        rtkClient.participants.acceptWaitingRoomRequest(id: participant.id)
    }
    
    public func rejectWaitingRequest(participant: RtkRemoteParticipant) {
        rtkClient.participants.rejectWaitingRoomRequest(id: participant.id)
    }
    
    private func removeRegisterListener() {
        self.rtkClient.removeWaitlistEventListener(waitlistEventListener: self)
    }
    
    deinit{
        print("RtkParticipantEventListener deallocing")
    }
}

extension RtkWaitListParticipantUpdateEventListener: RtkWaitlistEventListener {
    public func onWaitListParticipantAccepted(participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | onWaitListParticipantAccepted \(participant.name)")
        }
        DispatchQueue.main.async {
            self.participantRequestAcceptedCompletion?(participant)
        }
    }
    
    public func onWaitListParticipantRejected(participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | onWaitListParticipantRejected \(participant.name) \(participant.id) self \(participant.id)")
        }
        self.participantRequestRejectCompletion?(participant)
    }
    
    
    public func onWaitListParticipantClosed(participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | onWaitListParticipantClosed \(participant.name)")
        }
        self.participantRemovedCompletion?(participant)
    }
    
    public func onWaitListParticipantJoined(participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | onWaitListParticipantJoined \(participant.name)")
        }
        self.participantJoinedCompletion?(participant)
        
    }
}
