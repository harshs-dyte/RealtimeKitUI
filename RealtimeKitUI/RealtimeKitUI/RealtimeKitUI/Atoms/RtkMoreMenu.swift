//
//  RtkMoreMenu.swift
//  RealtimeKitUI
//
//  Created by Shaunak Jagtap on 21/01/23.
//

import UIKit
import RealtimeKit

public enum MenuType {
    case shareMeetingUrl
    case poll(notificationMessage:String)
    case chat(notificationMessage:String)
    case plugins
    case settings
    case particpants(notificationMessage:String)
    case recordingStart
    case recordingStop
    case muteAllAudio
    case muteAllVideo
    case muteAudio
    case muteVideo
    case pin
    case unPin
    case allowToJoinStage
    case denyToJoinStage
    case removeFromStage
    case startScreenShare
    case stopScreenShare
    case kick
    case files
    case images
    case cancel
}

extension MenuType {
    func getAccessIndentifier() -> String {
        switch self {
        case .shareMeetingUrl:
            return "MoreMenu_Option_ShareMeetingUrl"
            
        case .poll(notificationMessage: _):
            return "MoreMenu_Option_Poll"

        case .chat(notificationMessage: _):
            return "MoreMenu_Option_Chat"

        case .plugins:
            return "MoreMenu_Option_Plugins"
        
        case .startScreenShare:
            return "MoreMenu_Option_Start_Screenshare"
        case .stopScreenShare:
            return "MoreMenu_Option_Stop_Screenshare"
            
        case .settings:
            return "MoreMenu_Option_Settings"

        case .particpants(notificationMessage: _):
            return "MoreMenu_Option_Participants"

        case .recordingStart:
            return "MoreMenu_Option_StartRecording"

        case .recordingStop:
            return "MoreMenu_Option_StopRecording"

        case .muteAllAudio:
            return "MoreMenu_Option_MuteAllAudio"

        case .muteAllVideo:
            return "MoreMenu_Option_MuteAllVideo"

        case .muteAudio:
            return "MoreMenu_Option_MuteAudio"

        case .muteVideo:
            return "MoreMenu_Option_MuteVideo"

        case .pin:
            return "MoreMenu_Option_Pin"

        case .unPin:
            return "MoreMenu_Option_UnPin"

        case .allowToJoinStage:
            return "MoreMenu_Option_AllowToJoinStage"

        case .denyToJoinStage:
            return "MoreMenu_Option_DenyToJoinStage"

        case .removeFromStage:
            return "MoreMenu_Option_RemoveFromStage"

        case .kick:
            return "MoreMenu_Option_Kick"

        case .files:
            return "MoreMenu_Option_Files"

        case .images:
            return "MoreMenu_Option_Images"

        case .cancel:
            return "MoreMenu_Option_Cancel"

        }
    }
}


protocol BottomSheetModelProtocol {
    associatedtype IDENTIFIER
    var image: RtkImage {get}
    var title: String {get}
    var type: IDENTIFIER {get}
    var unreadCount: String {get}
    var onTap: (_ bottomSheet: BottomSheet) -> Void {get}
}

class UnreadCountView: UIView {

   private let title : RtkLabel = {
       let label = RtkUIUtility.createLabel(text: "")
       label.font = UIFont.systemFont(ofSize: 12)
       return label
   }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        createSubView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(unReadCount: String) {
        if unReadCount.count > 0 {
            self.isHidden = false
        }else {
            self.isHidden = true
        }
        self.title.text = unReadCount
    }
    
    private func createSubView() {
        self.backgroundColor = rtkSharedTokenColor.brand.shade500
        self.addSubview(title)
        title.set(.sameLeadingTrailing(self, rtkSharedTokenSpace.space1),
                  .sameTopBottom(self, rtkSharedTokenSpace.space1))
        
    }
    
}

class BottomSheet: UIView {
    let selfTag = 89373
    private let baseStackView = RtkUIUtility.createStackView(axis: .vertical, spacing: 0)
    let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypeNameTextField ?? .rounded
    let backgroundColorValue = DesignLibrary.shared.color.background.shade900
    let backgroundColorValueForLineSeparator = DesignLibrary.shared.color.background.shade800
    let tokenSpace = DesignLibrary.shared.space
    var options = [UIView]()
    public var onHide: ((BottomSheet)->Void)?
    
