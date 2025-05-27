//
//  ParticipantInCallTableViewCell.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 16/02/23.
//

import UIKit

class ParticipantInCallTableViewCell: ParticipantTableViewCell {
    let videoButton = {
        let button = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_video_enabled"))), rtkButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.setImage(ImageProvider.image(named: "icon_video_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        button.backgroundColor = .clear
        return button
    }()
    
    let audioButton = {
        let button = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_mic_enabled"))), rtkButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.textColor.onBackground.shade1000
        button.setImage(ImageProvider.image(named: "icon_mic_disabled")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.selectedStateTintColor = DesignLibrary.shared.color.status.danger
        button.backgroundColor = .clear
        return button
    }()
    var notificationBadge: RtkNotificationBadgeView?
    var moreButton = {
        let button = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_more_tabbar"))), rtkButtonState: .active)
        return button
    }()
    private var viewModel: ParticipantInCallTableViewCellModel?
    var buttonMoreClick:((RtkButton) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        profileAvatarView.backgroundColor = rtkSharedTokenColor.brand.shade500
        profileAvatarView.profileImageView.image = nil
        profileAvatarView.initialName.text = nil
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        notificationBadge?.isHidden = true
    }
    
    override func createSubView(on baseView: UIView) {
        super.createSubView(on: baseView)
        let videoButtonStackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: 0)
        videoButtonStackView.addArrangedSubviews(videoButton, audioButton)
        self.buttonStackView.addArrangedSubviews(videoButtonStackView, moreButton)
        self.moreButton.addTarget(self, action: #selector(moreButtonClick(button:)), for: .touchUpInside)
    }
    
   @objc func moreButtonClick(button: RtkButton) {
       self.buttonMoreClick?(button)
    }
}

extension ParticipantInCallTableViewCell: ConfigureView {
    var model: ParticipantInCallTableViewCellModel {
        if let model =  viewModel {
            return model
        }
        fatalError("Before calling this , Please set model first using 'func configure(model: TitleTableViewCellModel)'")
    }
    
    func configure(model: ParticipantInCallTableViewCellModel) {
        viewModel = model
        self.profileAvatarView.set(participant: model.participantUpdateEventListener.participant)
        self.audioButton.isSelected = !model.participantUpdateEventListener.participant.audioEnabled
        self.videoButton.isSelected = !model.participantUpdateEventListener.participant.videoEnabled
        self.nameLabel.text = model.title
        self.cellSeparatorBottom.isHidden = !model.showBottomSeparator
        self.cellSeparatorTop.isHidden = !model.showTopSeparator
        self.moreButton.isHidden = !model.showMoreButton
        model.participantUpdateEventListener.observeAudioState { [weak self] isEnabled, observer in
            guard let self = self else {return}
            self.audioButton.isSelected = !isEnabled
        }
        model.participantUpdateEventListener.observePinState { [weak self] isPinned, observer in
            guard let self = self else {return}
            self.setPinView(isHidden: !isPinned)
        }
        model.participantUpdateEventListener.observeVideoState { [weak self] isEnabled, observer in
            guard let self = self else {return}
            self.videoButton.isSelected = !isEnabled
        }
    }
    
}
