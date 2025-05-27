//
//  BaseAtom.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit

public class BaseView: UIView {
    
}

public class BaseStackView: UIStackView {
    
}

public class BaseAtomView:UIView, BaseAtom  {
    var isConstraintAdded: Bool = false    
}

public class BaseMoluculeView:UIView, Molecule  {
    var atoms: [BaseAtom] = [BaseAtom]()
    var isConstraintAdded: Bool = false
}

public class BaseImageView: UIImageView {
    func setImage(image: RtkImage?, completion:((UIImage)-> Void)? = nil) {
        if let image = image?.image {
            self.image = image.withRenderingMode(image.renderingMode)
            completion?(self.image ?? image)
        }else {
            if let url = image?.url {
              let result = ImageUtil.shared.obtainImageWithPath(url: url, completionHandler: { image, url in
                    self.image = image.withRenderingMode(image.renderingMode)
                   completion?(self.image ?? image)
               })
                if let image = result.0 {
                   self.image = image.withRenderingMode(image.renderingMode)
                   completion?(self.image ?? image)
               }
            }
        }
        
    }
}

protocol AutoLayoutable: UIView {
    var  isConstraintAdded:Bool {get}
    func createSubviews()
}

extension AutoLayoutable {
    
    func createSubviews() {
        
    }
}

protocol BaseAtom: AutoLayoutable{
        
}

protocol Molecule: AutoLayoutable {
    var atoms:[BaseAtom] {get}
}

public protocol AdaptableUI {
    var portraitConstraints: [NSLayoutConstraint] {get}
    var landscapeConstraints: [NSLayoutConstraint] {get}
    func applyConstraintAsPerOrientation(isLandscape:Bool, onPortait:()->Void, onLandscape:()->Void)
}

public extension AdaptableUI {
    func setOrientationContraintAsDeactive() {
        setPortraitContraintAsDeactive()
        setLandscapeContraintAsDeactive()
    }
    
    func setPortraitContraintAsDeactive() {
        portraitConstraints.forEach { $0.isActive = false}
    }
    func setLandscapeContraintAsDeactive() {
        landscapeConstraints.forEach { $0.isActive = false}
    }
    
    func applyConstraintAsPerOrientation() {
        applyConstraintAsPerOrientation(isLandscape: UIScreen.isLandscape())
    }
    
    func applyOnlyConstraintAsPerOrientation() {
        applyOnlyConstraintAsPerOrientation(isLandscape: UIScreen.isLandscape())
    }
    
    private func applyOnlyConstraintAsPerOrientation(isLandscape: Bool, onPortait:()->Void = {}, onLandscape:()->Void = {}) {
        if isLandscape {
           landscapeConstraints.forEach { $0.isActive = true }
           onLandscape()
       } else {
           portraitConstraints.forEach { $0.isActive = true }
           onPortait()
       }
    }
    
    func applyConstraintAsPerOrientation(isLandscape: Bool) {
        applyConstraintAsPerOrientation(isLandscape: isLandscape, onPortait: {}, onLandscape: {})
    }
    
    func applyConstraintAsPerOrientation(isLandscape: Bool, onPortait:()->Void = {}, onLandscape:()->Void = {}) {
        setOrientationContraintAsDeactive()
        applyOnlyConstraintAsPerOrientation(isLandscape: isLandscape, onPortait: onPortait, onLandscape: onLandscape)
    }
    
    func applyConstraintAsPerOrientation(onPortait:()->Void = {}, onLandscape:()->Void = {}) {
        applyConstraintAsPerOrientation(isLandscape: UIScreen.isLandscape(), onPortait: onPortait, onLandscape: onLandscape)
    }
    
    func isLandscape(size: CGSize) -> Bool {
        return size.width > size.height
    }
}

