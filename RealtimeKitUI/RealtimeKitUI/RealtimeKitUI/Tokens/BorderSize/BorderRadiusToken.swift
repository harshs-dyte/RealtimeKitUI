//
//  BorderRadius.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 24/11/22.
//

import Foundation

public class BorderRadiusToken {
   
    public enum RadiusType: String {
        case sharp
        case rounded
        case extrarounded
        case circular
    }

    public  enum Size: String {
        case zero
        case one
        case two
        case three
    }
    
    private let roundFactor: CGFloat
    private let extraRoundFactor: CGFloat
    private let circularFactor: CGFloat
    
    init(roundFactor: CGFloat = 4.0, extraRoundFactor: CGFloat = 8.0, circularFactor: CGFloat = 8.0) {
        self.roundFactor = roundFactor
        self.extraRoundFactor = extraRoundFactor
        self.circularFactor = circularFactor
    }
    
    public func getRadius(size: Size, radius: RadiusType) -> CGFloat {
        if size == .zero || radius == .sharp {
            return 0
        }
        if radius == .rounded {
            return getRadiusForRounded(size: size)
        }else if radius == .extrarounded {
            return getRadiusForExtraRounded(size: size)
        }else if radius == .circular {
            return getRadiusForCircular(size: size)
        }
        return 0.0
    }
}

extension BorderRadiusToken {
   private func getRadiusForRounded(size: Size) -> CGFloat {
       switch size {
       case .zero:
           return 0.0 * roundFactor
       case .one:
           return 1.0 * roundFactor
       case .two:
           return 2.0 * roundFactor
       case .three:
           return 4.0 * roundFactor
       }
   }
}

extension BorderRadiusToken {
    private func getRadiusForExtraRounded(size: Size) -> CGFloat {
        switch size {
        case .zero:
            return 0.0 * extraRoundFactor
        case .one:
            return 1.0 * extraRoundFactor
        case .two:
            return 2.0 * extraRoundFactor
        case .three:
            return 4.0 * extraRoundFactor
        }
   }
}

extension BorderRadiusToken {
    private func getRadiusForCircular(size: Size) -> CGFloat {
        switch size {
        case .zero:
            return 0.0 * circularFactor
        case .one:
            return 999
        case .two:
            return 3.0 * circularFactor
        case .three:
            return 4.0 * circularFactor
        }
   }
}
