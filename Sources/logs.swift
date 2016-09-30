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

fileprivate struct LogQueues {
    private static let internalQueue = DispatchQueue(label: "LogQueues.fetch")
    private static var qs: [URL : DispatchQueue] = [:]
    
    static func get(_ url: URL) -> DispatchQueue {
        return internalQueue.sync {
            if let q = qs[url] { return q }
            let q = DispatchQueue(label: "LogQueues.\(url)")
            qs[url] = q
            return q
        }
    }
}

fileprivate extension String {
    func append(to url: URL,
                allowLossyConversion lossy: Bool = false,
                encoding enc: String.Encoding = .utf8) {
        guard let dat = data(using: enc, allowLossyConversion: lossy) else {
            preconditionFailure("Couldn't convert \(self.debugDescription) to data.")
        }
        let q = LogQueues.get(url)
        q.async {
            let handle = try! FileHandle(forWritingTo: url)
            defer { handle.closeFile() }
            handle.seekToEndOfFile()
            handle.write(dat)
        }
    }
}

/// Map from a web URL to a logfile url
func logfile(outputDirectory: URL, host: URL) -> URL {
    // Log separated by host.
    guard let hostName = host.host else {
        preconditionFailure("Host URL \(host) does not have a host.")
    }
    return outputDirectory
      .appendingPathComponent(hostName)
      .appendingPathExtension("log")
}

/// Append the test result to the appropriate logfile in the directory.
func log(result: TestResult, toDirectory dir: URL) {
    let file = logfile(outputDirectory: dir, host: result.location)
    let mgr = FileManager.default
    if !mgr.fileExists(atPath: file.path) {
        let headings = ["RESULT", "CODE",
                        "URL", "BYTES",
                        "DURATION", "TIMESTAMP"].joined(separator: "\t") + "\n"
        try! headings.write(to: file, atomically: false, encoding: .utf8)
    }
    let now = Date()
    let fields: [Any]
    switch result.connection {
    case .connected(let status, let bytes):
        fields = ["CONNECT", status, result.location, bytes, result.duration, now]
    case .failed(let error):
        let err = error as NSError
        fields = ["FAILED", err.code, result.location, "NONE", result.duration, now]
    }
    let line = fields.map({ "\($0)" }).joined(separator: "\t") + "\n"
    line.append(to: file)
}