    init() {
        super.init(frame: .zero)
        self.addSubview(baseStackView)
        baseStackView.layer.cornerRadius = DesignLibrary.shared.borderRadius.getRadius(size: .one,
                                                                                       radius: borderRadiusType)
        baseStackView.set(.sameLeadingTrailing(self, tokenSpace.space1),
                          .bottom(self),
                          .top(self, tokenSpace.space4, .greaterThanOrEqual))
        
        baseStackView.backgroundColor = backgroundColorValue
        baseStackView.layoutMargins = UIEdgeInsets(top: 0, left: tokenSpace.space4, bottom: 0, right: 0)
        baseStackView.isLayoutMarginsRelativeArrangement = true
        self.tag = selfTag
    }
    
    func reload(title: String? = nil, features: [some BottomSheetModelProtocol]) {
        for view in baseStackView.arrangedSubviews {
            baseStackView.removeFully(view: view)
        }

        if let title = title, title.count > 0 {
            baseStackView.addArrangedSubview(self.getTitleView(title: title))
        }
        
        var views = [UIView]()
        for model in features {
            let button = getMenuButton(title: model.title, systemImage: model.image, unreadCount: model.unreadCount)
            button.button.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
            button.button.model = model
            baseStackView.addArrangedSubview(button.baseView)
            views.append(button.baseView)
        }
        self.options = views
    }
    
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden == false && self.frame.contains(point) {
            if self.baseStackView.frame.contains(point) {
                return super.hitTest(point, with: event)
            }
            DispatchQueue.main.async {
                // This is so that when this view say that touches are in this but not action sheet button.
                // then we have to consume these touches and current view should not be hidden before returning from this method else this will ignore these touches and passes down the hierarchy.
                self.hideSheet()
            }
            return self
        }
        return nil
    }
    
    public func show(on view: UIView) {
        view.viewWithTag(selfTag)?.removeFromSuperview()
        view.addSubview(self)
        self.set(.fillSuperView(view))
    }
    
    @objc private func buttonTapped(button: CustomButton) {
        // Perform additional actions here
        button.model?.onTap(self)
        self.hideSheet()
    }
    
    private func hideSheet() {
        self.isHidden = true
        self.onHide?(self)
    }
    
    class CustomButton: UIButton {
        var model: (any BottomSheetModelProtocol)?
    }
    
    private func getTitleView(title: String, needLine: Bool = true) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        let title = RtkUIUtility.createLabel(text: title, alignment: .center)
        view.addSubview(title)
        title.font = UIFont.systemFont(ofSize: 16)
        title.set(.sameLeadingTrailing(view), .sameTopBottom(view, tokenSpace.space4))
        if needLine {
            let lineView = UIView()
            view.addSubview(lineView)
            lineView.set(.leading(view),
                         .trailing(view, tokenSpace.space4),
                         .height(1),
                         .bottom(view))
            lineView.backgroundColor = backgroundColorValueForLineSeparator
        }
        return view
    }
    
    
    
    private func getMenuButton(title: String, systemImage: RtkImage, needLine: Bool = true, unreadCount: String = "") -> (baseView: UIView,button: CustomButton, notificationMessageView: UnreadCountView) {
        let color = DesignLibrary.shared.color.textColor.onBackground.shade900
        let view = UIView()
        view.isUserInteractionEnabled = false
        let imageView = RtkUIUtility.createImageView(image: systemImage)
        imageView.tintColor = color
        let baseImageView = UIView()
        baseImageView.addSubview(imageView)
        
        imageView.set(.centerView(baseImageView),
                      .top(baseImageView, 0.0 , .greaterThanOrEqual),
                      .leading(baseImageView,0.0,.greaterThanOrEqual))
        let title = RtkUIUtility.createLabel(text: title, alignment: .left)
        title.textColor = color
        view.addSubview(baseImageView)
        view.addSubview(title)
        baseImageView.set(.sameTopBottom(view, tokenSpace.space2), .leading(view), .width(30))
        title.set(.after(baseImageView, tokenSpace.space2), .centerY(baseImageView))
        
        let unreadCountView = UnreadCountView()
        view.addSubview(unreadCountView)
        unreadCountView.set(.after(title, tokenSpace.space2, .greaterThanOrEqual),
                            .trailing(view, tokenSpace.space2),
                            .centerY(title),
                            .height(tokenSpace.space5),
                            .width(tokenSpace.space5, .greaterThanOrEqual))
        unreadCountView.layer.cornerRadius = tokenSpace.space5/2.0
        unreadCountView.layer.masksToBounds = true
        unreadCountView.set(unReadCount: unreadCount)
        
        
        let viewBase = UIView()
        let fixedHeightView = UIView()
        viewBase.addSubview(fixedHeightView)
        fixedHeightView.set(.fillSuperView(viewBase),
                            .height(50))
        
        let button = CustomButton()
        viewBase.addSubview(button)
        button.set(.fillSuperView(viewBase))
        fixedHeightView.addSubview(view)
        
        view.set(.top(fixedHeightView, 0.0, .greaterThanOrEqual),
                 .centerY(fixedHeightView),
                 .leading(fixedHeightView),
                 .trailing(fixedHeightView, tokenSpace.space4, .greaterThanOrEqual))
        if needLine {
            let lineView = UIView()
            viewBase.addSubview(lineView)
            lineView.set(.leading(viewBase),
                         .trailing(viewBase, tokenSpace.space4),
                         .height(1),
                         .bottom(viewBase))
            lineView.backgroundColor = backgroundColorValueForLineSeparator
        }
        return (viewBase, button, unreadCountView)
    }
}

