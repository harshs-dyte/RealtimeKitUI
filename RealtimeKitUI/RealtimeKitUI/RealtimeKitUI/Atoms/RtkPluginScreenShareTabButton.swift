//
//  ScreenShareTabButton.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 03/01/23.
//

import UIKit


public class NextPreviousButtonView: UIView {
    public  let previousButton: RtkControlBarButton
    public  let nextButton: RtkControlBarButton
    private let firstLabel: RtkLabel
    private let secondLabel: RtkLabel
    private let slashLabel: RtkLabel
    
    private let tokenBorderRadius = DesignLibrary.shared.borderRadius
    private let tokenSpace = DesignLibrary.shared.space
    private let tokenColor = DesignLibrary.shared.color
    private let tokenTextColorToken = DesignLibrary.shared.color.textColor

    private let borderRadiusType: BorderRadiusToken.RadiusType = AppTheme.shared.cornerRadiusTypePaginationView ?? .extrarounded
   
    public var autolayoutModeEnable = true
    
    let autoLayoutImageView: BaseImageView = {
        let imageView = RtkUIUtility.createImageView(image: RtkImage(image: ImageProvider.image(named: "icon_topbar_autolayout")))
        return imageView
    }()
    
   convenience init() {
       self.init(firsButtonImage: RtkImage(image: ImageProvider.image(named: "icon_left_arrow")), secondButtonImage: RtkImage(image: ImageProvider.image(named: "icon_right_arrow")))
    }
    
    init(firsButtonImage: RtkImage, secondButtonImage: RtkImage) {
        self.previousButton = RtkControlBarButton(image: firsButtonImage, appearance: AppTheme.shared.controlBarButtonAppearance)
        self.nextButton = RtkControlBarButton(image: secondButtonImage, appearance: AppTheme.shared.controlBarButtonAppearance)
        self.firstLabel = RtkUIUtility.createLabel()
        self.firstLabel.font = UIFont.systemFont(ofSize: 16)
        self.firstLabel.textColor = tokenTextColorToken.onBackground.shade900
        self.slashLabel = RtkUIUtility.createLabel(text: "/")
        self.slashLabel.font = UIFont.systemFont(ofSize: 16)
        self.slashLabel.textColor = tokenTextColorToken.onBackground.shade600
        self.secondLabel = RtkUIUtility.createLabel()
        self.secondLabel.font = UIFont.systemFont(ofSize: 12)
        self.secondLabel.textColor = tokenTextColorToken.onBackground.shade600
        super.init(frame: .zero)
        createView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createView() {
        let stackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: 0)
        self.addSubview(stackView)
        stackView.set(.fillSuperView(self))
        
        let buttonBaseViewPrevious = UIView()
        buttonBaseViewPrevious.addSubview(previousButton)
        previousButton.set(.sameTopBottom(buttonBaseViewPrevious),
                           .trailing(buttonBaseViewPrevious),
                           .leading(buttonBaseViewPrevious))
        let buttonBaseViewNext = UIView()
        buttonBaseViewNext.addSubview(nextButton)
        nextButton.set(.sameTopBottom(buttonBaseViewNext),
                           .trailing(buttonBaseViewNext),
                           .leading(buttonBaseViewNext))
        let titleBaseView = UIView()
        titleBaseView.addSubview(firstLabel)
        titleBaseView.addSubview(slashLabel)
        titleBaseView.addSubview(secondLabel)
        
        firstLabel.set(.sameTopBottom(titleBaseView),
                       .leading(titleBaseView))
        slashLabel.set(.sameTopBottom(titleBaseView),
                       .after(firstLabel),
                       .before(secondLabel))
        secondLabel.set(.sameTopBottom(titleBaseView),
                        .trailing(titleBaseView))
        titleBaseView.addSubview(autoLayoutImageView)
        autoLayoutImageView.set(.fillSuperView(titleBaseView))
        
        stackView.addArrangedSubviews(buttonBaseViewPrevious,titleBaseView,buttonBaseViewNext)
        self.backgroundColor = tokenColor.background.shade900
        autoLayoutImageView.backgroundColor = self.backgroundColor
        self.layer.masksToBounds = true
        self.layer.cornerRadius = tokenBorderRadius.getRadius(size: .two, radius: borderRadiusType)

    }
    
    func setText(first: String, second: String) {
        self.firstLabel.text = first
        self.secondLabel.text = second
    }
}

public protocol PluginScreenShareTabButtonDesignDependency: BaseAppearance {
    var selectedStateBackGroundColor:  TextColorToken.Brand.Shade {get}
    var normalStateBackGroundColor: TextColorToken.Background.Shade {get}
    var cornerRadius: BorderRadiusToken.RadiusType {get}
    var titleColor: TextColorToken.Background.Shade {get}
    var acitivityInidicatorColor: TextColorToken.Background.Shade {get}
}


public class PluginScreenShareTabButtonDesignDependencyModel : PluginScreenShareTabButtonDesignDependency {
    public var desingLibrary: RtkDesignTokens
    public var selectedStateBackGroundColor: TextColorToken.Brand.Shade
    public var normalStateBackGroundColor: TextColorToken.Background.Shade
    public var cornerRadius: BorderRadiusToken.RadiusType = .rounded
    public var titleColor: TextColorToken.Background.Shade
    public var acitivityInidicatorColor: TextColorToken.Background.Shade

