//
//  MeetingViewModel.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 24/12/22.
//

import RealtimeKit
import UIKit

protocol MeetingViewModelDelegate: AnyObject {
    func refreshMeetingGrid(forRotation: Bool)
    func refreshPluginsScreenShareView()
    func activeSpeakerChanged(participant: RtkMeetingParticipant)
    func pinnedChanged(participant: RtkMeetingParticipant)
    func activeSpeakerRemoved()
    func participantJoined(participant: RtkMeetingParticipant)
    func participantLeft(participant: RtkMeetingParticipant)
    func newPollAdded(createdBy: String)
}
extension MeetingViewModelDelegate {
    func refreshMeetingGrid() {
        self.refreshMeetingGrid(forRotation: false)
    }
}

public enum RtkNotificationType {
    case Chat(message: String)
    case Poll
    case Joined
    case Leave
}

public protocol RtkNotificationDelegate: AnyObject {
    func didReceiveNotification(type: RtkNotificationType)
    func clearChatNotification()
}

public class GridCellViewModel {
    public var nameInitials: String
    public var fullName: String
    public var participant: RtkMeetingParticipant
    public  init(participant: RtkMeetingParticipant) {
        self.participant = participant
        self.fullName = participant.name
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: participant.name) {
            formatter.style = .abbreviated
            self.nameInitials = formatter.string(from: components)
        }else {
            if let first = fullName.first {
                self.nameInitials = "\(first)"
            }else {
                self.nameInitials = ""
            }
        }
        
    }
}


public class ScreenShareViewModel {
    public var arrScreenShareParticipants = [ParticipantsShareControl]()
    private var dict = [String : Int]()
    public var selectedIndex: (UInt, String)?
    private let selfActiveTab: ActiveTab?
    public init(selfActiveTab: ActiveTab?) {
        self.selfActiveTab = selfActiveTab
    }
    
    public func refresh(plugins: [RtkPlugin], selectedPlugin: RtkPlugin?) {
        for plugin in plugins {
            if dict[plugin.id] == nil {
                arrScreenShareParticipants.append(PluginButtonModel(plugin: plugin))
                dict[plugin.id] = arrScreenShareParticipants.count - 1
            }
        }
        selectPlugin(oldId: selectedPlugin?.id)
    }
    
    public func removed(plugin: RtkPlugin) {
        removePlugin(id: plugin.id)
        selectPlugin(oldId: selectedIndex?.1)
    }
    
    private func removePlugin(id: String) {
        if let index =  arrScreenShareParticipants.firstIndex(where: { item in
            return item.id == id
        }) {
            arrScreenShareParticipants.remove(at: index)
            dict[id] = nil
        }
    }
    
    public func refresh(participants: [RtkMeetingParticipant]) {
        for participant in participants {
            if dict[participant.id] == nil {
                arrScreenShareParticipants.append(ScreenShareModel(participant: participant))
                dict[participant.id] = arrScreenShareParticipants.count - 1
            }
        }
        
        func getUseLessIds() -> [String] {
            var result = [String] ()
            for participant in arrScreenShareParticipants {
                if let screenShare = participant as? ScreenShareModel {
                    // check only for ScreenShare which are now not a part of active participants are use less
                    var isIdExist = false
                    for participant in participants {
                        if screenShare.id == participant.id {
                            isIdExist = true
                            break
                        }
                    }
                    if isIdExist == false {
                        result.append(screenShare.id)
                    }
                }
            }
            return result
        }
        
        let useLessId = getUseLessIds()
        for id in useLessId {
            removePlugin(id: id)
        }
        selectPlugin(oldId: selectedIndex?.1)
    }
    
    private func selectPlugin(oldId: String?) {
        let oldId = oldId
        
        if let selfActiveTab = self.selfActiveTab , selectedIndex == nil {
            var index: UInt = 0
            for model in arrScreenShareParticipants {
                if model.id == selfActiveTab.id {
                    selectedIndex = (index, model.id)
                    return;
                }
                index += 1
            }
        }
        
        var index: UInt = 0
        for model in arrScreenShareParticipants {
            if model.id == oldId {
                selectedIndex = (index, model.id)
                return;
            }
            index += 1
        }
        
        
        if arrScreenShareParticipants.count >= 1 {
            selectedIndex = (0, arrScreenShareParticipants[0].id)
        }else {
            selectedIndex = nil
        }
    }
}

