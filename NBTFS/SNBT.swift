//
//  SNBT.swift
//  SwiftMine
//
//  Created by David Schwartz on 12/29/16.
//  Copyright © 2016 David Schwartz. All rights reserved.
//

import Foundation

final class SNBT {
    private var fileURL: URL? = nil
    internal var fileContentsObject: Any? = nil
    internal var internalFileData: Data = Data()
    
    private var fileData: Data = Data()
    
    /**
     
     For initializing SNBT with the URL of a compressed
     
     */
    
    internal init(fileURL: URL) {
        self.fileURL = fileURL
        
        fileData = SNBT.decodeGzip(file: fileURL)
        internalFileData = fileData
        self.fileContentsObject = processTag()!.1
    }
    
    internal init(swiftObject: Any, saveURL: URL) {
        fileContentsObject = swiftObject
        fileURL = saveURL
        internalFileData = processObject(name: "", object: swiftObject)
        fileData = internalFileData
        SNBT.encodeGzip(file: saveURL,
                        data: fileData)
    }
    
    internal init(tag: Data) {
        self.fileData = tag
        self.fileContentsObject = processTag()?.1
    }
    
    /**
     
     A recursive function, which parses the fileData variable above
     
     - returns: The name and contents of the tag
     
     */
    
    private func processTag() -> (String, Any)? {
        
        /// Tag ID, always a single byte
        let ID: UInt8 = fileData.read(length: 1)
        
        // we don't want to be reading name lengths or anything if we see an END tag, just return with junk and nil
        
        guard ID != TagID.END.rawValue else {
            return nil
        }
        
        /// The tag's name length
        
        let nameLength: UInt16 = fileData.read(length: 2)
        
        /// the tag's name
        
        let name = String(bytes: fileData.subdata(in: 0..<Int(nameLength)), encoding: String.Encoding.utf8)!
        fileData.removeFirst(Int(nameLength))
        
        let resultObject: Any
        
        switch ID {
        case TagID.COMPOUND.rawValue:
            var compoundDict: Dictionary<String, Any> = [:]
            while true {
                if let subTag = processTag() {
                    compoundDict[subTag.0] = subTag.1
                } else {
                    break
                }
            }
            resultObject = compoundDict
        case TagID.BYTE.rawValue:
            resultObject = Int8(bitPattern: fileData.read(length: 1) as UInt8)
        case TagID.SHORT.rawValue:
            resultObject = Int16(bitPattern: fileData.read(length: 2) as UInt16)
        case TagID.INT.rawValue:
            resultObject = Int32(bitPattern: fileData.read(length: 4) as UInt32)
        case TagID.LONG.rawValue:
            resultObject = Int64(bitPattern: fileData.read(length: 8) as UInt64)
        case TagID.FLOAT.rawValue:
            resultObject = Float(bitPattern: fileData.read(length: 4) as UInt32)
        case TagID.DOUBLE.rawValue:
            resultObject = Double(bitPattern: fileData.read(length: 8) as UInt64)
        case TagID.BYTE_ARRAY.rawValue:
            let arrayLength: UInt32 = fileData.read(length: 4)
            let result = fileData[0..<Int(arrayLength)].map({Int8(bitPattern: $0)})
            fileData.removeFirst(Int(arrayLength))
            resultObject = result
        case TagID.STRING.rawValue:
            let stringLength: UInt16 = fileData.read(length: 2)
            let result = String(bytes: fileData[0..<Int(stringLength)], encoding: String.Encoding.utf8)
            fileData.removeFirst(Int(stringLength))
            resultObject = result!
        case TagID.LIST.rawValue:
            let listItemID: UInt8 = fileData.read(length: 1)
            let listLength: UInt32 = fileData.read(length: 4)
            var resultList: [Any] = []
            for _ in 0..<Int(listLength) {
                fileData.insert(contentsOf: [listItemID, 0x00, 0x00], at: 0)
                resultList += [processTag()!.1]
            }
            resultObject = resultList
        case TagID.INT_ARRAY.rawValue:
            let arrayLength: UInt32 = fileData.read(length: 4)
            var resultArray: [Int32] = []
            for _ in 0..<arrayLength {
                resultArray.append(Int32(bitPattern: fileData.read(length: 4) as UInt32))
            }
            resultObject = resultArray
        default:
            return nil
        }
        return (name, resultObject)
    }
    
