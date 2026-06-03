/*
 CustomRunnerSettingsView.swift
 UserInterface

 Created by Takuto Nakamura on 2026/05/31.
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

struct CustomRunnerSettingsView: View {
    @StateObject var store: CustomRunnerSettings

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            CustomRunnerListView(store: store)
            Divider()
            CustomRunnerEditorView(store: store)
        }
        .fixedSize()
        .padding()
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

extension CustomRunnerSettings: ObservableObject {}