public protocol ParticipantsShareControl {
    var image: String? {get}
    var name: String {get}
    var id: String {get}
}

public protocol PluginsButtonModelProtocol: ParticipantsShareControl {
    var plugin: RtkPlugin {get}
}

public protocol ScreenSharePluginsProtocol: ParticipantsShareControl {
    var participant: RtkMeetingParticipant {get}
}


public class PluginButtonModel: PluginsButtonModelProtocol {
    public let image: String?
    public let name: String
    public let id: String
    public let plugin: RtkPlugin
    
    public init(plugin: RtkPlugin) {
        self.plugin = plugin
        self.id = plugin.id
        self.image = plugin.picture
        self.name = plugin.name
    }
}

public class ScreenShareModel : ScreenSharePluginsProtocol {
    public let image: String?
    public let name: String
    public let id: String
    public let nameInitials: String
    public let participant: RtkMeetingParticipant
    public init(participant: RtkMeetingParticipant) {
        self.participant = participant
        self.name = participant.name
        self.image = participant.picture
        self.id = participant.id
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: participant.name) {
            formatter.style = .abbreviated
            self.nameInitials = formatter.string(from: components)
        }else {
            if let first = name.first {
                self.nameInitials = "\(first)"
            }else {
                self.nameInitials = ""
            }
        }
    }
}

var notificationDelegate: RtkNotificationDelegate?


public final class MeetingViewModel {
    
    private let rtkClient: RealtimeKitClient
    let selfEventListener: RtkEventSelfListener
    let maxParticipantOnpage: UInt
    let waitlistEventListener: RtkWaitListParticipantUpdateEventListener
    
    weak var delegate: MeetingViewModelDelegate?
    var chatDelegate: ChatDelegate?
    var currentlyShowingItemOnSinglePage: UInt
    var arrGridParticipants = [GridCellViewModel]()
    let screenShareViewModel: ScreenShareViewModel
    var shouldShowShareScreen = false
    let rtkNotification = RtkNotification()
    
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    
    public init(rtkClient: RealtimeKitClient) {
        self.rtkClient = rtkClient
        self.screenShareViewModel = ScreenShareViewModel(selfActiveTab: rtkClient.meta.selfActiveTab)
        self.waitlistEventListener = RtkWaitListParticipantUpdateEventListener(rtkClient: rtkClient)
        self.selfEventListener = RtkEventSelfListener(rtkClient: rtkClient)
        self.maxParticipantOnpage = 9
        self.currentlyShowingItemOnSinglePage = maxParticipantOnpage
        initialise()
    }
    
    public func clearChatNotification() {
        notificationDelegate?.clearChatNotification()
    }
    
    func trackOnGoingState() {
        
        if let participant = rtkClient.participants.pinned {
            self.delegate?.pinnedChanged(participant: participant)
        }
        
        if rtkClient.plugins.active.count >= 1 {
            screenShareViewModel.refresh(plugins: self.rtkClient.plugins.active, selectedPlugin: nil)
            
            if self.rtkClient.participants.currentPageNumber == 0 {
                self.delegate?.refreshPluginsScreenShareView()
            }
        }
        
        if rtkClient.participants.screenShares.count > 0 {
            updateScreenShareStatus()
        }
    }
    
    func onReconnect() {
        if rtkClient.participants.screenShares.count > 0 {
            self.updateScreenShareStatus()
        }
        if rtkClient.plugins.active.count >= 1 {
            screenShareViewModel.refresh(plugins: self.rtkClient.plugins.active, selectedPlugin: nil)
        }
        self.delegate?.refreshMeetingGrid()
    }
    
    func initialise() {
        rtkClient.addSelfEventListener(selfEventListener: self)
        rtkClient.addParticipantsEventListener(participantsEventListener: self)
        rtkClient.addPluginsEventListener(pluginsEventListener: self)
        self.rtkClient.addPollsEventListener(pollsEventListener: self)
        rtkClient.addStageEventListener(stageEventListener: self)
    }
    
