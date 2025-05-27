//
//  ParticipantViewModel.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 15/02/23.
//

import RealtimeKit
import Foundation

public class WebinarParticipantViewControllerModel {
    
    let rtkClient: RealtimeKitClient
    let waitlistEventListener: RtkWaitListParticipantUpdateEventListener
    let rtkSelfListener: RtkEventSelfListener
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    private let searchControllerMinimumParticipant = 5
    
    required init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
        self.waitlistEventListener = RtkWaitListParticipantUpdateEventListener(rtkClient: rtkClient)
        self.rtkSelfListener = RtkEventSelfListener(rtkClient: rtkClient)
        
        rtkClient.addParticipantsEventListener(participantsEventListener: self)
        rtkClient.addStageEventListener(stageEventListener: self)
        addObserver()
    }
    
    private func addObserver() {
        self.waitlistEventListener.participantJoinedCompletion = { [weak self] partipant in
            guard let self = self, let completion = self.completion else {return}
            self.refresh(completion: completion)
        }
        self.waitlistEventListener.participantRemovedCompletion = { [weak self] partipant in
            guard let self = self, let completion = self.completion else {return}
            self.refresh(completion: completion)
        }
        self.waitlistEventListener.participantRequestAcceptedCompletion = { [weak self] partipant in
            guard let self = self, let completion = self.completion else {return}
            self.refresh(completion: completion)
        }
        self.waitlistEventListener.participantRequestRejectCompletion = { [weak self] partipant in
            guard let self = self, let completion = self.completion else {return}
            self.refresh(completion: completion)
        }
    }
    
    func acceptAll() {
        let userId = self.rtkClient.stage.accessRequests.map {  return $0.userId }
        self.rtkClient.stage.grantAccess(userIds: userId)
    }
    
    func acceptAllWaitingRoomRequest() {
        self.rtkClient.participants.acceptAllWaitingRoomRequests()
    }
    
    func rejectAll() {
        let userId = self.rtkClient.stage.accessRequests.map {  return $0.userId }
        self.rtkClient.stage.denyAccess(userIds: userId)
    }
    
    private func revokeInvitationToJoinStage(participant: RtkMeetingParticipant) {
        if let completion = self.completion {
            refresh(completion: completion)
        }
    }
    
    private func participantInviteToJoinStage(participant: RtkMeetingParticipant) {
        if let completion = self.completion {
            refresh(completion: completion)
        }
    }
    
    var dataSourceTableView = DataSourceStandard<BaseConfiguratorSection<CollectionTableConfigurator>>()
    
    private var completion: ((Bool)->Void)?
    
    public func load(completion:@escaping(Bool)->Void) {
        self.completion = completion
        refresh(completion: completion)
    }
    
    private func refresh(completion:@escaping(Bool)->Void) {
        self.dataSourceTableView.sections.removeAll()
        let minimumParticpantCountToShowSearchBar = searchControllerMinimumParticipant
        
        let sectionZero = self.getWaitlistSection()
        let sectionOne = self.getJoinStageRequestSection()
        let sectionTwo = self.getOnStageSection(minimumParticpantCountToShowSearchBar: minimumParticpantCountToShowSearchBar)
        let sectionThree = self.getInCallViewers(minimumParticpantCountToShowSearchBar: minimumParticpantCountToShowSearchBar)
        
        self.dataSourceTableView.sections.append(sectionZero)
        self.dataSourceTableView.sections.append(sectionOne)
        self.dataSourceTableView.sections.append(sectionTwo)
        self.dataSourceTableView.sections.append(sectionThree)
        completion(true)
    }
    
    func clean() {
        rtkClient.removeParticipantsEventListener(participantsEventListener: self)
        rtkClient.removeStageEventListener(stageEventListener: self)
        waitlistEventListener.clean()
    }
    
    deinit {
        
    }
}

extension WebinarParticipantViewControllerModel {
    
    private func getWaitlistSection() -> BaseConfiguratorSection<CollectionTableConfigurator> {
        let sectionOne = BaseConfiguratorSection<CollectionTableConfigurator>()
        let waitListedParticipants = self.rtkClient.participants.waitlisted
        if waitListedParticipants.count > 0 {
            var participantCount = ""
            if waitListedParticipants.count > 1 {
                participantCount = " (\(waitListedParticipants.count))"
            }
            sectionOne.insert(TableItemConfigurator<TitleTableViewCell,TitleTableViewCellModel>(model:TitleTableViewCellModel(title: "Waiting\(participantCount)")))
            
            for (index, participant) in waitListedParticipants.enumerated() {
                var image: RtkImage? = nil
                if let imageUrl = participant.picture, let url = URL(string: imageUrl) {
                    image = RtkImage(url: url)
                }
                var showBottomSeparator = true
                if index == waitListedParticipants.count - 1 {
                    showBottomSeparator = false
                }
                sectionOne.insert(TableItemConfigurator<ParticipantWaitingTableViewCell,ParticipantWaitingTableViewCellModel>(model:ParticipantWaitingTableViewCellModel(title: participant.name, image: image, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participant: participant)))
            }
            
            if waitListedParticipants.count > 1 {
                sectionOne.insert(TableItemConfigurator<AcceptButtonWaitingTableViewCell,ButtonTableViewCellModel>(model:ButtonTableViewCellModel(buttonTitle: "Accept All")))
            }
        }
        
        return sectionOne
    }
    
