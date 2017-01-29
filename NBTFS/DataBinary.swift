//
//  DataBinary.swift
//  SwiftMine
//
//  Created by David Schwartz on 12/21/16.
//  Copyright © 2016 David Schwartz. All rights reserved.
//

import Foundation
import simd

extension Data {
    
    /**
     
     Reads either 1, 2, 4 or 8 bytes from the Data object, and returns an unsigned integer of the appropriate type
     
     - parameter length: The length of the type you want to read
     
     - returns: An unsigned integer, of the appropriate length
     
     */
    
    mutating func read<T>(length: Int) -> T {
        let value = Array(self[0..<length]).withUnsafeBytes { (byte) -> Any in
            switch length {
            case 1:
                return byte.load(as: UInt8.self)
            case 2:
                return byte.load(as: UInt16.self).bigEndian
            case 4:
                return byte.load(as: UInt32.self).bigEndian
            case 8:
                return byte.load(as: UInt64.self).bigEndian
            default:
                return 0
            }
        }
        
        self.removeFirst(length)
        
        return value as! T
    }
    
    /**
     
     Allows you to push any unsigned integer onto the stack
     
     - parameter value: An unsigned integer
     
     */
    
    mutating func push<T>(value: T) where T:Shiftable, T:BitwiseOperations, T:UnsignedInteger {
        self.append(contentsOf: stride(from: MemoryLayout.size(ofValue: value) * 8 , to: 7, by: -8).map({ (i: Int) -> UInt8 in
            return UInt8(((value >> (T(UIntMax(i)) as T - T(8))) & T(0xff)).toUIntMax())
        }))
    }
    
    /**
     
     Allows you to push a list of 8-bit unsigned integer onto the stack
     
     - parameter value: A list of unsigned integers
     
     */
    
    mutating func push(value: [UInt8]) {
        self.append(contentsOf: value)
    }
    
    /**
     
     Allows you to push any floating point number onto the stack
     
     - parameter value: A floating point number
     
     */
    
    mutating func push(value: Float32) {
        push(value: value.bitPattern.bigEndian)
    }
    
    /**
     
     Allows you to push any double-precision floating point number onto the stack
     
     - parameter value: A double-precision floating point number
     
     */
    
    mutating func push(value: Float64) {
        push(value: value.bitPattern.bigEndian)
    }
    
    /**
     
     Allows you to push a vector_float3 (or a float3) onto the stack
     
     - parameter value: A vector_float3
     
     */
    
    mutating func push(value: vector_float3) {
        push(value: value.x)
        push(value: value.y)
        push(value: value.z)
    }
}