    public func clean() {
        selfEventListener.clean()
        rtkClient.removeSelfEventListener(selfEventListener: self)
        rtkClient.removeParticipantsEventListener(participantsEventListener: self)
        rtkClient.removePluginsEventListener(pluginsEventListener: self)
        self.rtkClient.removePollsEventListener(pollsEventListener: self)
        rtkClient.removeSelfEventListener(selfEventListener: self)
    }
    
}

extension MeetingViewModel: RtkPollsEventListener {
    public func onPollUpdate(poll: Poll) {
        
    }
    
    public func onNewPoll(poll: Poll) {
        delegate?.newPollAdded(createdBy: poll.createdBy)
        notificationDelegate?.didReceiveNotification(type: .Poll)
    }
    
    public func onPollUpdates(pollItems: [Poll]) {
        
    }
    
    
}

extension MeetingViewModel {
    
    public func refreshPinnedParticipants() {
        refreshActiveParticipants(pageItemCount: self.currentlyShowingItemOnSinglePage)
    }
    
    public func refreshActiveParticipants(pageItemCount: UInt = 0) {
        //pageItemCount tell on first page how many tiles needs to be shown to user
        self.updateActiveGridParticipants(pageItemCount: pageItemCount)
        self.delegate?.refreshMeetingGrid()
    }
    
    private func updateActiveGridParticipants(pageItemCount: UInt = 0) {
        self.currentlyShowingItemOnSinglePage = pageItemCount
        self.arrGridParticipants = getParticipant(pageItemCount: pageItemCount)
        if isDebugModeOn {
            print("Debug RtkUIKit | Current Visible Items \(arrGridParticipants.count)")
        }
    }
    
    func pinOrPluginScreenShareModeIsActive() -> Bool {
        return pinModeIsActive || pluginScreenShareModeIsActive()
    }
    
    private var isAnyUserPinned : Bool {
        get {
            (self.rtkClient.participants.pinned != nil || self.rtkClient.localUser.isPinned) ? true : false
        }
    }
    
    var pinModeIsActive : Bool {
        get {
            self.rtkClient.participants.currentPageNumber == 0 && isAnyUserPinned
        }
    }
    
    func pluginScreenShareModeIsActive() -> Bool {
        if self.rtkClient.participants.currentPageNumber == 0 {
            let isScreenShareActive = self.rtkClient.participants.screenShares.count > 0 || self.rtkClient.localUser.screenShareEnabled
            if isScreenShareActive || rtkClient.plugins.active.count > 0 {
                return true
            }
            return false
        }
        return false
    }
    
    private func getParticipant(pageItemCount: UInt = 0) -> [GridCellViewModel] {
        let pluginScreenShareIsActive = pluginScreenShareModeIsActive()
        
        let showAddSelfToActive = (self.rtkClient.participants.currentPageNumber == 0 &&
                                   self.rtkClient.localUser.stageStatus == .onStage)
        let activeParticipants = if showAddSelfToActive {
            self.rtkClient.participants.active + [self.rtkClient.localUser]
        } else {
            self.rtkClient.participants.active
        }
        
        if isDebugModeOn {
            print("Debug RtkUIKit | Active participant count \(activeParticipants.count)")
        }
        
        let rowCount = (pageItemCount == 0 || pageItemCount >= activeParticipants.count) ? UInt(activeParticipants.count) : min(UInt(activeParticipants.count), pageItemCount)
        if isDebugModeOn {
            print("Debug RtkUIKit | visibleItemCount \(pageItemCount) MTVM RowCount \(rowCount)")
        }
        var itemCount = 0
        var result =  [GridCellViewModel]()
        for participant in activeParticipants {
            if itemCount < rowCount {
                if pinOrPluginScreenShareModeIsActive() {
                    if pluginScreenShareIsActive {
                        // we will show plugin view and if there is pinned participant it should be shown at 0 index inside grid
                        if participant.isPinned {
                            result.insert(GridCellViewModel(participant: participant), at: 0)
                        }else {
                            result.append(GridCellViewModel(participant: participant))
                        }
                    } else if pinModeIsActive {
                        // We have to remove pinned Participant from the Grid.
                        if participant.isPinned == false {
                            // we are adding only non pinned participant
                            result.append(GridCellViewModel(participant: participant))
                        }
                    }
                } else {
                    result.append(GridCellViewModel(participant: participant))
                }
            } else {
                break;
            }
            itemCount += 1
        }
        return result
    }
}