    private func getJoinStageRequestSection() -> BaseConfiguratorSection<CollectionTableConfigurator> {
        let sectionOne = BaseConfiguratorSection<CollectionTableConfigurator>()
        let waitListedParticipants = self.rtkClient.stage.accessRequests
        if waitListedParticipants.count > 0 {
            var participantCount = ""
            if waitListedParticipants.count > 1 {
                participantCount = " (\(waitListedParticipants.count))"
            }
            sectionOne.insert(TableItemConfigurator<TitleTableViewCell,TitleTableViewCellModel>(model:TitleTableViewCellModel(title: "Join stage requests\(participantCount)")))
            
            for (index, participant) in waitListedParticipants.enumerated() {
                let image: RtkImage? = nil
                var showBottomSeparator = true
                if index == waitListedParticipants.count - 1 {
                    showBottomSeparator = false
                }
                
                sectionOne.insert(TableItemConfigurator<OnStageWaitingRequestTableViewCell,OnStageParticipantWaitingRequestTableViewCellModel>(model:OnStageParticipantWaitingRequestTableViewCellModel(title: participant.name, image: image, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participant: participant)))
            }
            
            if waitListedParticipants.count > 1 {
                sectionOne.insert(TableItemConfigurator<AcceptButtonJoinStageRequestTableViewCell,ButtonTableViewCellModel>(model:ButtonTableViewCellModel(buttonTitle: "Accept All")))
                sectionOne.insert(TableItemConfigurator<RejectButtonJoinStageRequestTableViewCell,ButtonTableViewCellModel>(model:ButtonTableViewCellModel(buttonTitle: "Reject All")))
            }
        }
        return sectionOne
    }
    
    private func getOnStageSection(minimumParticpantCountToShowSearchBar: Int) ->  BaseConfiguratorSection<CollectionTableConfigurator> {
        let arrJoinedParticipants = self.rtkClient.participants.joined
        let selfIsOnStage = self.rtkClient.localUser.stageStatus==StageStatus.onStage
        
        var onStageRemoteParticipants = [RtkRemoteParticipant]()
        
        for participant in arrJoinedParticipants {
            if participant.stageStatus == StageStatus.onStage {
                onStageRemoteParticipants.append(participant)
            }
        }
        let sectionTwo =  BaseConfiguratorSection<CollectionTableConfigurator>()
        
        var onStageParticipants = [RtkMeetingParticipant]()
        if(selfIsOnStage){
            onStageParticipants.append(self.rtkClient.localUser)
        }
        
        onStageRemoteParticipants.forEach { onStageParticipants.append($0) }
        
        if onStageParticipants.count > 0 {
            var participantCount = ""
            if onStageParticipants.count > 1 {
                participantCount = " (\(onStageParticipants.count))"
            }
            sectionTwo.insert(TableItemConfigurator<TitleTableViewCell,TitleTableViewCellModel>(model:TitleTableViewCellModel(title: "On stage\(participantCount)")))
            
            if onStageParticipants.count > minimumParticpantCountToShowSearchBar {
                sectionTwo.insert(TableItemConfigurator<SearchTableViewCell,SearchTableViewCellModel>(model:SearchTableViewCellModel(placeHolder: "Search Participant")))
            }
            
            for (index, participant) in onStageParticipants.enumerated() {
                var showBottomSeparator = true
                if index == onStageParticipants.count - 1 {
                    showBottomSeparator = false
                }
                func showMoreButton() -> Bool {
                    var canShow = false
                    let hostPermission = self.rtkClient.localUser.permissions.host
                    
                    if hostPermission.canPinParticipant && participant.isPinned == false {
                        canShow = true
                    }
                    
                    if hostPermission.canMuteAudio && participant.audioEnabled == true {
                        canShow = true
                    }
                    
                    if hostPermission.canMuteVideo && participant.videoEnabled == true {
                        canShow = true
                    }
                    
                    if hostPermission.canKickParticipant {
                        canShow = true
                    }
                    
                    return canShow
                }
                
                var name = participant.name
                if participant.userId == rtkClient.localUser.userId {
                    name = "\(participant.name) (you)"
                }
                var image: RtkImage? = nil
                if let imageUrl = participant.picture, let url = URL(string: imageUrl) {
                    image = RtkImage(url: url)
                }
                
                
                sectionTwo.insert(TableItemSearchableConfigurator<ParticipantInCallTableViewCell,ParticipantInCallTableViewCellModel>(model:ParticipantInCallTableViewCellModel(image: image, title: name, showBottomSeparator: showBottomSeparator, showTopSeparator: false, participantUpdateEventListener: RtkParticipantUpdateEventListener(participant: participant), showMoreButton: showMoreButton())))
            }
        }
        return sectionTwo
    }
    
