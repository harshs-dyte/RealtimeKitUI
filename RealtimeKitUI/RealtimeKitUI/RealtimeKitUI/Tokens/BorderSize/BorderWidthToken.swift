//
//  BorderWidthToken.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/11/22.
//

import Foundation

public class BorderWidthToken {
   
    public enum Width: String {
        case none
        case thin
        case fat
    }

    enum Size: String {
        case zero
        case one
        case two
        case three
    }
    
    private var thinFactor = 1.0
    private var fatFactor = 2.0
    
    
    init(thinFactor: CGFloat = 1.0, fatFactor: CGFloat = 2.0) {
        self.thinFactor = thinFactor
        self.fatFactor = fatFactor
    }
    
    func getWidth(size: Size, width: Width) -> CGFloat {
        if size == .zero || width == .none {
            return 0
        }
        if width == .thin {
            return getSizeForThinWidth(size: size)
        }else if width == .fat {
            return getSizeForFatWidht(size: size)
        }
        return 0.0
    }
}

extension BorderWidthToken {
   private func getSizeForThinWidth(size: Size) -> CGFloat {
        switch size {
        case .zero:
            return 0.0 * thinFactor
        case .one:
            return 1.0 * thinFactor
        case .two:
            return 2.0 * thinFactor
        case .three:
            return 4.0 * thinFactor
        }
   }
}

extension BorderWidthToken {
    private func getSizeForFatWidht(size: Size) -> CGFloat {
        switch size {
        case .zero:
            return 0.0 * fatFactor
        case .one:
            return 1.0 * fatFactor
        case .two:
            return 2.0 * fatFactor
        case .three:
            return 4.0 * fatFactor
        }
   }
}
