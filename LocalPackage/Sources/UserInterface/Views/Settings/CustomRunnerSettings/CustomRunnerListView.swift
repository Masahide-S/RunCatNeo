/*
 CustomRunnerListView.swift
 UserInterface

 Created by Takuto Nakamura on 2026/06/03.
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

struct CustomRunnerListView: View {
    @Bindable var store: CustomRunnerSettings

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $store.selectedCustomRunner) {
                ForEach(store.customRunnerBundleList, id: \.runner) { runnerBundle in
                    Label {
                        Text(runnerBundle.runner.name)
                    } icon: {
                        runnerBundle.thumbnail
                    }
                    .labelReservedIconWidth(50)
                    .listItemTint(.primary)
                    .tag(runnerBundle.runner)
                }
            }
            .listStyle(.plain)
            Divider()
            HStack {
                Button {
                    Task {
                        await store.send(.deleteButtonTapped)
                    }
                } label: {
                    Label {
                        Text("deleteCustomRunner", bundle: .module)
                    } icon: {
                        Image(systemName: "minus")
                    }
                    .labelStyle(.iconOnly)
                }
                .buttonStyle(.segmented)
                .disabled(store.selectedCustomRunner == nil)
                Spacer()
            }
        }
        .frame(width: 128)
        .border(Color(.separatorColor))
    }
}
