//
//  Participant.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 09/02/23.
//

import RealtimeKit
import UIKit


public let rtkSharedTokenColor = DesignLibrary.shared.color

public let rtkSharedTokenSpace = DesignLibrary.shared.space

public class ParticipantViewControllerFactory {
    public static func getLivestreamParticipantViewController(meeting: RealtimeKitClient) -> ParticipantViewController {
        return ParticipantViewController(viewModel: LiveParticipantViewControllerModel(meeting: meeting))
    }
    public static func getParticipantViewController(meeting: RealtimeKitClient) -> ParticipantViewController {
        return ParticipantViewController(viewModel: ParticipantViewControllerModel(meeting: meeting))
    }
}

public class ParticipantViewController: RtkBaseViewController, SetTopbar, KeyboardObservable {
    public var shouldShowTopBar: Bool = true
    let tableView = UITableView()
    let viewModel: ParticipantViewControllerModelProtocol
    var keyboardObserver: KeyboardObserver?
    
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn
    private var searchController: SearchViewController?
    
    public let topBar: RtkNavigationBar = {
        let topBar = RtkNavigationBar(title: "Participants")
        return topBar
    }()
    
    init(viewModel: ParticipantViewControllerModelProtocol) {
        self.viewModel = viewModel
        super.init(meeting: viewModel.meeting)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        topBar.set(.top(self.view, self.view.safeAreaInsets.top))
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.accessibilityIdentifier = "GroupCall_Participant_Screen"
        self.setUpView()
        setupKeyboard()
        setUpReconnection {} success: {}
    }
    
    func setUpView() {
        self.addTopBar(dismissAnimation: true)
        setUpTableView()
        reloadScreen()
    }
    
    private func reloadScreen() {
        self.viewModel.load {[weak self] _ in
            guard let self = self else {return}
            self.tableView.reloadData()
        }
    }
    
