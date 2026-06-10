/*
 DonationSettings.swift
 Model

 Created by Takuto Nakamura on 2026/06/08.
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
import Observation
import StoreKit
import SwiftUI

@MainActor @Observable
public final class DonationSettings: Composable {
    private let logService: LogService

    public var subscriptionGroupID: String
    public var isSubscribed: Bool
    public var didCompleteOneTimeDonation: Bool
    public var showingAlert: Bool
    public var error: StoreKitError?
    public let action: (Action) async -> Void

    public init(
        _ appDependencies: AppDependencies,
        subscriptionGroupID: String? = nil,
        isSubscribed: Bool = false,
        didCompleteOneTimeDonation: Bool = false,
        showingAlert: Bool = false,
        error: StoreKitError? = nil,
        action: @escaping (Action) async -> Void = { _ in }
    ) {
        self.logService = .init(appDependencies)
        self.subscriptionGroupID = subscriptionGroupID ?? appDependencies.appStateClient.withLock(\.subscriptionGroupID)
        self.isSubscribed = isSubscribed
        self.didCompleteOneTimeDonation = didCompleteOneTimeDonation
        self.showingAlert = showingAlert
        self.error = error
        self.action = action
    }

    public func reduce(_ action: Action) async {
        switch action {
        case let .task(screenName):
            logService.notice(.screenView(name: screenName))

        case .restoreSubscriptionButtonTapped:
            do {
                try await AppStore.sync()
            } catch {
                handle(error)
            }

        case let .onReceiveProductTaskState(taskState):
            if case let .failure(error) = taskState {
                handle(error)
            }
        }
    }

    private func handle(_ error: any Error) {
        if let error = error as? StoreKitError {
            switch error {
            case .userCancelled:
                return
            default:
                self.error = error
                showingAlert = true
            }
        } else {
            logService.error(.donationFailed(error))
        }
    }

    public enum Action: Sendable {
        case task(String)
        case restoreSubscriptionButtonTapped
        case onReceiveProductTaskState(Product.CollectionTaskState)
    }
}
