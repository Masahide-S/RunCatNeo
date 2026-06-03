/*
 CustomRunnerEditorView.swift
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

struct CustomRunnerEditorView: View {
    @Bindable var store: CustomRunnerSettings

    var body: some View {
        VStack {
            Form {
                TextField(text: $store.runnerName) {
                    Text("runnerName:", bundle: .module)
                }
                LabeledContent {
                    Toggle(isOn: $store.isTemplate) {
                        Text("monochrome", bundle: .module)
                    }
                } label: {
                    Text("color:", bundle: .module)
                }
                LabeledContent {
                    VStack(alignment: .leading) {
                        Text("format:", bundle: .module)
                        Text("height:", bundle: .module)
                        Text("width:", bundle: .module)
                    }
                } label: {
                    Text("requirements:", bundle: .module)
                }
                LabeledContent {
                    FrameImagesCollectionView(store: store)
                } label: {
                    Text("frames:", bundle: .module)
                }
                LabeledContent {
                    RunnerPreviewView(store: store)
                } label: {
                    Text("preview:", bundle: .module)
                }
            }
            .formStyle(.columns)
            HStack(spacing: 8) {
                Spacer()
                Button {
                    Task {
                        await store.send(.saveButtonTapped)
                    }
                } label: {
                    Text("save", bundle: .module)
                }
                .disabled(!store.canSave)
            }
        }
        .fileImporter(
            isPresented: $store.showingFileImporter,
            allowedContentTypes: [.png],
            allowsMultipleSelection: true,
            onCompletion: { result in
                Task {
                    await store.send(.onCompletionFileImporter(result))
                }
            }
        )
    }
}