public class RtkMoreMenu: UIView {
    
    struct BottomSheetModel: BottomSheetModelProtocol {
        var unreadCount: String = ""
        
        var type: MenuType
        
        var image: RtkImage
        
        var title: String
        
        var onTap: (BottomSheet) -> Void
    }
    
    var bottomSheet: BottomSheet!
    let selfTag = 89372
    private var features: [MenuType]
    private var onSelect: (MenuType) -> ()
    private var title:String? = nil
    public  init(title:String? = nil, features: [MenuType] , onSelect: @escaping (MenuType) -> ()) {
        self.onSelect = onSelect
        self.title = title
        self.features = features
        super.init(frame: .zero)
        bottomSheet = BottomSheet()
        bottomSheet.onHide = {[weak self] bottomSheet in
            guard let self = self else {return}
            self.hideSheet()
        }
        reload(title: title, features: features)
        self.tag = selfTag
    }
    
    func reload(title:String? = nil, features: [MenuType]) {
        self.features = features
        let model = getModel(features: features)
        bottomSheet.reload(title: title, features: model)
        for i in 0..<features.count {
            let menu = features[i]
            //Setting accessIdentifier for Maestro Testing
            bottomSheet.options[i].accessibilityIdentifier = menu.getAccessIndentifier()
        }
    }
    
    private func getModel(features: [MenuType]) -> [BottomSheetModel] {
        var model = [BottomSheetModel]()
        for feature in features {
            switch feature {
            case.files:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_attach")), title: "File", onTap: { [weak self] bottomSheet in
                    guard let self = self else { return }
                    onSelect(feature)
                    self.hideSheet()
                }))
                
            case.images:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_image")), title: "Image", onTap: { [weak self] bottomSheet in
                    guard let self = self else { return }
                    onSelect(feature)
                    self.hideSheet()
                }))
            case.muteAllAudio:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_mic_disabled")), title: "Mute All Audio", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case.muteAllVideo:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_video_disabled")), title: "Mute All Video", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case.shareMeetingUrl:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_chat_send")), title: "Share meeting", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .poll(let notificationMessage):
                model.append(BottomSheetModel(unreadCount: notificationMessage, type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_polls")), title: "Polls", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .unPin:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_unpin")), title: "Unpin", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .startScreenShare:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_start_screenshare")), title: "Screen Share", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .stopScreenShare:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_start_screenshare")), title: "Stop screen share", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
                
            case .muteAudio:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_mic_disabled")), title: "Mute", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .pin:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_pin")), title: "Pin", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .allowToJoinStage:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_stage_join")), title: "Allow to join Stage", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .denyToJoinStage:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_stage_join")), title: "Revoke to join Stage", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .removeFromStage:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_stage_leave")), title: "Remove from Stage", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .muteVideo:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_video_disabled")), title: "Turn off video", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .kick:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_kick")), title: "Kick", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .chat(let notificationMessage):
                model.append(BottomSheetModel(unreadCount: notificationMessage, type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_chat")), title: "Chat", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .plugins:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_plugin")), title: "Plugin", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .settings:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_setting")), title: "Settings", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .recordingStart:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_recording_start")), title: "Record", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .recordingStop:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_recording_stop")), title: "Stop", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .particpants(let notificationMessage):
                
                model.append(BottomSheetModel(unreadCount: notificationMessage, type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_participants")), title: "Participants", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            case .cancel:
                model.append(BottomSheetModel(type: feature, image: RtkImage(image: ImageProvider.image(named: "icon_cross")), title: "Cancel", onTap: { [weak self] bottomSheet in
                    guard let self = self else {return}
                    onSelect(feature)
                    self.hideSheet()
                }))
            }
        }
        return model
    }
    
    public func show(on view: UIView) {
        view.viewWithTag(selfTag)?.removeFromSuperview()
        view.addSubview(self)
        self.set(.fillSuperView(view))
        self.bottomSheet.show(on: self)
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hideSheet() {
        self.isHidden = true
    }
}
