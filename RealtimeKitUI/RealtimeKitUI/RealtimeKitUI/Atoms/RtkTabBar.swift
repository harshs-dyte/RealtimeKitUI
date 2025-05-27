//
//  RtkControlBar.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 29/12/22.
//

import UIKit
import RealtimeKit
public protocol RtkTabBarDelegate: AnyObject {
    func didTap(button: RtkControlBarButton, atIndex index:NSInteger)
    func getTabBarHeightForPortrait() -> CGFloat
    func getTabBarWidthForLandscape() -> CGFloat
}

public protocol RtkControlBarAppearance: BaseAppearance {
    var backgroundColor: BackgroundColorToken.Shade {get set}
}

public class RtkControlBarAppearanceModel : RtkControlBarAppearance {
    public var desingLibrary: RtkDesignTokens

    public required init(designLibrary: RtkDesignTokens = DesignLibrary.shared) {
        self.desingLibrary = designLibrary
        backgroundColor = desingLibrary.color.background.shade900
    }

    public var backgroundColor: BackgroundColorToken.Shade
}

open class RtkTabBar: UIView, AdaptableUI {
    public var portraitConstraints = [NSLayoutConstraint]()
    public var landscapeConstraints = [NSLayoutConstraint]()
    private var previousOrientationIsLandscape = UIScreen.isLandscape()
    private struct Constants {
        static let tabBarAnimationDuration: Double = 1.5

    }
    
    private lazy var containerView: UIView = {
       UIView()
    }()
    
    public weak var delegate:RtkTabBarDelegate?
    
    private let tokenSpace = DesignLibrary.shared.space

    public let stackView = UIStackView()
    
    private var appearance: RtkControlBarAppearance
    private let bottomSpace: CGFloat
    @objc public static var baseHeight: CGFloat = 50.0
    @objc public static var defaultBottomAdjustForNonNotch: CGFloat = 15.0
    private let baseWidthForLandscape: CGFloat = 57

    public private(set) var buttons: [RtkControlBarButton] = []
    
    private var selectedButton: RtkControlBarButton? {
        didSet {
            
        }
    }
    
    private var heightConstraint: NSLayoutConstraint?
    private var widthLandscapeConstraint: NSLayoutConstraint?

   public func setHeight() {
       removeHeightWidthConstraint()
        var extra = RtkTabBar.defaultBottomAdjustForNonNotch
        if self.superview!.safeAreaInsets.bottom != 0 {
            extra = self.superview!.safeAreaInsets.bottom
        }
        let height = RtkTabBar.baseHeight + extra
       self.heightConstraint = self.heightAnchor.constraint(equalToConstant: delegate?.getTabBarHeightForPortrait() ?? height)
       self.heightConstraint?.isActive = true
    }
    
    public func setWidth() {
        var extra = RtkTabBar.defaultBottomAdjustForNonNotch
        if UIScreen.isLandscape() && self.superview!.safeAreaInsets.right != 0 {
            extra = self.superview!.safeAreaInsets.right
        }
        self.setWidth(extra: extra)
    }
    
    private func removeHeightContraint() {
        if let constraint = self.heightConstraint {
            constraint.isActive = false
            self.removeConstraint(constraint)
        }
    }
    
    private func removeWidthContraint() {
        if let constraint = self.widthLandscapeConstraint {
            constraint.isActive = false
            self.removeConstraint(constraint)
        }
    }
    
    private func setWidth(extra: CGFloat) {
        removeHeightWidthConstraint()
        let width = baseWidthForLandscape + extra
        self.widthLandscapeConstraint = self.widthAnchor.constraint(equalToConstant: delegate?.getTabBarWidthForLandscape() ?? width)
        self.widthLandscapeConstraint?.isActive = true
    }
    
    private func removeHeightWidthConstraint() {
        self.removeHeightContraint()
        self.removeWidthContraint()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("initwithcoder not supported")
    }

