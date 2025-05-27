//
//  SettingViewController.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 07/12/22.
//

import RealtimeKit
import UIKit
import AVFAudio

public class RtkSettingViewController: RtkBaseViewController, SetTopbar {
    public var shouldShowTopBar: Bool = true
    public var topBar: RtkNavigationBar = RtkNavigationBar(title: "Settings")
    private let baseView: BaseView = BaseView()
    private let selfPeerView: RtkParticipantTileView

    private let spaceToken = DesignLibrary.shared.space
    private let borderRadius = DesignLibrary.shared.borderRadius

    private let nameTagTitle: String
    
    private var cameraDropDown: RtkDropdown<CameraPickerCellModel>!
    private var speakerDropDown: RtkDropdown<RtkAudioPickerCellModel>!
    private var audioSelectionView: RtkCustomPickerView<RtkPickerModel<RtkAudioPickerCellModel>>?

    private let backgroundColor = DesignLibrary.shared.color.background.shade1000
    private let completion: (()->Void)?
    
    public init(nameTag: String, meeting: RealtimeKitClient, completion:(()->Void)? = nil) {
        nameTagTitle = nameTag
        self.completion = completion
        selfPeerView = RtkParticipantTileView(viewModel: VideoPeerViewModel(meeting: meeting, participant: meeting.localUser, showSelfPreviewVideo: true))
        super.init(meeting: meeting)
        
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        topBar.get(.top)?.constant = self.view.safeAreaInsets.top
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
         super.viewDidLoad()
         self.addTopBar(dismissAnimation: true) { [weak self] in
           guard  let self = self else {return}
           self.completion?()
         }
         createSubviews()
         applyConstraintAsPerOrientation()
         self.setTag(name: nameTagTitle)
        
         loadSelfVideoView()
         self.view.backgroundColor =  backgroundColor
        NotificationCenter.default.addObserver(self, selector: #selector(routeChanged(notification:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    deinit {
        print("Debug RtkUIKit | SettingViewController deinit is calling")
    }
    
}

extension RtkSettingViewController {
    
    @objc
    private func routeChanged(notification: Notification) {
        if self.speakerDropDown != nil {
            refreshAudioOutputDropDown()
        }
    }
    
    private func refreshAudioOutputDropDown() {
        let metaData = self.getSpeakerDropDownData()
        self.speakerDropDown.refresh(selectedIndex: UInt(metaData.selectedIndex), options: metaData.devicesModel)
        if self.speakerDropDown.selectedState {
            self.audioSelectionView?.refresh(list: metaData.devicesModel, selectedIndex: UInt(metaData.selectedIndex))
        }
    }

    private func setTag(name: String) {
        selfPeerView.viewModel.refreshNameTag()
        selfPeerView.viewModel.refreshInitialName()
    }
    
    private func createSubviews() {
        self.view.addSubview(baseView)
        baseView.accessibilityIdentifier = "ContainerView"
        
        func addPortraitConstraintToBaseView() {
            baseView.set(.leading(self.view , spaceToken.space2, .greaterThanOrEqual),
                         .centerView(self.view),
                         .below(self.topBar, spaceToken.space4, .greaterThanOrEqual))
           
            portraitConstraints.append(contentsOf: [ baseView.get(.top)!,
                                                     baseView.get(.centerX)!,
                                                     baseView.get(.leading)!,
                                                     baseView.get(.centerY)!])
            setPortraitContraintAsDeactive()
        }
        
        func addLandscapeConstraintToBaseView() {
            baseView.set(.sameLeadingTrailing( self.view, spaceToken.space8),
                         .below(self.topBar),
                         .bottom(self.view))
            landscapeConstraints.append(contentsOf: [ baseView.get(.top)!,
                                                     baseView.get(.bottom)!,
                                                     baseView.get(.leading)!,
                                                     baseView.get(.trailing)!])
    
            setLandscapeContraintAsDeactive()
        }
        
        addPortraitConstraintToBaseView()
        addLandscapeConstraintToBaseView()
        
        baseView.addSubview(selfPeerView)
        
        selfPeerView.clipsToBounds = true
        selfPeerView.accessibilityIdentifier = "SelfPeerView"
        
        func addPortraitConstraintToPeerView() {
            let equalWidthConstraintPeerView =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: self.view, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.7).getConstraint(for: selfPeerView)
            let equalHeightConstraintPeerView =  ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: self.view, toViewAttribute: .height, relation: .equal, constant: 0, multiplier: 0.5).getConstraint(for: selfPeerView)
            
            
            selfPeerView.set(.top(baseView),
                             .sameLeadingTrailing(baseView, spaceToken.space6))
            
