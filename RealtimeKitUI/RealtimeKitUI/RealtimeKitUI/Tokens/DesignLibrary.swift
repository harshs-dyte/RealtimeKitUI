//
//  Tokens.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit


public protocol RtkDesignTokens {
    var color: ColorTokens {get}
    var space: SpaceToken {get}
    var borderSize: BorderWidthToken {get}
    var borderRadius: BorderRadiusToken {get}
}

public class DesignLibrary: RtkDesignTokens {
    
    public var color: ColorTokens
    public var space: SpaceToken = SpaceToken()
    public var borderSize: BorderWidthToken
    public var borderRadius: BorderRadiusToken
    
    public static let shared:DesignLibrary = DesignLibrary()
    
    
    private init() {
        let configurator = DesignLibraryConfigurator()
        color =  ColorTokens(brand: BrandColorToken(base: configurator.colorBrandBase),
                             background: BackgroundColorToken(base: configurator.colorBackgroundBase),
                             status: StatusColor(danger: configurator.statusDangerColor,
                                                 success: configurator.statusSuccessColor,
                                                 warning: configurator.statusWarningColor),
                             textColor: TextColorToken(background: TextColorToken.Background(base: configurator.textColorBackgroundBase),
                                                  brand: TextColorToken.Brand(base:configurator.textColorBrandBase)))
        self.borderRadius = BorderRadiusToken(roundFactor: configurator.cornerRadiusRoundFactor,
                                         extraRoundFactor: configurator.cornerRadiusExtraRoundFactor,
                                         circularFactor: configurator.cornerRadiusCircularFactor)
        self.borderSize = BorderWidthToken(thinFactor: configurator.borderSizeThinFactor,
                                     fatFactor: configurator.borderSizeFatFactor)
    }
    
    func setConfigurator(configurator: DesignLibraryConfiguratorProtocol) {
        color =  ColorTokens(brand: BrandColorToken(base: configurator.colorBrandBase),
                             background: BackgroundColorToken(base: configurator.colorBackgroundBase),
                             status: StatusColor(danger: configurator.statusDangerColor,
                                                 success: configurator.statusSuccessColor,
                                                 warning: configurator.statusWarningColor),
                             textColor: TextColorToken(background: TextColorToken.Background(base: configurator.textColorBackgroundBase),
                                                  brand: TextColorToken.Brand(base:configurator.textColorBrandBase)))
        self.borderRadius = BorderRadiusToken(roundFactor: configurator.cornerRadiusRoundFactor,
                                         extraRoundFactor: configurator.cornerRadiusExtraRoundFactor,
                                         circularFactor: configurator.cornerRadiusCircularFactor)
        self.borderSize = BorderWidthToken(thinFactor: configurator.borderSizeThinFactor,
                                     fatFactor: configurator.borderSizeFatFactor)
    }
}

public protocol DesignLibraryConfiguratorProtocol {
    var colorBackgroundBase: BackgroundColorToken.Shade {get}
    var colorBrandBase: BrandColorToken.Shade {get}
    
    var textColorBackgroundBase: TextColorToken.Background.Shade {get}
    var textColorBrandBase: TextColorToken.Brand.Shade {get}
    
    var statusDangerColor: StatusColor.Shade {get}
    var statusSuccessColor: StatusColor.Shade {get}
    var statusWarningColor: StatusColor.Shade {get}
    
    var cornerRadiusRoundFactor: CGFloat {get}
    var cornerRadiusExtraRoundFactor: CGFloat {get}
    var cornerRadiusCircularFactor: CGFloat {get}
    
    var borderSizeThinFactor: CGFloat {get}
    var borderSizeFatFactor: CGFloat {get}
}


class DesignLibraryConfigurator: DesignLibraryConfiguratorProtocol {
    
    public let colorBackgroundBase: BackgroundColorToken.Shade = BackgroundColorToken.Shade(hex: "#050505")!
    public let colorBrandBase: BrandColorToken.Shade = BrandColorToken.Shade(hex: "#0246FD")!
    
    public let textColorBackgroundBase: TextColorToken.Background.Shade = TextColorToken.Background.Shade(hex: "#FFFFFF")!
    public let textColorBrandBase: TextColorToken.Brand.Shade = TextColorToken.Brand.Shade(hex: "#111111")!
    
    public let statusDangerColor: StatusColor.Shade = StatusColor.Shade(hex: "#FF2D2D")!
    public let statusSuccessColor: StatusColor.Shade = StatusColor.Shade(hex: "#83D017")!
    public let statusWarningColor: StatusColor.Shade = StatusColor.Shade(hex: "#FFCD07")!
    
    public let cornerRadiusRoundFactor: CGFloat = 4.0
    public let cornerRadiusExtraRoundFactor: CGFloat = 8.0
    public let cornerRadiusCircularFactor: CGFloat = 8.0
    
