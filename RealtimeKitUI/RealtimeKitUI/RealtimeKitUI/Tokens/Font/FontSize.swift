//
//  FontSize.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 22/11/22.
//

import UIKit

struct FontToken {
    
    public let size300: CGFloat
    public let size250: CGFloat
    public let size200: CGFloat
    public let size150: CGFloat
    public let size125: CGFloat
    public let size100: CGFloat
    public let size88: CGFloat
    public let size75: CGFloat
    
    init(base: CGFloat = 16) {
        size300 = 3.0 * base
        size250 = 2.5 * base
        size200 = 2.0 * base
        size150 = 1.5 * base
        size125 = 1.25 * base
        size100 = 1.0 * base
        size88 = 0.875 * base
        size75 = 0.75 * base
    }
}
