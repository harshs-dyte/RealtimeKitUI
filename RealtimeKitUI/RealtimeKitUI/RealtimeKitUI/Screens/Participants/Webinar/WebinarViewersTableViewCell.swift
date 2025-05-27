//
//  ParticipantInCallTableViewCell.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 16/02/23.
//

import UIKit

class WebinarViewersTableViewCell: ParticipantTableViewCell {
   
    let moreButton = {
        let button = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_more_tabbar"))), rtkButtonState: .active)
        return button
    }()
    private var viewModel: WebinarViewersTableViewCellModel?
    var buttonMoreClick:((RtkButton) -> Void)?

    override func createSubView(on baseView: UIView) {
        super.createSubView(on: baseView)
        let videoButtonStackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: 0)
        self.buttonStackView.addArrangedSubviews(videoButtonStackView, moreButton)
        self.moreButton.addTarget(self, action: #selector(moreButtonClick(button:)), for: .touchUpInside)
    }
    
   @objc func moreButtonClick(button: RtkButton) {
       self.buttonMoreClick?(button)
    }
}

extension WebinarViewersTableViewCell: ConfigureView {
    var model: WebinarViewersTableViewCellModel {
        if let model =  viewModel {
            return model
        }
        fatalError("Before calling this , Please set model first using 'func configure(model: TitleTableViewCellModel)'")
    }
    
    func configure(model: WebinarViewersTableViewCellModel) {
        viewModel = model
        self.profileAvatarView.set(participant: model.participantUpdateEventListener.participant)
        self.nameLabel.text = model.title
        self.cellSeparatorBottom.isHidden = !model.showBottomSeparator
        self.cellSeparatorTop.isHidden = !model.showTopSeparator
        self.moreButton.isHidden = !model.showMoreButton
       
    }
    
}