    public let borderSizeThinFactor: CGFloat =  1.0
    public let borderSizeFatFactor: CGFloat = 2.0
    
}

public protocol AppThemeProtocol {
    var cornerRadiusTypeButton: BorderRadiusToken.RadiusType? {get}
    var cornerRadiusTypePaginationView: BorderRadiusToken.RadiusType? {get}
    var cornerRadiusTypePeerView: BorderRadiusToken.RadiusType? {get}
    var cornerRadiusTypeDropDown: BorderRadiusToken.RadiusType?{get}
    var cornerRadiusTypeNameTag: BorderRadiusToken.RadiusType? {get}
    var cornerRadiusTypeNameTextField: BorderRadiusToken.RadiusType?{get}
    var cornerRadiusTypeCreateView: BorderRadiusToken.RadiusType?{get}
    var cornerRadiusTypeNameBottomSheet: BorderRadiusToken.RadiusType?{get}
    var borderSizeWidthTypeTextField: BorderWidthToken.Width? {get}
    var borderSizeWidthTypeButton: BorderWidthToken.Width? {get}
    var borderSizeWidthTypeDropDown: BorderWidthToken.Width? {get}
    
    var cornerRadiusTypeImageView: BorderRadiusToken.RadiusType {get}
    var controlBarButtonAppearance: RtkControlBarButtonAppearance {get}
    var buttonAppearance: RtkButtonAppearance {get}
    var nameTagAppearance: RtkNameTagAppearance {get}
    var clockViewAppearance: RtkTextAppearance {get}
    var meetingTitleAppearance: RtkTextAppearance {get}
    var participantCountAppearance: RtkTextAppearance {get}
    var recordingViewAppearance:RtkRecordingViewAppearance {get}
    var designLibrary: RtkDesignTokens {get}
    init(designToken: RtkDesignTokens)
}

class AppThemeConfigurator: AppThemeProtocol {
      
    var designLibrary: RtkDesignTokens
    
    var controlBarButtonAppearance: RtkControlBarButtonAppearance {
        let model = RtkControlBarButtonAppearanceModel(designLibrary: self.designLibrary)
        return model
    }
    
    var buttonAppearance: RtkButtonAppearance {
        let model = RtkButtonAppearanceModel(designLibrary: self.designLibrary)
        return model
    }
    
    var nameTagAppearance: RtkNameTagAppearance {
        let model = RtkNameTagAppearanceModel(designLibrary: self.designLibrary)
        return model
    }
    
    var clockViewAppearance: RtkTextAppearance {
        let model = RtkTextAppearanceModel(designLibrary: self.designLibrary)
        model.textColor = designLibrary.color.textColor.onBackground.shade700
        model.font = UIFont.systemFont(ofSize: 12)
        return model
    }
    
    var meetingTitleAppearance: RtkTextAppearance {
        let model = RtkTextAppearanceModel(designLibrary: self.designLibrary)
        model.font = UIFont.boldSystemFont(ofSize: 16)
        model.textColor = designLibrary.color.textColor.onBackground.shade700
        return model
    }
    
    var participantCountAppearance: RtkTextAppearance {
        let model = RtkTextAppearanceModel(designLibrary: self.designLibrary)
        model.textColor = designLibrary.color.textColor.onBackground.shade700
        model.font = UIFont.systemFont(ofSize: 12)
        return model
    }
    
    var recordingViewAppearance: RtkRecordingViewAppearance {
        return RtkRecordingViewAppearanceModel(designLibrary: self.designLibrary)
    }
    
    required init(designToken: RtkDesignTokens) {
        self.designLibrary = designToken
    }

    private let cornerRadiusType: BorderRadiusToken.RadiusType = .rounded
    private let borderSizeWidthType: BorderWidthToken.Width = .fat
    
    var cornerRadiusTypeButton: BorderRadiusToken.RadiusType? {
        get {
            return cornerRadiusType
        }
    }
    
    var cornerRadiusTypeImageView: BorderRadiusToken.RadiusType {
        get {
            return cornerRadiusType
        }
    }
    
    
    var cornerRadiusTypePaginationView: BorderRadiusToken.RadiusType? {
        get {
            return .extrarounded
        }
    }
    
    var cornerRadiusTypePeerView: BorderRadiusToken.RadiusType? {
        get {
            return cornerRadiusType
        }
    }
    
    var cornerRadiusTypeDropDown: BorderRadiusToken.RadiusType? {
        get {
            return cornerRadiusType
        }
    }
    
    var cornerRadiusTypeNameTag: BorderRadiusToken.RadiusType? {
        get {
            return cornerRadiusType
        }
    }
    