extension MeetingViewModel: RtkParticipantsEventListener {
    public func onAllParticipantsUpdated(allParticipants: [RtkParticipant]) {
        
    }
    
    public func onAudioUpdate(participant: RtkRemoteParticipant,  isEnabled: Bool) {
        
    }
    
    public func onNewBroadcastMessage(type: String, payload: [String : Any]) {
        
    }
    
    public func onUpdate(participants: RtkParticipants) {
        
    }
    
    public func onVideoUpdate(participant: RtkRemoteParticipant,  isEnabled: Bool) {
    }
    
    public func onScreenShareUpdate(participant: RtkRemoteParticipant,  isEnabled: Bool) {
        if isEnabled {
            onScreenShareStarted(participant: participant)
        } else {
            onScreenShareEnded(participant: participant)
        }
    }
    
    public func onScreenShareEnded(participant_ participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit |onScreenShareEnded Participant Id \(participant.userId)")
        }
    }
    
    public func onScreenShareStarted(participant_ participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | onScreenShareStarted Participant Id \(participant.userId)")
        }
    }
    
    public func onScreenShareEnded(participant: RtkMeetingParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | onScreenShareEnded Participant Id \(participant.userId)")
        }
        updateScreenShareStatus()
    }
    
    public func onScreenShareStarted(participant: RtkMeetingParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | onScreenShareStarted Participant Id \(participant.userId)")
        }
        updateScreenShareStatus()
    }
    
    public func onParticipantLeave(participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | onParticipantLeave Participant Id \(participant.userId)")
        }
        delegate?.participantLeft(participant: participant)
        notificationDelegate?.didReceiveNotification(type: .Leave)
    }
    
    public func onActiveParticipantsChanged(active: [RtkRemoteParticipant]) {
        if isDebugModeOn {
            print("Debug RtkUIKit | onActiveParticipantsChanged")
        }
        
        self.refreshActiveParticipants(pageItemCount: self.currentlyShowingItemOnSinglePage)
    }
    
    public func onActiveSpeakerChanged(participant: RtkRemoteParticipant?) {
        if let participant = participant {
            self.delegate?.activeSpeakerChanged(participant: participant)
        }
    }
    public  func onNoActiveSpeaker() {
        self.delegate?.activeSpeakerRemoved()
        
    }
    
    public func onParticipantJoin(participant: RtkRemoteParticipant) {
        delegate?.participantJoined(participant: participant)
        notificationDelegate?.didReceiveNotification(type: .Joined)
        if isDebugModeOn {
            print("Debug RtkUIKit | Delegate onParticipantJoin \(participant.audioEnabled) \(participant.name) totalCount \(self.rtkClient.participants.joined) participants")
        }
    }
    
    public func onParticipantPinned(participant: RtkRemoteParticipant) {
        
        if isDebugModeOn {
            print("Debug RtkUIKit | Pinned changed Participant Id \(participant.userId)")
        }
        refreshPinnedParticipants()
        self.delegate?.pinnedChanged(participant: participant)
    }
    
    public func onParticipantUnpinned(participant: RtkRemoteParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | Pinned removed Participant Id \(participant.userId)")
        }
        refreshPinnedParticipants()
    }
    
    private func updateScreenShareStatus() {
        if isAnyUserPinned {
            self.refreshPinnedParticipants()
        }
        
        var screenshareParticipants : [RtkMeetingParticipant] = self.rtkClient.participants.screenShares
        
        let isSelfScreenshare = self.rtkClient.localUser.screenShareEnabled
        
        if isSelfScreenshare {
            screenshareParticipants.append(self.rtkClient.localUser)
        }
        
        screenShareViewModel.refresh(participants: screenshareParticipants)
        self.shouldShowShareScreen = screenShareViewModel.arrScreenShareParticipants.count > 0 ? true : false
        if self.rtkClient.participants.currentPageNumber == 0 {
            self.delegate?.refreshPluginsScreenShareView()
        }
    }
}

