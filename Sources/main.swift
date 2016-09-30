// Copyright 2016 Will Field-Thompson

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//     http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

fileprivate let cmd = CommandLine.arguments[0]

func usage() {
    print("USAGE: \(cmd) OUTPUT_DIR [INTERVAL]")
    print("INTERVAL is in seconds and defaults to 20 minutes.")
}

func main() throws {
    guard 2...3 ~= CommandLine.arguments.count else {
        print("\(cmd) needs an output directory.")
        usage()
        exit(1)
    }
    
    let outputDir = CommandLine.arguments[1]
    let mgr = FileManager.default
    var isdir: ObjCBool = false
    let exists = mgr.fileExists(atPath: outputDir, isDirectory: &isdir)
    guard isdir.boolValue || !exists else {
        print("\(cmd) needs an output directory. \(outputDir) is not one.")
        usage()
        exit(1)
    }

    let interval: UInt32
    if CommandLine.arguments.count > 2 {
        guard let i = UInt32(CommandLine.arguments[2]) else {
            print("\(CommandLine.arguments[2]) is not a number of seconds.")
            usage()
            exit(1)
        }
        interval = i
    } else {
        interval = 20 * 60 // default to 20 minutes
    }
    
    if !exists {
        // Create the output directory if it doesn't exist.
        try mgr.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
    }

    let output = URL(fileURLWithPath: outputDir)

    repeat {
        let start = Date()
        testConnection {
            log(result: $0, toDirectory: output)
        }
        let elapsed = Date().timeIntervalSince(start)

        print("\(start): tests took a combined \(elapsed) seconds")
        
        if UInt32(elapsed) < interval {
            // protect against underflow
            sleep(interval - UInt32(elapsed))
        }
    } while true
}

try main()
