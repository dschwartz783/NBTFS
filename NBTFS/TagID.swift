//
//  TagIDs.swift
//  SwiftMine
//
//  Created by David Schwartz on 12/29/16.
//  Copyright © 2016 David Schwartz. All rights reserved.
//

import Foundation

enum TagID: UInt8 {
    case END
    case BYTE
    case SHORT
    case INT
    case LONG
    case FLOAT
    case DOUBLE
    case BYTE_ARRAY
    case STRING
    case LIST
    case COMPOUND
    case INT_ARRAY
}