extension MeetingViewModel: RtkPluginsEventListener {
    public func onPluginMessage(plugin: RtkPlugin, eventName: String, data: Any?) {
        
    }
    
    
    public func onPluginActivated(plugin: RtkPlugin) {
        if isDebugModeOn {
            print("Debug RtkUIKit | Delegate onPluginActivated(")
        }
        if isAnyUserPinned {
            self.refreshPinnedParticipants()
        }
        screenShareViewModel.refresh(plugins: self.rtkClient.plugins.active, selectedPlugin: plugin)
        if self.rtkClient.participants.currentPageNumber == 0 {
            self.delegate?.refreshPluginsScreenShareView()
        }
    }
    
    public func onPluginDeactivated(plugin: RtkPlugin) {
        if isDebugModeOn {
            print("Debug RtkUIKit | Delegate onPluginDeactivated(")
        }
        if isAnyUserPinned {
            self.refreshPinnedParticipants()
        }
        screenShareViewModel.removed(plugin: plugin)
        if self.rtkClient.participants.currentPageNumber == 0 {
            self.delegate?.refreshPluginsScreenShareView()
        }
    }
    
    public func onPluginFileRequest(plugin: RtkPlugin) {
        
    }
    
    public func onPluginMessage(message: [String : Kotlinx_serialization_jsonJsonElement]) {
        if isDebugModeOn {
            print("Debug RtkUIKit | Delegate onPluginMessage(")
        }
    }
    
}

extension MeetingViewModel : RtkSelfEventListener {
    public func onAudioDevicesUpdated() {
        
    }
    
    public func onAudioUpdate(isEnabled: Bool) {
        
    }
    
    public func onMeetingRoomJoinedWithoutCameraPermission() {
        
    }
    
    public func onMeetingRoomJoinedWithoutMicPermission() {
        
    }
    
    public func onPermissionsUpdated(permission: SelfPermissions) {
        
    }
    
    public func onPinned() {
        if isDebugModeOn {
            print("Debug RtkUIKit | Pinned changed Participant Id \(self.rtkClient.localUser.id)")
        }
        refreshPinnedParticipants()
        self.delegate?.pinnedChanged(participant: self.rtkClient.localUser)
    }
    
    public func onRemovedFromMeeting() {
        
    }
    
    public func onScreenShareStartFailed(reason: String) {
        
    }
    
    public func onScreenShareUpdate(isEnabled: Bool) {
        if isEnabled {
            onScreenShareStarted(participant: self.rtkClient.localUser)
        } else {
            onScreenShareEnded(participant: self.rtkClient.localUser)
        }
    }
    
    public func onUnpinned() {
        if isDebugModeOn {
            print("Debug RtkUIKit | Pinned removed self Participant Id \(self.rtkClient.localUser.id)")
        }
        refreshPinnedParticipants()

    }
    
    public func onUpdate(participant: RtkSelfParticipant) {
        
    }
    
    public func onVideoDeviceChanged(videoDevice: VideoDevice) {
        
    }
    
    public func onVideoUpdate(isEnabled: Bool) {
        
    }
    
    public func onWaitListStatusUpdate(waitListStatus: RealtimeKit.WaitListStatus) {
        
    }
    
    
}

extension MeetingViewModel : RtkStageEventListener {
    public func onNewStageAccessRequest(participant: RtkRemoteParticipant) {
        
    }
    
    public func onPeerStageStatusUpdated(participant: RtkRemoteParticipant, oldStatus: RealtimeKit.StageStatus, newStatus: RealtimeKit.StageStatus) {
        
    }
    
    public func onRemovedFromStage() {
        
    }
    
    public func onStageAccessRequestAccepted() {
        
    }
    
    public func onStageAccessRequestRejected() {
        
    }
    
    public func onStageAccessRequestsUpdated(accessRequests: [RtkRemoteParticipant]) {
        
    }
    
    public func onStageStatusUpdated(oldStatus: RealtimeKit.StageStatus, newStatus: RealtimeKit.StageStatus) {
        if newStatus == .onStage || newStatus == .offStage {
            if isDebugModeOn {
                print("Debug RtkUIKit | onStageStatusUpdated")
            }
            
            self.refreshActiveParticipants(pageItemCount: self.currentlyShowingItemOnSinglePage)
        }
    }
}

