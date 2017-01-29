//
//  main.swift
//  NBTFS
//
//  Created by David Schwartz on 1/27/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Foundation

if ProcessInfo.processInfo.arguments.count == 2 && FileManager.default.fileExists(atPath: ProcessInfo.processInfo.arguments[1]) {
    NBTFS.main!.mount(atPath: URL(fileURLWithPath: ProcessInfo.processInfo.arguments[1]).path.appending("_mount"),
                      withOptions: [
                        "volname=\(URL(fileURLWithPath: ProcessInfo.processInfo.arguments[1]).lastPathComponent)",
                        "fstypename=NBTFS"],
                      shouldForeground: true,
                      detachNewThread: false
    )
} else {
    print("Please specify an existing NBT file")
}
