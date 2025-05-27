//
//  RtkVideoView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 07/02/23.
//

import RealtimeKit
import UIKit

public class RtkVideoView : UIView {
    
    private var renderView: UIView?// Video View returned from MobileCore SDK
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    private var participant: RtkMeetingParticipant
    private var onRendered: (()-> Void)?
    private let showSelfPreview: Bool
    private let showScreenShareView: Bool
    
    public init(participant: RtkMeetingParticipant, showSelfPreview: Bool = false, showScreenShare: Bool = false) {
        self.participant = participant
        self.showSelfPreview = showSelfPreview
        self.showScreenShareView = showScreenShare
        super.init(frame: .zero)
        if isDebugModeOn {
            print("Debug RtkUIKit | RtkVideoView is being Created")
        }
        set(participant: participant)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(participant: RtkMeetingParticipant) {
        if isDebugModeOn {
            print("Debug RtkUIKit | RtkVideoView set(participant:) is called")
        }
        self.participant.removeParticipantUpdateListener(participantUpdateListener: self)
        self.participant = participant
        self.participant.addParticipantUpdateListener(participantUpdateListener: self)
        refreshView()
    }
    
    func refreshView() {
        if isDebugModeOn {
            print("Debug RtkUIKit | RtkVideoView refreshView() is called")
        }
        self.showVideoView(participant: self.participant)
    }
    
    public func prepareForReuse() {
        if self.renderView?.superview == self {
            //As Core SDK provides cached renderView, So If someone ask for the view SDK will return the same view and Hence self.renderView.superView is changed , But self.renderView is still pointing to same cached SDK View.
            self.renderView?.removeFromSuperview()
        }
        self.renderView = nil
    }
    
    public func clean() {
        self.participant.removeParticipantUpdateListener(participantUpdateListener: self)
        
        prepareForReuse()
    }
    
    public override func removeFromSuperview() {
        if isDebugModeOn {
            print("Debug RtkUIKit | Removing Video View by calling removeFromSuperview()")
        }
        super.removeFromSuperview()
        prepareForReuse()
    }
    
    deinit {
        print("Debug RtkUIKit | RtkVideoView deinit is calling")
    }
}

extension RtkVideoView {
    
    private func showVideoView(participant: RtkMeetingParticipant) {
        if  participant.screenShareEnabled && self.showScreenShareView == true {
            let view =  participant.getScreenShareVideoView()
            
            if let nonNullableView = view {
                if isDebugModeOn {
                    print("Debug RtkUIKit | VideoView Screen share view \(nonNullableView.bounds) \(nonNullableView.frame)")
                }
                setRenderView(view: nonNullableView)
            }
            self.isHidden = false
        } else if let participant = participant as? RtkSelfParticipant, showSelfPreview == true ,participant.videoEnabled == true {
            if let selfVideoView = participant.getSelfPreview() {
                if isDebugModeOn {
                    print("Debug RtkUIKit | Participant \(participant.name) is RtkSelfParticipant videoView bounds \(selfVideoView.bounds) frame \(selfVideoView.frame)")
                }
                setRenderView(view: selfVideoView)
            }
            self.isHidden = false
            
        } else if let view = participant.getVideoView(), participant.videoEnabled == true {
            if isDebugModeOn {
                print("Debug RtkUIKit | Participant \(participant.name) videoView bounds \(view.bounds) frame \(view.frame)")
            }
            setRenderView(view: view)
            self.isHidden = false
        } else {
            if isDebugModeOn {
                print("Debug RtkUIKit | VideoView participant video is NIL: \(String(describing: participant.getVideoView()))")
            }
            self.isHidden = true
        }
    }
    
    private func setRenderView(view: UIView) {
        self.renderView?.removeFromSuperview()
        self.renderView = view
        self.addSubview(view)
        view.set(.fillSuperView(self))
        if isDebugModeOn {
            print("Debug RtkUIKit | Rendered VideoView \(view) Parent View :\(self) superView: \(String(describing: self.superview))")
        }
        self.onRendered?()
    }
}

extension RtkVideoView: RtkParticipantUpdateListener {
    public func onAudioUpdate(participant: RtkMeetingParticipant, isEnabled: Bool) {
        
    }
    
    public func onPinned(participant: RtkMeetingParticipant) {
        
    }
    
    public func onScreenShareUpdate(participant: RtkMeetingParticipant, isEnabled: Bool) {
        
    }
    
    public func onUnpinned(participant: RtkMeetingParticipant) {
        
    }
    
    public func onUpdate(participant: RtkMeetingParticipant) {
        
    }
    
    public func onVideoUpdate(participant: RtkMeetingParticipant, isEnabled: Bool) {
        if isDebugModeOn {
            print("Debug RtkUIKit | Delegate VideoView onVideoUpdate(participant Name \(participant.name)")
        }
        self.showVideoView(participant: self.participant)
    }
}
