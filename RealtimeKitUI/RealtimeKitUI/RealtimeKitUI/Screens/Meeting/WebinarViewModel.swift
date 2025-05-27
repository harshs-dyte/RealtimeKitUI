//
//  WebinarViewModel.swift
//  RealtimeKitUI
//
//  Created by Shaunak Jagtap on 07/03/24.
//

import Foundation
import RealtimeKit


protocol RtkStageDelegate: AnyObject {
    func onPresentRequestAdded(participant: RtkRemoteParticipant)
    func onPresentRequestWithdrawn(participant: RtkRemoteParticipant)
}

class WebinarViewModel {
    var stageDelegate: RtkStageDelegate?
    private let rtkClient: RealtimeKitClient
    
    public init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
        rtkClient.addStageEventListener(stageEventListener: self)
    }
}

extension WebinarViewModel: RtkStageEventListener {
    func onNewStageAccessRequest(participant: RtkRemoteParticipant) {
        
    }
    
    func onPeerStageStatusUpdated(participant: RtkRemoteParticipant, oldStatus: RealtimeKit.StageStatus, newStatus: RealtimeKit.StageStatus) {
        
    }
    
    func onRemovedFromStage() {
        
    }
    
    func onStageAccessRequestAccepted() {
        
    }
    
    func onStageAccessRequestRejected() {
        
    }
    
    func onStageAccessRequestsUpdated(accessRequests: [RtkRemoteParticipant]) {
        
    }
    
    func onStageStatusUpdated(oldStatus: RealtimeKit.StageStatus, newStatus: RealtimeKit.StageStatus) {
        
    }
    
    func onPresentRequestWithdrawn(participant: RtkRemoteParticipant) {
        stageDelegate?.onPresentRequestWithdrawn(participant: participant)
    }
    
    func onPresentRequestAdded(participant: RtkRemoteParticipant) {
        stageDelegate?.onPresentRequestAdded(participant: participant)
    }
    
}
