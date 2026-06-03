/*
 Runner.swift
 DataSource

 Created by Takuto Nakamura on 2026/05/09.
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

import Foundation

public struct Runner: Sendable, Hashable, Identifiable, Codable {
    public var id: String
    public var name: String
    public var isCustom: Bool
    public var isTemplate: Bool
    public var frameOrder: FrameOrder

    public init(id: String, name: String, isTemplate: Bool, frameOrder: FrameOrder) {
        self.id = id
        self.name = name
        self.isCustom = true
        self.isTemplate = isTemplate
        self.frameOrder = frameOrder
    }

    public init(kind: RunnerKind) {
        id = kind.id
        name = kind.localizedName
        isCustom = false
        isTemplate = true
        frameOrder = kind.frameOrder
    }

    public func resourceNames() -> [String] {
        frameOrder.order.map { n in
            if isCustom {
                "frame-\(n)"
            } else {
                "\(id)-frame-\(n)"
            }
        }
    }

    public static let `default` = Runner(kind: .cat)

    // MARK: Equatable
    public static func ==(lhs: Runner, rhs: Runner) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
