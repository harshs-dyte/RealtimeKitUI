//
//  RtkPeerView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 12/12/22.
//

import Foundation


protocol RtkPeerViewDesignDependency: BaseAppearance {
    var backgroundColor: BackgroundColorToken.Shade {get}
    var cornerRadius: BorderRadiusToken.RadiusType {get}
}

class RtkPeerViewViewModel: RtkPeerViewDesignDependency {
    public var desingLibrary: RtkDesignTokens
    var backgroundColor: BackgroundColorToken.Shade
    var cornerRadius: BorderRadiusToken.RadiusType = .rounded
    
    required public init(designLibrary: RtkDesignTokens = DesignLibrary.shared) {
        self.desingLibrary = designLibrary
        backgroundColor = designLibrary.color.background.video
    }
}

public  class RtkPeerView: BaseView {
    private let appearance: RtkPeerViewDesignDependency

    init(frame: CGRect, appearance: RtkPeerViewDesignDependency = RtkPeerViewViewModel()) {
        self.appearance = appearance
        super.init(frame: .zero)
        self.backgroundColor = self.appearance.backgroundColor
        self.layer.cornerRadius = self.appearance.desingLibrary.borderRadius.getRadius(size: .two, radius: self.appearance.cornerRadius)
        self.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
