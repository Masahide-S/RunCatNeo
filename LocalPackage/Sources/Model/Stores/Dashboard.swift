/*
 Dashboard.swift
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

import DataSource
import Foundation
import Observation
import SystemInfoKit

@MainActor @Observable
public final class Dashboard: Composable {
    private let appStateClient: AppStateClient
    private let nsAppClient: NSAppClient
    private let logService: LogService

    @ObservationIgnored private var task: Task<Void, Never>?

    public var systemInfoBundle: SystemInfoBundle
    public var cpuRingBuffer: RingBuffer
    public var memoryRingBuffer: RingBuffer
    public let isPreview: Bool
    public let action: (Action) async -> Void

    public init(
        _ appDependencies: AppDependencies,
        systemInfoBundle: SystemInfoBundle = .cpuZero(),
        cpuRingBuffer: RingBuffer = .init(),
        memoryRingBuffer: RingBuffer = .init(),
        isPreview: Bool? = nil,
        action: @escaping (Action) async -> Void =  { _ in }
    ) {
        self.appStateClient = appDependencies.appStateClient
        self.nsAppClient = appDependencies.nsAppClient
        self.logService = .init(appDependencies)
        self.systemInfoBundle = systemInfoBundle
        self.cpuRingBuffer = cpuRingBuffer
        self.memoryRingBuffer = memoryRingBuffer
        self.isPreview = isPreview ?? ProcessInfo.isPreview
        self.action = action
    }

    public func reduce(_ action: Action) async {
        switch action {
        case let .task(screenName):
            logService.notice(.screenView(name: screenName))
            task = Task { [weak self, appStateClient] in
                let stream = appStateClient.withLock(\.metricsStreamBundle).stream
                for await value in stream {
                    self?.updateMetrics(value)
                }
            }

        case .onDisappear:
            task?.cancel()

        case .settingsButtonTapped:
            nsAppClient.activate(true)

        case .aboutButtonTapped:
            nsAppClient.activate(true)
            nsAppClient.orderFrontStandardAboutPanel([:])

        case .quitButtonTapped:
            nsAppClient.terminate(nil)
        }
    }

    private func updateMetrics(_ metrics: Metrics) {
        systemInfoBundle = metrics.systemInfoBundle
        cpuRingBuffer = metrics.cpuRingBuffer
        memoryRingBuffer = metrics.memoryRingBuffer
    }

    public enum Action: Sendable {
        case task(String)
        case onDisappear
        case settingsButtonTapped
        case aboutButtonTapped
        case quitButtonTapped
    }
}