    public init(delegate: RtkTabBarDelegate?, appearance: RtkControlBarAppearance = RtkControlBarAppearanceModel()) {
        self.appearance = appearance
        bottomSpace = tokenSpace.space1
        super.init(frame: .zero)
        self.backgroundColor = appearance.backgroundColor
        self.delegate = delegate
        createViews()
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    deinit {
       NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    open override func updateConstraints() {
        super.updateConstraints()
        self.applyConstraintAsPerOrientation()
        if UIScreen.isLandscape() {
            self.stackView.axis = .vertical
            self.setWidth()
        }else {
            self.stackView.axis = .horizontal
            self.setHeight()
        }
    }
    
    @objc func onOrientationChange() {
        let currentOrientationIsLandscape = UIScreen.isLandscape()
        if previousOrientationIsLandscape != currentOrientationIsLandscape {
            previousOrientationIsLandscape = currentOrientationIsLandscape
            onRotationChange()
        }
    }
    
    func onRotationChange() {
            self.removeHeightWidthConstraint()
            self.setOrientationContraintAsDeactive()
            self.setNeedsUpdateConstraints()
    }
    
   private func createViews() {
        self.translatesAutoresizingMaskIntoConstraints = false
        createContainerView()
        createStackView()
        layoutViews()
    }
    
    private func createContainerView() {
        addSubview(containerView)
        bringSubviewToFront(containerView)
        self.backgroundColor = appearance.backgroundColor
    }
    
    private func createStackView() {
        containerView.addSubview(self.stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.clipsToBounds = true
    }
    
   private func layoutViews() {
       stackView.set(.fillSuperView(containerView))
       addPortraitConstraintsForContainerView()
       addLandscapeConstraintsForContainerView()
       applyOnlyConstraintAsPerOrientation()
    }
    
    private func addPortraitConstraintsForContainerView() {
        containerView.set(.sameLeadingTrailing(self, tokenSpace.space4),
                          .top(self, tokenSpace.space2),
                          .height(RtkTabBar.baseHeight),
                          .bottom(self, tokenSpace.space2,.greaterThanOrEqual), isActive: false)
        portraitConstraints.append(contentsOf: [containerView.get(.leading)!,
                                                containerView.get(.trailing)!,
                                                containerView.get(.top)!,
                                                containerView.get(.height)!,
                                                containerView.get(.bottom)!])
    }
    
    private func addLandscapeConstraintsForContainerView() {
        containerView.set(.sameTopBottom(self, tokenSpace.space4),
                          .leading(self, tokenSpace.space2),
                          .trailing(self, tokenSpace.space2,.greaterThanOrEqual),
                          .width(baseWidthForLandscape), isActive: false)
        landscapeConstraints.append(contentsOf: [containerView.get(.leading)!,
                                                 containerView.get(.trailing)!,
                                                containerView.get(.top)!,
                                                containerView.get(.bottom)!,
                                                 containerView.get(.width)!])
    }
    
    public func setButtons(_ buttons: [RtkControlBarButton]) {
        for button in self.buttons {
            button.clean()
            stackView.removeFully(view: button.superview!)
        }
        self.buttons.removeAll()
        self.buttons = buttons
        
        for button in self.buttons {
            let baseView = BaseView()
            baseView.addSubview(button)
            
            button.set(.top(baseView, 0.0, .greaterThanOrEqual),
                       .centerY(baseView),
                       .centerX(baseView),
                       .leading(baseView, 0.0, .greaterThanOrEqual))
            button.backgroundColor = self.backgroundColor
            stackView.addArrangedSubview(baseView)
        }
    }
    
    public func selectButton(at index: Int) {
        if index >= 0 && index < buttons.count {
            selectedButton = buttons[index]
        }
    }
    
    public func getButton(at index: Int) -> RtkControlBarButton? {
        if index >= 0 && index < buttons.count {
            return buttons[index]
        }
        return nil
    }
        
    public func setItemsOrientation(axis: NSLayoutConstraint.Axis) {
        self.stackView.axis = axis
    }
}


open class RtkControlBar: RtkTabBar {
    public let moreButton: RtkMoreButtonControlBar
    public private(set) var endCallButton: RtkEndMeetingControlBarButton
    private unowned let presentingViewController: UIViewController
    private let meeting: RealtimeKitClient
    private let endCallCompletion: (()->Void)?
    
    public init(meeting: RealtimeKitClient, delegate: RtkTabBarDelegate?, presentingViewController: UIViewController, appearance: RtkControlBarAppearance = RtkControlBarAppearanceModel(), settingViewControllerCompletion:(()->Void)? = nil, onLeaveMeetingCompletion: (()->Void)? = nil) {
        self.meeting = meeting
        self.presentingViewController = presentingViewController
        let moreButton = RtkMoreButtonControlBar(meeting: meeting, presentingViewController: presentingViewController, settingViewControllerCompletion: settingViewControllerCompletion)
        self.moreButton = moreButton
        moreButton.accessibilityIdentifier = "More_ControlBarButton"
        self.endCallCompletion = onLeaveMeetingCompletion
        let endCallButton = RtkEndMeetingControlBarButton(meeting: meeting, alertViewController: presentingViewController) { buttons, alertButton in
            onLeaveMeetingCompletion?()
        }
        endCallButton.accessibilityIdentifier = "End_ControlBarButton"
        self.endCallButton = endCallButton
        
        super.init(delegate: delegate, appearance: appearance)
        self.setButtons([RtkControlBarButton]())
    }
    
    //Override this if you don't want to add More and Call Buttons by defaults
    open func addDefaultButtons(_ buttons: [RtkControlBarButton]) -> [RtkControlBarButton] {
        return buttons
    }
    
    public override func setButtons(_ buttons: [RtkControlBarButton]) {
        var buttons = buttons
        buttons.append(contentsOf: addDefaultButtons(getDefaultButton()))
        super.setButtons(buttons)
    }
    
    private func getDefaultButton() -> [RtkControlBarButton] {
        var defaultButtons =  [RtkControlBarButton]()
        defaultButtons.append(moreButton)
        self.endCallButton = getEndCallButton()
        self.endCallButton.accessibilityIdentifier = "End_ControlBarButton"
        defaultButtons.append(endCallButton)
        return defaultButtons
    }
    
    private func getEndCallButton() -> RtkEndMeetingControlBarButton {
        let endCallButton = RtkEndMeetingControlBarButton(meeting: meeting, alertViewController: presentingViewController) { buttons, alertButton in
            self.endCallCompletion?()
        }
        return endCallButton
    }
    
    public func setTabBarButtonTitles(numOfLines: Int) {
        for button in self.buttons {
            button.btnTitle?.numberOfLines = numOfLines
        }
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   
}