    func setUpTableView() {
        self.view.addSubview(tableView)
        tableView.backgroundColor = rtkSharedTokenColor.background.shade1000
        tableView.set(.sameLeadingTrailing(self.view),
                      .below(topBar),
                      .bottom(self.view))
        registerCells(tableView: tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
    }
    
    func registerCells(tableView: UITableView) {
        tableView.register(ParticipantInCallTableViewCell.self)
        tableView.register(ParticipantWaitingTableViewCell.self)
        tableView.register(OnStageWaitingRequestTableViewCell.self)
        tableView.register(AcceptButtonTableViewCell.self)
        tableView.register(RejectButtonTableViewCell.self)
        tableView.register(TitleTableViewCell.self)
        tableView.register(SearchTableViewCell.self)
    }
    
    private func setupKeyboard() {
        self.startKeyboardObserving {[weak self] keyboardFrame in
            guard let self = self else {return}
            self.tableView.get(.bottom)?.constant = -keyboardFrame.height
            // self.view.frame.origin.y = keyboardFrame.origin.y - self.scrollView.frame.maxY
        } onHide: {[weak self] in
            guard let self = self else {return}
            self.tableView.get(.bottom)?.constant = 0
            // self.view.frame.origin.y = 0 // Move view to original position
        }
    }
    
    deinit {
        if isDebugModeOn {
            print("RtkUIKit | participantView Controller deinit is calling")
        }
    }
}
extension ParticipantViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let _ = self.viewModel.dataSourceTableView.getItem(indexPath: indexPath) as? TableItemConfigurator<SearchTableViewCell,SearchTableViewCellModel>  {
            let sectionToBeSearch = BaseConfiguratorSection<CollectionTableSearchConfigurator>()
            self.viewModel.dataSourceTableView.iterate(start: indexPath) { subItemIndexPath, itemConfigurator in
                if subItemIndexPath.section == indexPath.section {
                    if let item = itemConfigurator as? TableItemSearchableConfigurator<WebinarViewersTableViewCell,WebinarViewersTableViewCellModel> {
                        sectionToBeSearch.insert(item)
                    }
                    if let item = itemConfigurator as? TableItemSearchableConfigurator<ParticipantInCallTableViewCell,ParticipantInCallTableViewCellModel> {
                        sectionToBeSearch.insert(item)
                    }
                    
                    return false
                }
                return true
            }
            self.openSearchController(originalItems: [sectionToBeSearch])
        }
    }
    
    func openSearchController(originalItems: [BaseConfiguratorSection<CollectionTableSearchConfigurator>]) {
        let controller = SearchViewController(meeting: self.viewModel.meeting, originalItems: originalItems) { [weak self] in
            guard let self = self else {return}
            self.reloadScreen()
        }
        self.view.addSubview(controller.view)
        controller.view.set(.sameLeadingTrailing(self.view),
                            .below(self.topBar),
                            .bottom(self.view))
        self.searchController = controller
    }
}
extension ParticipantViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.dataSourceTableView.numberOfSections()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.dataSourceTableView.numberOfRows(section: section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  self.viewModel.dataSourceTableView.configureCell(tableView: tableView, indexPath: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = tableView.backgroundColor
        
        if let cell = cell as? ParticipantInCallTableViewCell {
            let model = cell.model
            cell.buttonMoreClick = { [weak self] button in
                guard let self = self else {return}
                if self.createMoreMenu(participantListener: model.participantUpdateEventListener, indexPath: indexPath) {
                    if self.isDebugModeOn {
                        print("Debug RtkUIKit | Critical UIBug Please check why we are showing this button")
                    }
                }
            }
            cell.setPinView(isHidden: !cell.model.participantUpdateEventListener.participant.isPinned)
            
            cell.moreButton.accessibilityIdentifier = "InCall_ThreeDots_Button"
        } else if let cell = cell as? ParticipantWaitingTableViewCell {
            let model = cell.model
            
            cell.buttonCrossClick = { [weak self] button in
                guard let self = self else {return}
                button.showActivityIndicator()
                self.viewModel.waitlistEventListener.rejectWaitingRequest(participant: model.participant)
            }
            cell.buttonTickClick = { [weak self] button in
                guard let self = self else {return}
                button.showActivityIndicator()
                self.viewModel.waitlistEventListener.acceptWaitingRequest(participant: model.participant)
                
            }
            cell.setPinView(isHidden: true)
            
        } else if let cell = cell as? OnStageWaitingRequestTableViewCell {
            let model = cell.model
            
            cell.buttonCrossClick = { [weak self] button in
                guard let self = self else {return}
                button.showActivityIndicator()
                self.viewModel.meeting.stage.denyAccess(userIds: [model.participant.userId])
                button.hideActivityIndicator()
                self.reloadScreen()
            }
            cell.buttonTickClick = { [weak self] button in
                guard let self = self else {return}
                button.showActivityIndicator()
                self.viewModel.meeting.stage.grantAccess(userIds: [model.participant.userId])
                button.hideActivityIndicator()
                self.reloadScreen()
            }
            cell.setPinView(isHidden: !cell.model.participant.isPinned)
            
        } else if let cell = cell as? AcceptButtonTableViewCell {
            cell.button.hideActivityIndicator()
            cell.buttonClick = { [weak self] button in
                guard let self = self else {return}
                button.showActivityIndicator()
                self.viewModel.acceptAll()
                button.hideActivityIndicator()
                
                self.reloadScreen()
            }
            
        } else if let cell = cell as? RejectButtonTableViewCell {
            cell.button.hideActivityIndicator()
            cell.buttonClick = { [weak self] button in
                guard let self = self else {return}
                self.viewModel.rejectAll()
                self.reloadScreen()
            }
        }
        return cell
    }
    
    private func createMoreMenu(participantListener: RtkParticipantUpdateEventListener, indexPath: IndexPath)-> Bool {
        var menus = [MenuType]()
        let participant = participantListener.participant
        let hostPermission = self.viewModel.meeting.localUser.permissions.host
        
        if hostPermission.canPinParticipant {
            if participant.isPinned == false {
                menus.append(.pin)
            }else {
                menus.append(.unPin)
            }
        }
        
        if hostPermission.canMuteAudio && participant.audioEnabled == true {
            menus.append(.muteAudio)
        }
        
        if hostPermission.canMuteVideo && participant.videoEnabled == true {
            menus.append(.muteVideo)
        }
        
        if hostPermission.canKickParticipant && participant != self.viewModel.meeting.localUser {
            menus.append(.kick)
        }
        
        if menus.count < 1 {
            return false
        }
        menus.append(contentsOf: [.cancel])
        
        let moreMenu = RtkMoreMenu(title: participant.name, features: menus, onSelect: { [weak self] menuType in
            guard let _ = self else {return}
            switch menuType {
            case .pin:
                participant.pin()
            case .unPin:
                participant.unpin()
                
            case .muteAudio:
                if let remoteParticipant = participant as? RtkRemoteParticipant{
                    remoteParticipant.disableAudio()
                }
            case .muteVideo:
                if let remoteParticipant = participant as? RtkRemoteParticipant{
                    remoteParticipant.disableVideo()
                }
                
            case .kick:
                if let remoteParticipant = participant as? RtkRemoteParticipant{
                    remoteParticipant.kick()
                }
                
            case .cancel:
                print("Not Supported for now")
                
            default:
                print("No need to handle others for now")
            }
        })
        moreMenu.show(on: view)
        return true
    }
}