    internal func processObject(name: String = "", object: Any) -> Data{
        
        var returnObject = Data()
        
        switch object {
        case is Dictionary<String, Any>:
            returnObject.append(nameToData(ID: TagID.COMPOUND, name: name))
            
            let object = object as! Dictionary<String, Any>
            for (name, value) in object {
                returnObject.append(processObject(name: name, object: value))
            }
            returnObject.append(TagID.END.rawValue)
        case is Int8:
            returnObject.append(nameToData(ID: TagID.BYTE, name: name))
            returnObject.push(value: UInt8(object as! Int8))
        case is Int16:
            returnObject.append(nameToData(ID: TagID.SHORT, name: name))
            returnObject.push(value: UInt16(bitPattern: object as! Int16))
        case is Int32:
            returnObject.append(nameToData(ID: TagID.INT, name: name))
            returnObject.push(value: UInt32(bitPattern: object as! Int32))
        case is Int64:
            returnObject.append(nameToData(ID: TagID.LONG, name: name))
            returnObject.push(value: UInt64(bitPattern: object as! Int64))
        case is Int:
            if MemoryLayout<Int>.size == 8 {
                returnObject.append(processObject(name: name, object: Int64(object as! Int)))
            } else {
                returnObject.append(processObject(name: name, object: Int32(object as! Int)))
            }
        case is Float:
            returnObject.append(nameToData(ID: TagID.FLOAT, name: name))
            returnObject.push(value: (object as! Float).bitPattern)
        case is Double:
            returnObject.append(nameToData(ID: TagID.DOUBLE, name: name))
            returnObject.push(value: (object as! Double).bitPattern)
        case is [Int8]:
            let object = object as! [Int8]
            returnObject.append(nameToData(ID: TagID.INT_ARRAY, name: name))
            returnObject.push(value: UInt32(object.count))
            for item in object {
                returnObject.push(value: UInt8(bitPattern: item))
            }
        case is String:
            let object = object as! String
            returnObject.append(nameToData(ID: TagID.STRING, name: name))
            returnObject.push(value: UInt16(object.lengthOfBytes(using: String.Encoding.utf8)))
            if object.lengthOfBytes(using: String.Encoding.utf8) != 0{
                returnObject.push(value: Array(Array((object.cString(using: String.Encoding.utf8)! as [Int8]).map({UInt8(bitPattern: $0)})).dropLast()))
            }
        case is [Int32]:
            let object = object as! [Int32]
            returnObject.append(nameToData(ID: TagID.INT_ARRAY, name: name))
            returnObject.push(value: UInt32(bitPattern: Int32(object.count)))
            for i in object {
                returnObject.push(value: UInt32(bitPattern: i))
            }
        case is [Any]:
            let object = object as! [Any]
            returnObject.append(nameToData(ID: TagID.LIST, name: name))
            if object.count == 0 {
                returnObject.push(value: TagID.END.rawValue)
            } else {
                returnObject.push(value: tagIDForObject(object: object[0]))
            }
            returnObject.push(value: UInt32(object.count))
            for item in object {
                returnObject.append(Data(processObject(name: "", object: item).dropFirst(3)))
            }
        default:
            break
        }
        return returnObject
    }
    
    internal func tagIDForObject(object: Any) -> UInt8 {
        switch object {
        case is Dictionary<String, Any>:
            return TagID.COMPOUND.rawValue
        case is Int8:
            return TagID.BYTE.rawValue
        case is Int16:
            return TagID.SHORT.rawValue
        case is Int32:
            return TagID.INT.rawValue
        case is Int64:
            return TagID.LONG.rawValue
        case is Float32:
            return TagID.FLOAT.rawValue
        case is Double:
            return TagID.DOUBLE.rawValue
        case is [Int8]:
            return TagID.BYTE_ARRAY.rawValue
        case is String:
            return TagID.STRING.rawValue
        case is [Int32]:
            return TagID.INT_ARRAY.rawValue
        case is [Any]:
            return TagID.LIST.rawValue
        default:
            return TagID.END.rawValue
        }
    }
    
    private func nameToData(ID: TagID, name: String) -> Data {
        var nameData = Data()
        nameData.push(value: ID.rawValue)
        nameData.push(value: UInt16(name.characters.count))
        
        if name.characters.count > 0 {
            nameData.push(value: Array((name.cString(using: String.Encoding.utf8)! as [Int8]).map({UInt8(bitPattern: $0)}).dropLast()))
        }
        return nameData
    }
    
    internal func save(toURL fileURL: URL) {
        SNBT.encodeGzip(file: fileURL, data: self.processObject(name: "", object: self.fileContentsObject!))
    }
    
    /**
     
     Decode gzip file using zlib library
     
     - parameter file: location of dzip file to decode
     
     - returns: file's decoded data
     
     */
    
    static func decodeGzip(file: URL) -> Data {
        if FileManager.default.fileExists(atPath: file.path) {
            // Gzip files always start with these two bytes, so check for them first
            if Array(try! Data(contentsOf: file)[0..<2]) == [0x1f, 0x8b] {
                let buffer = malloc(10 * 1024 * 1024)
                defer {free(buffer)}
                let openFile = gzopen(file.path, "r")
                let readBytes = gzread(openFile, buffer, 10 * 1024 * 1024)
                gzclose(openFile)
                return Data(bytes: buffer!, count: Int(readBytes))
            } else {
                return try! Data(contentsOf: file)
            }
        }
        return Data()
    }
    
    /**
     
     Encode gzip file using zlib library
     
     - parameter file: location of gzip file to decode
     - parameter data: the data to encode
     
     */
    
    static func encodeGzip(file: URL, data: Data) {
        let openFile = gzopen(file.path, "w")
        gzsetparams(openFile, 1, Z_DEFAULT_STRATEGY)
        gzwrite(openFile, Array(data), UInt32(data.count))
        gzclose(openFile)
    }
}
