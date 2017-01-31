//
//  NBTFS.swift
//  NBTFS
//
//  Created by David Schwartz on 1/28/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Foundation

class NBTFS: NSObject {
    static let privateInstance = NBTFS()
    static let main = GMUserFileSystem(delegate: privateInstance, isThreadSafe: true)
    
    let NBTFile = SNBT(fileURL: URL(fileURLWithPath: ProcessInfo.processInfo.arguments[1]))
    
    var cache: [String: Data] = [:]
    
    let cacheUpdateQueue = DispatchQueue(label: "cacheUpdateQueue")
    
    override func openFile(atPath path: String!, mode: Int32, userData: AutoreleasingUnsafeMutablePointer<AnyObject?>!) throws {
        throw POSIXError(.EPERM)
    }
    
    override func createFile(atPath path: String!, attributes: [AnyHashable : Any]! = [:], flags: Int32, userData: AutoreleasingUnsafeMutablePointer<AnyObject?>!) throws {
        throw POSIXError(.EPERM)
    }
    
    override func removeDirectory(atPath path: String!) throws {
        throw POSIXError(.EPERM)
    }
    
    
    override func createDirectory(atPath path: String!, attributes: [AnyHashable : Any]! = [:]) throws {
        throw POSIXError(.EPERM)
    }
    
    override func value(ofExtendedAttribute name: String!, ofItemAtPath path: String!, position: off_t) throws -> Data {
        return Data([0xff, 0xff])
    }
    
    override func extendedAttributesOfItem(atPath path: Any!) throws -> [Any] {
        return ["com.apple.FinderInfo"]
    }
    
    override func attributesOfItem(atPath path: String!, userData: Any!) throws -> [AnyHashable : Any] {
        
        if path == "/" || path.hasSuffix(".list_int8") || path.hasSuffix("list_int32") || path.hasSuffix("list_any") || path.hasSuffix("compound") {
            return [FileAttributeKey.type: FileAttributeType.typeDirectory]
        } else if path.hasSuffix(".txt") {
            return [FileAttributeKey.type: FileAttributeType.typeRegular]
        } else {
            throw POSIXError(.ENOENT)
        }
    }
    
    override func contents(atPath path: String!) -> Data! {
        if let cachedObject = cache[path] {
            return cachedObject
        }
        
        let pathURL = URL(fileURLWithPath: path)
        
        var currentItem: Any? = self.NBTFile.fileContentsObject
        
        for component in pathURL.pathComponents {
            if component == "/" { continue }
            if currentItem as? [String: Any] != nil {
                currentItem = (currentItem as! [String: Any])[removeSuffix(fromString: component)]
            } else if currentItem as? [Any] != nil {
                currentItem = (currentItem as! [Any])[Int(removeSuffix(fromString: component))!]
            }
        }
        
        self.cache[path] = String(describing: currentItem!).data(using: String.Encoding.utf8)!
        
        return String(describing: currentItem!).data(using: String.Encoding.utf8)!
    }
    
    override func contentsOfDirectory(atPath path: String!) throws -> [Any] {
        let pathURL = URL(fileURLWithPath: path)
        
        var currentItem: Any? = self.NBTFile.fileContentsObject
        
        for component in pathURL.pathComponents {
            if currentItem as? [String: Any] != nil {
                currentItem = (currentItem as! [String: Any])
                if component != "/" {
                    currentItem = (currentItem as! [String: Any])[removeSuffix(fromString: component)]
                }
                continue
            } else if currentItem as? [Any] != nil {
                currentItem = (currentItem as! [Any])[Int(removeSuffix(fromString: component))!]
            }
        }
        
        return handleObject(currentItem!)
    }
    
    private func handleObject(_ object: Any) -> [String] {
        switch type(of: object) {
        case is [String: Any].Type:
            return (object as! [String: Any]).map({ (key: String, value: Any) -> String in
                switch type(of: value){
                case is Int8.Type:
                    return key.appending(".int8.txt")
                case is Int16.Type:
                    return key.appending(".int16.txt")
                case is Int32.Type:
                    return key.appending(".int32.txt")
                case is Int64.Type:
                    return key.appending(".int64.txt")
                case is Float.Type:
                    return key.appending(".float.txt")
                case is Double.Type:
                    return key.appending(".double.txt")
                case is String.Type:
                    return key.appending(".string.txt")
                case is [Int8].Type:
                    return key.appending(".list_int8")
                case is [Int32].Type:
                    return key.appending(".list_int32")
                case is [Any].Type:
                    return key.appending(".list_any")
                case is [String: Any].Type:
                    return key.appending(".compound")
                default:
                    return key
                }
            })
        case is [Any].Type:
            return stride(from: 0, to: (object as! [Any]).count, by: 1).map({ (key) -> String in
                let value = (object as! [Any])[key]
                switch type(of: value){
                case is Int8.Type:
                    return String(describing: key).appending(".int8.txt")
                case is Int16.Type:
                    return String(describing: key).appending(".int16.txt")
                case is Int32.Type:
                    return String(describing: key).appending(".int32.txt")
                case is Int64.Type:
                    return String(describing: key).appending(".int64.txt")
                case is Float.Type:
                    return String(describing: key).appending(".float.txt")
                case is Double.Type:
                    return String(describing: key).appending(".double.txt")
                case is String.Type:
                    return String(describing: key).appending(".string.txt")
                case is [Int8].Type:
                    return String(describing: key).appending(".list_int8")
                case is [Int32].Type:
                    return String(describing: key).appending(".list_int32")
                case is [Any].Type:
                    return String(describing: key).appending(".list_any")
                case is [String: Any].Type:
                    return String(describing: key).appending(".compound")
                default:
                    return String(describing: key)
                }
            })
        default:
            return [String(describing: object)]
        }
    }
    
    private func removeSuffix(fromString string: String) -> String {
        if string.hasSuffix(".int8.txt") {
            return string.replacingOccurrences(of: ".int8.txt", with: "")
        } else if string.hasSuffix(".int16.txt") {
            return string.replacingOccurrences(of: ".int16.txt", with: "")
        } else if string.hasSuffix(".int32.txt") {
            return string.replacingOccurrences(of: ".int32.txt", with: "")
        } else if string.hasSuffix(".int64.txt") {
            return string.replacingOccurrences(of: ".int64.txt", with: "")
        } else if string.hasSuffix(".float.txt") {
            return string.replacingOccurrences(of: ".float.txt", with: "")
        } else if string.hasSuffix(".double.txt") {
            return string.replacingOccurrences(of: ".double.txt", with: "")
        } else if string.hasSuffix(".compound") {
            return string.replacingOccurrences(of: ".compound", with: "")
        } else if string.hasSuffix(".string.txt") {
            return string.replacingOccurrences(of: ".string.txt", with: "")
        } else if string.hasSuffix(".list_int8") {
            return string.replacingOccurrences(of: ".list_int8", with: "")
        } else if string.hasSuffix(".list_int32") {
            return string.replacingOccurrences(of: ".list_int32", with: "")
        } else if string.hasSuffix(".list_any") {
            return string.replacingOccurrences(of: ".list_any", with: "")
        }
        
        return string
    }
    
    internal func dumpNBT() -> Any {
        return self.NBTFile.fileContentsObject!
    }
}
