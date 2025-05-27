//
//  RtkMeetingHeaderView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import UIKit
import RealtimeKit

open class RtkMeetingHeaderView: UIView {
    
    private let nextPreviousButtonView = NextPreviousButtonView()
    private var nextButtonClick: ((RtkControlBarButton)->Void)?
    private var previousButtonClick: ((RtkControlBarButton)->Void)?
    
    private let tokenTextColorToken = DesignLibrary.shared.color.textColor
    private let tokenSpace = DesignLibrary.shared.space
    private let backgroundColorValue = DesignLibrary.shared.color.background.shade900
    let containerView = UIView()
    
    public lazy var lblSubtitle: RtkParticipantCountView = {
        let label = RtkParticipantCountView(meeting: self.meeting)
        label.textAlignment = .left
        return label
    }()
    
    private lazy var clockView: RtkClockView = {
        let label = RtkClockView(meeting: self.meeting)
        label.textAlignment = .left
        return label
    }()
    
    private lazy var recordingView: RtkRecordingView = {
        let view = RtkRecordingView(meeting: self.meeting, title: "Rec", image: nil, appearance: AppTheme.shared.recordingViewAppearance)
        return view
    }()
    
    private let meeting: RealtimeKitClient
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setContentTop(offset: CGFloat) {
        self.containerView.get(.top)?.constant = offset
    }
    
    public init(meeting: RealtimeKitClient) {
        self.meeting = meeting
        super.init(frame: .zero)
        self.backgroundColor = backgroundColorValue
        createSubViews()
        self.nextPreviousButtonView.isHidden = true
    }
    
    private func createSubViews() {
        self.addSubview(containerView)
        containerView.set(.sameTopBottom(self, 0, .lessThanOrEqual))
        containerView.set(.sameLeadingTrailing(self, 0, .lessThanOrEqual))
        createSubview(containerView: containerView)
    }
    
    private func createSubview(containerView: UIView) {
        let stackView = RtkUIUtility.createStackView(axis: .vertical, spacing: 4)
        containerView.addSubview(stackView)
        
        let title = RtkMeetingTitleLabel(meeting: self.meeting)
        let stackViewSubTitle = RtkUIUtility.createStackView(axis: .horizontal, spacing: 4)
        stackViewSubTitle.addArrangedSubviews(lblSubtitle,clockView)
        stackView.addArrangedSubviews(title,stackViewSubTitle)
        containerView.addSubview(recordingView)
        
        let nextPreviouStackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: tokenSpace.space2)
        containerView.addSubview(nextPreviouStackView)
        
        stackView.set(.leading(containerView, tokenSpace.space3),
                      .sameTopBottom(containerView, tokenSpace.space2))
        recordingView.set(.centerY(containerView),
                          .top(containerView, tokenSpace.space1, .greaterThanOrEqual),
                          .after(stackView, tokenSpace.space3))
        recordingView.get(.top)?.priority = .defaultLow
        nextPreviouStackView.set(.after(recordingView,tokenSpace.space3, .greaterThanOrEqual),
                                 .trailing(containerView,tokenSpace.space3),
                                 .centerY(containerView),
                                 .top(containerView,tokenSpace.space1,.greaterThanOrEqual))
        nextPreviouStackView.get(.top)?.priority = .defaultLow
        
        let cameraSwitchButton = RtkSwitchCameraButtonControlBar(meeting: self.meeting)
        cameraSwitchButton.backgroundColor = self.backgroundColor
        nextPreviouStackView.addArrangedSubviews(nextPreviousButtonView, cameraSwitchButton)
        
        self.nextPreviousButtonView.previousButton.addTarget(self, action: #selector(clickPrevious(button:)), for: .touchUpInside)
        self.nextPreviousButtonView.nextButton.addTarget(self, action: #selector(clickNext(button:)), for: .touchUpInside)
    }
    
    @objc private func clickPrevious(button: RtkControlBarButton) {
        button.showActivityIndicator()
        self.loadPreviousPage()
        self.previousButtonClick?(button)
    }
    
    @objc private func clickNext(button: RtkControlBarButton) {
        button.showActivityIndicator()
        self.loadNextPage()
        self.nextButtonClick?(button)
    }
    
}

extension RtkMeetingHeaderView {
    // MARK: Public methods
    public func refreshNextPreviouButtonState() {
        
        if (meeting.meta.meetingType == RtkMeetingType.webinar) {
            // For Hive Webinar we are not showing any pagination. Hence feature is disabled.
            return
        }
        
        let nextPagePossible = self.meeting.participants.canGoNextPage
        let prevPagePossible = self.meeting.participants.canGoPreviousPage
        
        if !nextPagePossible && !prevPagePossible {
            //No page view to be shown
            self.nextPreviousButtonView.isHidden = true
        } else {
            self.nextPreviousButtonView.isHidden = false
            
            self.nextPreviousButtonView.nextButton.isEnabled = nextPagePossible
            self.nextPreviousButtonView.previousButton.isEnabled = prevPagePossible
            self.nextPreviousButtonView.nextButton.hideActivityIndicator()
            self.nextPreviousButtonView.previousButton.hideActivityIndicator()
            self.setNextPreviousText(first: Int(self.meeting.participants.currentPageNumber), second: Int(self.meeting.participants.pageCount) - 1)
        }
    }
    
    public func setClicks(nextButton:@escaping(RtkControlBarButton)->Void, previousButton:@escaping(RtkControlBarButton)->Void) {
        self.nextButtonClick = nextButton
        self.previousButtonClick = previousButton
    }
}

private extension RtkMeetingHeaderView {
    private  func loadPreviousPage() {
        if  self.meeting.participants.canGoPreviousPage == true {
            self.meeting.participants.setPage(pageNumber: self.meeting.participants.currentPageNumber - 1)
        }
    }
    
    private  func loadNextPage() {
        if self.meeting.participants.canGoNextPage == true {
            self.meeting.participants.setPage(pageNumber: self.meeting.participants.currentPageNumber + 1)
        }
    }
    
    private func setNextPreviousText(first: Int, second: Int) {
        if first == 0 {
            self.nextPreviousButtonView.autoLayoutImageView.isHidden = false
            self.nextPreviousButtonView.autolayoutModeEnable = true
        }else {
            self.nextPreviousButtonView.autoLayoutImageView.isHidden = true
            self.nextPreviousButtonView.autolayoutModeEnable = false
            
            self.nextPreviousButtonView.setText(first: "\(first)", second: "\(second)")
        }
    }
}
