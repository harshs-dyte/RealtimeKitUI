//
//  ParticipantWaitingTableViewCell.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 16/02/23.
//

import UIKit

class BaseParticipantWaitingTableViewCell: ParticipantTableViewCell {
    let crossButton = {
        let button = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_cross"))), rtkButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.status.danger
        button.isSelected = false
        return button
    }()
    
    let tickButton = {
        let button = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_tick"))), rtkButtonState: .active)
        button.normalStateTintColor = DesignLibrary.shared.color.status.success
        button.isSelected = false
        return button
    }()
    
    var buttonCrossClick:((RtkButton) -> Void)?
    var buttonTickClick:((RtkButton) -> Void)?
    
    override func createSubView(on baseView: UIView) {
        super.createSubView(on: baseView)
        self.buttonStackView.addArrangedSubviews(crossButton, tickButton)
        self.tickButton.addTarget(self, action: #selector(tickButtonClick(button:)), for: .touchUpInside)
        self.crossButton.addTarget(self, action: #selector(crossButtonClick(button:)), for: .touchUpInside)
    }
    
    @objc func tickButtonClick(button: RtkButton) {
         buttonTickClick?(button)
    }
    
    @objc func crossButtonClick(button: RtkButton) {
         buttonCrossClick?(button)
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        crossButton.prepareForReuse()
        tickButton.prepareForReuse()
    }
}

class ParticipantWaitingTableViewCell: BaseParticipantWaitingTableViewCell {
    private var viewModel: ParticipantWaitingTableViewCellModel?
}

class OnStageWaitingRequestTableViewCell: BaseParticipantWaitingTableViewCell {
    private var viewModel: OnStageParticipantWaitingRequestTableViewCellModel?
}


extension OnStageWaitingRequestTableViewCell: ConfigureView {
    var model: OnStageParticipantWaitingRequestTableViewCellModel {
        if let model =  viewModel {
            return model
        }
        fatalError("Before calling this , Please set model first using 'func configure(model: TitleTableViewCellModel)'")
    }
    
    func configure(model: OnStageParticipantWaitingRequestTableViewCellModel) {
        viewModel = model
        self.profileAvatarView.set(participant: model.participant)
        self.nameLabel.text = model.title
        self.cellSeparatorBottom.isHidden = !model.showBottomSeparator
        self.cellSeparatorTop.isHidden = !model.showTopSeparator
    }
}
extension ParticipantWaitingTableViewCell: ConfigureView {
    var model: ParticipantWaitingTableViewCellModel {
        if let model =  viewModel {
            return model
        }
        fatalError("Before calling this , Please set model first using 'func configure(model: TitleTableViewCellModel)'")
    }
    
    func configure(model: ParticipantWaitingTableViewCellModel) {
        viewModel = model
        self.profileAvatarView.set(participant: model.participant)
        self.nameLabel.text = model.title
        self.cellSeparatorBottom.isHidden = !model.showBottomSeparator
        self.cellSeparatorTop.isHidden = !model.showTopSeparator
    }
}

