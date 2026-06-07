/*
 GeneralSettingsView.swift
 UserInterface

 Created by Takuto Nakamura on 2026/05/23.
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
import SwiftUI

struct GeneralSettingsView: View {
    @StateObject var store: GeneralSettings

    var body: some View {
        Form {
            Section {
                Picker(selection: Binding<Runner?>(
                    get: { store.currentRunner },
                    asyncSet: { await store.send(.selectRunner($0)) }
                )) {
                    ForEach(store.runnerBundleList, id: \.runner) { runnerBundle in
                        Label {
                            Text(runnerBundle.runner.name)
                        } icon: {
                            runnerBundle.thumbnail
                        }
                        .tag(runnerBundle.runner)
                    }
                } label: {
                    Text("runner", bundle: .module)
                }
                Toggle(isOn: Binding<Bool>(
                    get: { store.speedDecreasesUnderLoad },
                    asyncSet: { await store.send(.slowDownUnderLoadToggleSwitched($0)) }
                )) {
                    Text("slowDownUnderLoad", bundle: .module)
                }
                Toggle(isOn: Binding<Bool>(
                    get: { store.isFlippedHorizontally },
                    asyncSet: { await store.send(.flipHorizontallyToggleSwitched($0)) }
                )) {
                    Text("flipHorizontally", bundle: .module)
                }
            } header: {
                Text("runnerBar", bundle: .module)
            }
            Section {
                Toggle(isOn: Binding<Bool>(
                    get: { store.showsMetricsBar },
                    asyncSet: { await store.send(.showMetricsBarToggleSwitched($0)) }
                )) {
                    Text("showMetricsBar", bundle: .module)
                }
            } header: {
                Text("metricsBar", bundle: .module)
            }
            Section {
                Toggle(isOn: Binding<Bool>(
                    get: { store.launchesAtLogin },
                    asyncSet: { await store.send(.launchAtLoginToggleSwitched($0)) }
                )) {
                    Text("launchAtLogin", bundle: .module)
                }
            } header: {
                Text("launch", bundle: .module)
            }
        }
        .formStyle(.grouped)
        .fixedSize()
        .alert(
            isPresented: $store.showingAlert,
            error: store.error,
            actions: { _ in },
            message: { _ in }
        )
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

extension GeneralSettings: ObservableObject {}
