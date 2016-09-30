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

func usage() {
    let cmd = CommandLine.arguments[0]
    print("\(cmd) OUTPUT_DIR")
}

func main() throws {
    let cmd = CommandLine.arguments[0]
    guard CommandLine.arguments.count == 2 else {
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
    if !exists {
        print("Creating \(outputDir) ")
        try mgr.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
    }

    let output = URL(fileURLWithPath: outputDir)

    let complete = DispatchSemaphore(value: 0)
    
    testConnection {
        log(result: $0, toDirectory: output)
        complete.signal()
    }

    complete.wait()
}

try main()