    var cornerRadiusTypeNameTextField: BorderRadiusToken.RadiusType? {
        get {
            return cornerRadiusType
        }
    }
    
    var cornerRadiusTypeCreateView: BorderRadiusToken.RadiusType? {
        get {
            return cornerRadiusType
        }
    }
    
    var cornerRadiusTypeNameBottomSheet: BorderRadiusToken.RadiusType? {
        get {
            return cornerRadiusType
        }
    }
    
    var borderSizeWidthTypeTextField: BorderWidthToken.Width? {
        get {
            return borderSizeWidthType
        }
    }
    
    var borderSizeWidthTypeButton: BorderWidthToken.Width? {
        get {
            return borderSizeWidthType
        }
    }
    
    var borderSizeWidthTypeDropDown: BorderWidthToken.Width? {
        get {
            return borderSizeWidthType
        }
    }
}

public class AppTheme {
    public static let shared:AppTheme = AppTheme(designTokens: DesignLibrary.shared)
    public var cornerRadiusTypePaginationView: BorderRadiusToken.RadiusType?
    public var cornerRadiusTypePeerView: BorderRadiusToken.RadiusType?
    public var cornerRadiusTypeDropDown: BorderRadiusToken.RadiusType?
    public var cornerRadiusTypeNameTextField: BorderRadiusToken.RadiusType?
    public var cornerRadiusTypeCreateView: BorderRadiusToken.RadiusType?
    public var borderSizeWidthTypeTextField: BorderWidthToken.Width?
    public var borderSizeWidthTypeButton: BorderWidthToken.Width?
    public var borderSizeWidthTypeDropDown: BorderWidthToken.Width?
    public var cornerRadiusTypeNameBottomSheet: BorderRadiusToken.RadiusType?
    public var cornerRadiusTypeImageView: BorderRadiusToken.RadiusType
    public var controlBarButtonAppearance: RtkControlBarButtonAppearance
    public var buttonAppearance: RtkButtonAppearance
    public var nameTagAppearance: RtkNameTagAppearance
    public var clockViewAppearance: RtkTextAppearance
    public var meetingTitleAppearance: RtkTextAppearance
    public var participantCountAppearance: RtkTextAppearance
    public var recordingViewAppearance: RtkRecordingViewAppearance

    init(designTokens: RtkDesignTokens) {
        let configurator = AppThemeConfigurator(designToken: designTokens)
        cornerRadiusTypePaginationView = configurator.cornerRadiusTypePaginationView
        cornerRadiusTypePeerView = configurator.cornerRadiusTypePeerView
        cornerRadiusTypeDropDown = configurator.cornerRadiusTypeDropDown
        cornerRadiusTypeNameTextField = configurator.cornerRadiusTypeNameTextField
        cornerRadiusTypeCreateView = configurator.cornerRadiusTypeCreateView
        borderSizeWidthTypeTextField = configurator.borderSizeWidthTypeTextField
        borderSizeWidthTypeButton = configurator.borderSizeWidthTypeButton
        borderSizeWidthTypeDropDown = configurator.borderSizeWidthTypeDropDown
        cornerRadiusTypeNameBottomSheet = configurator.cornerRadiusTypeNameBottomSheet
        cornerRadiusTypeImageView = configurator.cornerRadiusTypeImageView
        controlBarButtonAppearance = configurator.controlBarButtonAppearance
        buttonAppearance = configurator.buttonAppearance
        nameTagAppearance = configurator.nameTagAppearance
        clockViewAppearance = configurator.clockViewAppearance
        meetingTitleAppearance = configurator.meetingTitleAppearance
        participantCountAppearance = configurator.participantCountAppearance
        recordingViewAppearance = configurator.recordingViewAppearance
    }
    
    public func setUp(theme: AppThemeProtocol) {
        cornerRadiusTypePaginationView = theme.cornerRadiusTypePaginationView
        cornerRadiusTypePeerView = theme.cornerRadiusTypePeerView
        cornerRadiusTypeDropDown = theme.cornerRadiusTypeDropDown
        cornerRadiusTypeNameTextField = theme.cornerRadiusTypeNameTextField
        cornerRadiusTypeCreateView = theme.cornerRadiusTypeCreateView
        borderSizeWidthTypeTextField = theme.borderSizeWidthTypeTextField
        borderSizeWidthTypeButton = theme.borderSizeWidthTypeButton
        borderSizeWidthTypeDropDown = theme.borderSizeWidthTypeDropDown
        controlBarButtonAppearance = theme.controlBarButtonAppearance
        cornerRadiusTypeImageView = theme.cornerRadiusTypeImageView
        buttonAppearance = theme.buttonAppearance
        nameTagAppearance = theme.nameTagAppearance
        recordingViewAppearance = theme.recordingViewAppearance

    }
}
