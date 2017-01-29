//
//  Shiftable.swift
//  SwiftMine
//
//  Created by David Schwartz on 12/26/16.
//  Copyright © 2016 David Schwartz. All rights reserved.
//

import Foundation

protocol Shiftable {
    static func >>(lhs: Self, rhs: Self) -> Self
    static func <<(lhs: Self, rhs: Self) -> Self
}

extension UInt8: Shiftable {}
extension UInt16: Shiftable {}
extension UInt32: Shiftable {}
extension UInt64: Shiftable {}
