/*
 StatusBarAppearanceBridge.swift
 Model

 Created by Takuto Nakamura on 2026/05/08.
 Copyright 2026 Koyme22 (Takuto Nakamura)

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import AppKit
import DataSource
import Synchronization

public final class StatusBarAppearanceBridge: Sendable {
    public static let shared = StatusBarAppearanceBridge()

    private let streamBundle = AsyncStreamBundle<NSAppearance>()
    private let lastAppearance = Mutex<NSAppearance?>(nil)

    public var stream: AsyncStream<NSAppearance> {
        streamBundle.stream
    }

    public func send(_ appearance: NSAppearance) {
        guard lastAppearance.withLock(\.self) != appearance else { return }
        lastAppearance.withLock { $0 = appearance }
        streamBundle.send(appearance)
    }
}

extension NSAppearance: @retroactive @unchecked Sendable {}
