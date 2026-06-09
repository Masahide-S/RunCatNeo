/*
 DonationSettingsView.swift
 UserInterface

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
import Model
import StoreKit
import SwiftUI

struct DonationSettingsView: View {
    @StateObject var store: DonationSettings

    var body: some View {
        Form {
            Section {
                Label {
                    Text("donationIntro", bundle: .module)
                } icon: {
                    Image(systemName: "pawprint.fill")
                }
            }
            Section {
                ProductView(id: DonationProduct.oneTime.id, prefersPromotionalIcon: true) {
                    Image(systemName: "mug.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                        .productIconBorder()
                }
                .tint(.accentColor)
            } header: {
                Text("oneTimeDonation", bundle: .module)
            } footer: {
                if store.didCompleteOneTimeDonation {
                    Text("thankYouDonation", bundle: .module)
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                ProductView(id: DonationProduct.yearly.id, prefersPromotionalIcon: true) {
                    Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                        .productIconBorder()
                }
                .subscriptionStatusTask(for: store.subscriptionGroupID) { taskState in
                    store.isSubscribed = taskState.value?.map(\.state)
                        .contains { [.subscribed, .inGracePeriod].contains($0) } == true
                }
                .tint(.accentColor)
            } header: {
                Text("continuousSupport", bundle: .module)
            } footer: {
                HStack(alignment: .firstTextBaseline) {
                    if store.isSubscribed {
                        Text("thankYouSupporting", bundle: .module)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        if store.isSubscribed {
                            TintedButton(labelKey: "manageSubscription") {
                                await store.send(.linkButtonTapped(URL.manageSubscriptions))
                            }
                        } else {
                            TintedButton(labelKey: "restoreSubscription") {
                                await store.send(.restoreSubscriptionButtonTapped)
                            }
                        }
                        TintedButton(labelKey: "termsOfService") {
                            await store.send(.linkButtonTapped(URL.termsOfService))
                        }
                        TintedButton(labelKey: "privacyPolicy") {
                            await store.send(.linkButtonTapped(URL.privacyPolicy))
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .alert(
            isPresented: $store.showingAlert,
            error: store.error,
            actions: { _ in },
            message: { _ in }
        )
        .task {
            await store.send(.task(String(describing: Self.self)))
        }
        .storeProductsTask(for: DonationProduct.allCases.map(\.id)) { taskState in
            await store.send(.onReceiveProductTaskState(taskState))
        }
    }
}

extension DonationSettings: ObservableObject {}

private struct TintedButton: View {
    var labelKey: LocalizedStringKey
    var action: () async -> Void

    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            Text(labelKey, bundle: .module)
        }
        .buttonStyle(.borderless)
        .textScale(.secondary)
        .tint(Color.accentColor)
    }
}
