//
//  BaseProtocols.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 16/02/23.
//

import UIKit

protocol Searchable {
    func search(text: String) -> Bool
}


protocol ReusableObject: AnyObject {}

extension ReusableObject {
    public static var reuseIdentifier: String {
        return String(describing: self)
    }
}


public protocol SetTopbar {
    var topBar: RtkNavigationBar {get}
    var shouldShowTopBar: Bool {get}
}
extension SetTopbar where Self:UIViewController {
    func addTopBar(dismissAnimation: Bool, completion:(()->Void)? = nil) {
        self.view.addSubview(self.topBar)
        if shouldShowTopBar {
            topBar.setBackButtonClick { [weak self] button in
                guard let self = self else {return}
                if self.isModal {
                    self.dismiss(animated: dismissAnimation, completion: completion)
                }else {
                    self.navigationController?.popViewController(animated: dismissAnimation)
                    completion?()
                }
            }
            topBar.set(.sameLeadingTrailing(self.view),
                       .top(self.view),
                       .height(44))
        } else {
            topBar.set(.sameLeadingTrailing(self.view),
                       .top(self.view),
                       .height(0))
        }
    }
}


internal protocol KeyboardObservable: AnyObject {
    var keyboardObserver: KeyboardObserver? { get set }
    func startKeyboardObserving(onShow: @escaping (_ keyboardFrame: CGRect) -> Void,
                                onHide: @escaping () -> Void)
    func stopKeyboardObserving()
}

extension KeyboardObservable {
    public func startKeyboardObserving(onShow: @escaping (_ keyboardFrame: CGRect) -> Void,
                                onHide: @escaping () -> Void) {
        keyboardObserver = KeyboardObserver(onShow: onShow, onHide: onHide)
    }
    
    
    public  func stopKeyboardObserving() {
        keyboardObserver?.stopObserving()
        keyboardObserver = nil
    }

}