    public required init(designLibrary: RtkDesignTokens = DesignLibrary.shared) {
        self.desingLibrary = designLibrary
        selectedStateBackGroundColor = designLibrary.color.textColor.onBrand.shade500
        normalStateBackGroundColor = designLibrary.color.textColor.onBackground.shade700
        titleColor = designLibrary.color.textColor.onBackground.shade900
        acitivityInidicatorColor = designLibrary.color.textColor.onBackground.shade900
    }
   
}


public class RtkPluginScreenShareTabButton: UIButton {
    
    private var normalImage: RtkImage?
    fileprivate var normalTitle: String
    private var selectedImage: RtkImage?
    fileprivate var selectedTitle: String?

    fileprivate var btnTitle: RtkLabel?
    private var baseActivityIndicatorView: BaseIndicatorView?
    fileprivate let appearance: PluginScreenShareTabButtonDesignDependency
   
    public var index: Int = 0
    public let id: String
    public var btnImageView: BaseImageView?

    public init(image: RtkImage?, title: String = "", id: String = "", appearance: PluginScreenShareTabButtonDesignDependency = PluginScreenShareTabButtonDesignDependencyModel()) {
        self.normalImage = image
        self.id = id
        self.appearance = appearance
        self.normalTitle = title
        super.init(frame: .zero)
        self.layer.cornerRadius = appearance.desingLibrary.borderRadius.getRadius(size: .one, radius: appearance.cornerRadius)
        createButton()
        self.backgroundColor = appearance.normalStateBackGroundColor
        self.clipsToBounds = true
    }
    
    public override var isSelected: Bool {
        didSet {
            if isSelected == true {
                if let image = self.selectedImage {
                    self.btnImageView?.setImage(image: image)
                }
                if let title = self.selectedTitle {
                    self.btnTitle?.setTextWhenInsideStackView(text: title)
                }
                self.backgroundColor = appearance.selectedStateBackGroundColor
            }else {
                if let image = self.normalImage {
                    self.btnImageView?.setImage(image: image)
                }
                self.btnTitle?.setTextWhenInsideStackView(text: self.normalTitle)
                self.backgroundColor = appearance.normalStateBackGroundColor
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setSelected(image: RtkImage) {
        self.selectedImage = RtkImage.init(image: image.image?.withRenderingMode(.alwaysTemplate), url: image.url)
    }
    
    public func setSelected(title: String) {
        self.selectedTitle = title
    }
    
   private func createButton() {
        let baseView = UIView()
        self.addSubview(baseView)
        baseView.set(.fillSuperView(self))
        baseView.isUserInteractionEnabled = false
        let buttonsComponent = getLabelAndImageOnlyView()
        self.btnTitle = buttonsComponent.title
        self.btnTitle?.setTextWhenInsideStackView(text: self.normalTitle)
        self.btnTitle?.textColor = appearance.titleColor
        self.btnImageView = buttonsComponent.imageView
        self.btnImageView?.tintColor = self.btnTitle?.textColor
        baseView.addSubview(buttonsComponent.stackView)
        buttonsComponent.stackView.set(.top(baseView, rtkSharedTokenSpace.space2, .greaterThanOrEqual),
                                       .centerY(baseView),
                                       .leading(baseView, rtkSharedTokenSpace.space2, .greaterThanOrEqual),
                                       .centerX(baseView))
    }
    
    private func getLabelAndImageOnlyView() -> (stackView: BaseStackView, title: RtkLabel , imageView: BaseImageView) {
        let stackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: rtkSharedTokenSpace.space2)
        let imageView = RtkUIUtility.createImageView(image: self.normalImage)
        let title = RtkUIUtility.createLabel(text: self.normalTitle)
        title.font = UIFont.systemFont(ofSize: 14)
        stackView.addArrangedSubviews(imageView,title)
        return (stackView: stackView ,title: title,imageView: imageView)
    }
}

extension RtkPluginScreenShareTabButton {
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.alpha = 0.6
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.alpha = 1.0
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.alpha = 1.0
    }
}

extension RtkPluginScreenShareTabButton {
      
     private func showActivityIndicator() {
          if self.baseActivityIndicatorView == nil {
              let baseIndicatorView = BaseIndicatorView.createIndicatorView()
              self.addSubview(baseIndicatorView)
              baseIndicatorView.set(.fillSuperView(self))
              self.baseActivityIndicatorView = baseIndicatorView
          }
          self.baseActivityIndicatorView?.indicatorView.color = appearance.acitivityInidicatorColor
          self.baseActivityIndicatorView?.indicatorView.startAnimating()
          self.baseActivityIndicatorView?.backgroundColor = self.backgroundColor
          self.bringSubviewToFront(self.baseActivityIndicatorView!)
          self.baseActivityIndicatorView?.isHidden = false
      }
      
    private func hideActivityIndicator() {
          self.baseActivityIndicatorView?.indicatorView.stopAnimating()
          self.baseActivityIndicatorView?.isHidden = true
      }
}

public class SyncScreenShareTabButton: RtkPluginScreenShareTabButton {
    public override var isSelected: Bool {
        didSet {
            if isSelected == true {
                if let title = self.selectedTitle {
                    self.btnTitle?.setTextWhenInsideStackView(text: title)
                    self.backgroundColor = DesignLibrary.shared.color.status.danger
                }
            }else {
                self.btnTitle?.setTextWhenInsideStackView(text: self.normalTitle)
                self.backgroundColor = DesignLibrary.shared.color.status.success

            }
        }
    }
}