            portraitConstraints.append(contentsOf: [equalWidthConstraintPeerView,
                                                    equalHeightConstraintPeerView,
                                                    selfPeerView.get(.top)!,
                                                    selfPeerView.get(.leading)!,
                                                    selfPeerView.get(.trailing)!])
            setPortraitContraintAsDeactive()
        }
        
        
        func addLandscapeConstraintToPeerView() {
            let equalWidthConstraintPeerViewLandscape =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: self.baseView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.5).getConstraint(for: selfPeerView)
            landscapeConstraints.append(equalWidthConstraintPeerViewLandscape)
            let equalHeightConstraintPeerViewLandscape =  ConstraintCreator.Constraint.equate(viewAttribute: .height, toView: self.baseView, toViewAttribute: .height, relation: .equal, constant: 0, multiplier: 0.7).getConstraint(for: selfPeerView)
            landscapeConstraints.append(equalHeightConstraintPeerViewLandscape)

            selfPeerView.set(.top(baseView, spaceToken.space6, .greaterThanOrEqual),
                             .leading(baseView, spaceToken.space6),
                             .centerY(baseView))
            
            landscapeConstraints.append(contentsOf: [selfPeerView.get(.top)!,
                                                     selfPeerView.get(.leading)!,
                                                     selfPeerView.get(.centerY)!])
            setLandscapeContraintAsDeactive()
        }
        addPortraitConstraintToPeerView()
        addLandscapeConstraintToPeerView()
               
        let btnStackView = createDropdownStackView()
        let wrapperView = btnStackView.wrapperView()
        wrapperView.addSubview(btnStackView)
        btnStackView.accessibilityIdentifier = "btnStackView"
        wrapperView.accessibilityIdentifier = "wrapperView_btnStackView"

        baseView.addSubview(wrapperView)


        func addPortraitConstraintToBtnStackView() {

            let equalHeightConstraintBtnStackViewPortrait =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: selfPeerView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.7).getConstraint(for: btnStackView)
            portraitConstraints.append(equalHeightConstraintBtnStackViewPortrait)
            wrapperView.set(.below(selfPeerView, spaceToken.space4),
                            .sameLeadingTrailing(baseView),
                            .bottom(baseView))
            portraitConstraints.append(contentsOf: [ wrapperView.get(.top)!,
                                                     wrapperView.get(.bottom)!,
                                                     wrapperView.get(.leading)!,
                                                     wrapperView.get(.trailing)!])

            btnStackView.set(.top(wrapperView, 0, .greaterThanOrEqual),
                .leading(wrapperView, 0, .greaterThanOrEqual),
                             .centerView(wrapperView))

            portraitConstraints.append(contentsOf: [
                                                     btnStackView.get(.top)!,
                                                     btnStackView.get(.centerX)!,
                                                     btnStackView.get(.leading)!,
                                                     btnStackView.get(.centerY)!])
            setPortraitContraintAsDeactive()
        }

        func addLandscapeConstraintToBtnStackView() {
            let equalHeightConstraintBtnStackViewPortrait =  ConstraintCreator.Constraint.equate(viewAttribute: .width, toView: selfPeerView, toViewAttribute: .width, relation: .equal, constant: 0, multiplier: 0.7).getConstraint(for: btnStackView)
            landscapeConstraints.append(equalHeightConstraintBtnStackViewPortrait)

            btnStackView.set(.centerX(wrapperView),
                             .centerY(wrapperView),
                             .top(wrapperView, 0, .greaterThanOrEqual),
                             .leading(wrapperView, 0, .greaterThanOrEqual))

            landscapeConstraints.append(contentsOf: [ btnStackView.get(.top)!,
                                                      btnStackView.get(.centerX)!,
                                                      btnStackView.get(.centerY)!,
                                                      btnStackView.get(.leading)!])


            wrapperView.set(.top(baseView, spaceToken.space4),
                             .bottom(baseView,spaceToken.space4),
                             .after(selfPeerView,spaceToken.space4),
                            .trailing(baseView, spaceToken.space4))


            landscapeConstraints.append(contentsOf: [ wrapperView.get(.top)!,
                                                      wrapperView.get(.bottom)!,
                                                      wrapperView.get(.trailing)!,
                                                      wrapperView.get(.leading)!])
            setLandscapeContraintAsDeactive()
        }

        addPortraitConstraintToBtnStackView()
        addLandscapeConstraintToBtnStackView()
    }
    
    private  func createDropdownStackView() -> BaseStackView {
        let stackView = RtkUIUtility.createStackView(axis: .vertical, spacing: spaceToken.space4)
        
        if meeting.localUser.videoEnabled {
            self.cameraDropDown = createCameraDropDown()
            stackView.addArrangedSubviews(cameraDropDown)
        }
        self.speakerDropDown = createAudioDropDown()
        stackView.addArrangedSubviews(speakerDropDown)
        return stackView
    }
    
    private func createCameraDropDown() -> RtkDropdown<CameraPickerCellModel> {
        let currentCameraSelectedDevice: VideoDeviceType? = meeting.localUser.getSelectedVideoDevice()?.type
        
        let cameraDropDown =  RtkDropdown(rightImage: RtkImage(image: ImageProvider.image(named: "icon_angle_arrow_down")), heading: "Camera", options: [CameraPickerCellModel(name: "Front camera", deviceType: .front) ,CameraPickerCellModel(name: "Back camera", deviceType: .rear)], selectedIndex: currentCameraSelectedDevice == .front ? 0 : 1) { [weak self] dropDown in
            guard let self = self else {return}
            let currentSelectedDevice: VideoDeviceType? = self.meeting.localUser.getSelectedVideoDevice()?.type
           
            let picker = RtkCustomPickerView.show(model: RtkPickerModel(title: dropDown.heading, selectedIndex: currentSelectedDevice == .front ? 0 : 1, cells: dropDown.options), on: self.view)
            picker.onSelectRow = { [weak self] picker, index  in
                guard let self = self else {return}
                let currentSelectedDevice = picker.options[index]
                self.toggleCamera(rtkClient: self.meeting, selectDevice: currentSelectedDevice.deviceType)
                dropDown.selectOption(index: currentSelectedDevice.deviceType == .front ? 0 : 1)
            }
            picker.onCancelButtonClick = { [weak self] _ in
                guard let self = self else {return}
                self.toggleCamera(rtkClient: self.meeting, selectDevice: currentSelectedDevice)
                dropDown.selectOption(index: currentSelectedDevice == .front ? 0 : 1)
            }
        }
        return cameraDropDown
    }
    
    private func getSpeakerDropDownData() -> (devicesModel: [RtkAudioPickerCellModel], selectedIndex: Int) {
        func getDevices() -> [RtkAudioPickerCellModel] {
            let audioDevices = self.meeting.localUser.getAudioDevices()
            var deviceModels = [RtkAudioPickerCellModel]()
            for device in audioDevices {
                deviceModels.append(RtkAudioPickerCellModel(name: device.type.displayName, deviceType: device.type))
            }
            return deviceModels
        }
        
        func selectedIndex(current: AudioDeviceType?, deviceModels: [RtkAudioPickerCellModel]) -> Int {
            var count = -1
            for deviceModel in deviceModels {
                count += 1
                if deviceModel.deviceType == current {
                    return count
                }
            }
            return count
        }
        let currentAudioSelectedDevice: AudioDeviceType? = self.meeting.localUser.getSelectedAudioDevice()?.type
        let devices = getDevices()
        return (devices, selectedIndex(current: currentAudioSelectedDevice, deviceModels: devices))
    }
   
    private func createAudioDropDown() -> RtkDropdown<RtkAudioPickerCellModel> {
        
        let metaData = getSpeakerDropDownData()
        let speakerDropDown =  RtkDropdown(rightImage: RtkImage(image: ImageProvider.image(named: "icon_angle_arrow_down")), heading: "Speaker (output)", options: metaData.devicesModel, selectedIndex:UInt(metaData.selectedIndex)) { [weak self] dropDown in
            guard let self = self else {return}
            let metaData = getSpeakerDropDownData()
            let audioDevices = self.meeting.localUser.getAudioDevices()
            
            let picker = RtkCustomPickerView.show(model: RtkPickerModel(title: dropDown.heading, selectedIndex: UInt(metaData.selectedIndex), cells: dropDown.options), on: self.view)
            picker.onSelectRow = { [weak self] picker, index  in
                guard let self = self else {return}
                let currentSelectedDevice = picker.options[index]
                for device in audioDevices {
                    if currentSelectedDevice.deviceType == device.type {
                        self.meeting.localUser.setAudioDevice(rtkAudioDevice: device)
                        dropDown.selectOption(index: UInt(index))
                    }
                }
            }
            picker.onDoneButtonClick = { [weak dropDown]  picker in
                dropDown?.selectedState = false
            }
            picker.onCancelButtonClick = {[weak dropDown]  picker in
                dropDown?.selectedState = false
            }
            self.audioSelectionView = picker
        }
        return speakerDropDown
    }
    
    private func toggleCamera(rtkClient: RealtimeKitClient, selectDevice: VideoDeviceType?) {
        let videoDevices = rtkClient.localUser.getVideoDevices()
        let currentSelectedDevice: VideoDeviceType? = rtkClient.localUser.getSelectedVideoDevice()?.type
       
        if currentSelectedDevice == .front && selectDevice == .rear {
            if let device = getVideoDevice(type: .rear) {
                rtkClient.localUser.setVideoDevice(rtkVideoDevice: device)
            }
        } else if currentSelectedDevice == .rear && selectDevice == .front  {
            if let device = getVideoDevice(type: .front) {
                rtkClient.localUser.setVideoDevice(rtkVideoDevice: device)
            }
        }
        
        func getVideoDevice(type: VideoDeviceType) -> VideoDevice? {
            for device in videoDevices {
                if device.type == type {
                    return device
                }
            }
            return nil
        }
    }
    
    private func loadSelfVideoView() {
        selfPeerView.refreshVideo()
    }
    
}
