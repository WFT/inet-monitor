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

enum ConnectionResult {
    case connected(status: Int, bytes: Int)
    case failed(error: Error)
}

/// A result of a test to `location` returned `connection`.
typealias TestResult = (location: URL,
                        connection: ConnectionResult,
                        duration: TimeInterval)

/// `checkComplete` is called for every URL tested.
func testConnection(checkComplete: @escaping (TestResult) -> ()) {
    let sesh = URLSession.shared
    let urls = [
      "http://www.google.com/",
      "http://www.github.com/",
      "http://www.apple.com/",
      "http://www.cloudflare.com/",
      "http://www.nytimes.com/"
    ].map({ URL(string: $0)! })

    let group = DispatchGroup()
    
    for u in urls {
        let start = Date()
        let task = sesh.dataTask(with: u) { data, response, error in
            defer { group.leave() }
            let end = Date()
            let dur = end.timeIntervalSince(start)
            guard let response = response as? HTTPURLResponse,
                  let data = data else {
                checkComplete((u, .failed(error: error!), dur))
                return
            }
            checkComplete((u,
                           .connected(status: response.statusCode,
                                      bytes: data.count),
                           dur))
        }
        group.enter()
        task.resume()
    }
    group.wait()
}
