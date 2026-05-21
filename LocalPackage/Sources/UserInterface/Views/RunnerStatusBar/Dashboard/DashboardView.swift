/*
 DashboardView.swift
 UserInterface

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

import Model
import SwiftUI

struct DashboardView: View {
    @Environment(\.appDependencies) private var appDependencies
    @StateObject var store: Dashboard

    var body: some View {
        VStack(spacing: 8) {
            SystemInfoStackView(
                systemInfoBundle: store.systemInfoBundle,
                cpuRingBuffer: store.cpuRingBuffer,
                memoryRingBuffer: store.memoryRingBuffer,
                isPreview: store.isPreview
            )
            HStack(spacing: 8) {
                SettingsLink {
                    Label {
                        Text("settings", bundle: .module)
                    } icon: {
                        Image(systemName: "gear")
                    }
                    .labelStyle(.iconOnly)
                }
                .buttonStyle(.preAction {
                    await store.send(.settingsButtonTapped)
                })
                .accessibilityIdentifier("open_settings")

                Button {
                    Task {
                        await store.send(.aboutButtonTapped)
                    }
                } label: {
                    Label {
                        Text("aboutApp", bundle: .module)
                    } icon: {
                        Image(systemName: "info")
                    }
                    .labelStyle(.iconOnly)
                }
                .accessibilityIdentifier("about_app")

                Button {
                    Task {
                        await store.send(.quitButtonTapped)
                    }
                } label: {
                    Label {
                        Text("quitApp", bundle: .module)
                    } icon: {
                        Image(systemName: "hand.wave")
                    }
                    .labelStyle(.iconOnly)
                }
                .accessibilityIdentifier("terminate_app")
            }
        }
        .fixedSize()
        .task {
            await store.send(.task(String(describing: Self.self)))
        }
        .onDisappear {
            Task {
                await store.send(.onDisappear)
            }
        }
    }
}

extension Dashboard: ObservableObject {}

#Preview {
    DashboardView(store: .init(.testDependencies()))
}
