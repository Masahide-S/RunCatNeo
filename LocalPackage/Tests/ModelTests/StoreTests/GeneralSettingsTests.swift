import AllocatedUnfairLock
import Foundation
import Testing

@testable import DataSource
@testable import Model

struct GeneralSettingsTests {
    @MainActor @Test
    func send_selectRunner_updates_current_runner() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let sut = GeneralSettings(.testDependencies(appStateClient: .testDependency(appState)))
        await sut.send(.selectRunner(Runner(kind: .parrot)))
        #expect(sut.currentRunner == Runner(kind: .parrot))
        #expect(appState.withLock(\.runnerBundles.latestValue)?.runner == Runner(kind: .parrot))
    }

    @MainActor @Test
    func send_selectRunner_shows_alert_when_custom_runner_frames_are_missing() async {
        let runner = Runner(id: "custom-runner", name: "Custom Runner", isTemplate: false, frameOrder: .custom([0]))
        let sut = GeneralSettings(.testDependencies(
            fileManagerClient: testDependency(of: FileManagerClient.self) {
                $0.fileExists = { $0.hasSuffix("RunCatNeo/") }
            }
        ))
        await sut.send(.selectRunner(runner))
        #expect(sut.error == .customRunner(.loadingFailed))
        #expect(sut.showingAlert == true)
        #expect(sut.currentRunner == nil)
    }
}