    private func getInCallViewers(minimumParticpantCountToShowSearchBar: Int) ->  BaseConfiguratorSection<CollectionTableConfigurator> {
        var viewerRemoteParticipants = [RtkRemoteParticipant]()
        viewerRemoteParticipants.append(contentsOf: self.rtkClient.stage.viewers)
        let shouldShowSelfInViewers = self.rtkClient.localUser.stageStatus != StageStatus.onStage
        let sectionTwo =  BaseConfiguratorSection<CollectionTableConfigurator>()
        
        var allViewerParticipants = [RtkMeetingParticipant]()
        if(shouldShowSelfInViewers){
            allViewerParticipants.append(self.rtkClient.localUser)
        }
        
        viewerRemoteParticipants.forEach { allViewerParticipants.append($0) }
        
        if allViewerParticipants.count > 0 {
            var participantCount = ""
            if allViewerParticipants.count > 1 {
                participantCount = " (\(allViewerParticipants.count))"
            }
            sectionTwo.insert(TableItemConfigurator<TitleTableViewCell,TitleTableViewCellModel>(model:TitleTableViewCellModel(title: "Viewers\(participantCount)")))
            
            if allViewerParticipants.count > minimumParticpantCountToShowSearchBar {
                sectionTwo.insert(TableItemConfigurator<SearchTableViewCell,SearchTableViewCellModel>(model:SearchTableViewCellModel(placeHolder: "Search Viewers")))
                
            }
            
            for (index, participant) in allViewerParticipants.enumerated() {
                var showBottomSeparator = true
                if index == allViewerParticipants.count - 1 {
                    showBottomSeparator = false
                }
                
                func showMoreButton() -> Bool {
                    var canShow = false
                    let hostPermission = self.rtkClient.localUser.permissions.host
                    
                    if self.rtkClient.localUser.canDoParticipantHostControls() || hostPermission.canAcceptRequests == true {
                        canShow = true
                    }
                    return canShow
                }
                
                var name = participant.name
                if participant.userId == rtkClient.localUser.userId {
                    name = "\(participant.name) (you)"
                }
                var image: RtkImage? = nil
                if let imageUrl = participant.picture, let url = URL(string: imageUrl) {
                    image = RtkImage(url: url)
                }
                sectionTwo.insert(TableItemSearchableConfigurator<WebinarViewersTableViewCell,WebinarViewersTableViewCellModel>(model:WebinarViewersTableViewCellModel(image: image, title: name, showBottomSeparator: showBottomSeparator, showTopSeparator: false,  participantUpdateEventListener: RtkParticipantUpdateEventListener(participant: participant), showMoreButton: showMoreButton())))
            }
        }
        return sectionTwo
    }
}

extension WebinarParticipantViewControllerModel: RtkParticipantsEventListener {
    
    public func onActiveParticipantsChanged(active: [RtkRemoteParticipant]) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    
    public func onParticipantJoin(participant: RtkRemoteParticipant) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onParticipantLeave(participant: RtkRemoteParticipant) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onActiveSpeakerChanged(participant: RtkRemoteParticipant?) {
        
    }
    
    public func onAllParticipantsUpdated(allParticipants: [RtkParticipant]) {
        
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
    
    public func onUpdate(participants: RtkParticipants) {
        
    }
    
    public func onVideoUpdate(participant: RtkRemoteParticipant, isEnabled: Bool) {
        
    }
}

extension WebinarParticipantViewControllerModel: RtkStageEventListener {
    public func onNewStageAccessRequest(participant: RtkRemoteParticipant) {
        
    }
    
    public func onPeerStageStatusUpdated(participant: RtkRemoteParticipant, oldStatus: RealtimeKit.StageStatus, newStatus: RealtimeKit.StageStatus) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }

    }
    
    public func onStageAccessRequestRejected() {

    }
    
    public func onStageAccessRequestsUpdated(accessRequests: [RtkRemoteParticipant]) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onStageStatusUpdated(oldStatus: RealtimeKit.StageStatus, newStatus: RealtimeKit.StageStatus) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
        
    public func onStageAccessRequestAccepted() {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onRemovedFromStage() {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    public func onStageRequestsUpdated(accessRequests: [RtkRemoteParticipant]) {
        if let completion = self.completion {
            self.refresh(completion: completion)
        }
    }
    
    
}
