import AllocatedUnfairLock
import Foundation
import Testing

@testable import DataSource
@testable import Model

struct GeneralSettingsTests {
    private func makeSetRecorder() -> (lock: AllocatedUnfairLock<[String]>, client: UserDefaultsClient) {
        let setCallStack = AllocatedUnfairLock<[String]>(initialState: [])
        let client = testDependency(of: UserDefaultsClient.self) {
            $0.set = { value, key in
                let entry = "set: \(key) = \(value ?? "nil")"
                setCallStack.withLock { $0.append(entry) }
            }
        }
        return (setCallStack, client)
    }

    @MainActor @Test
    func send_task_loads_current_runner_and_observes_streams() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        appState.withLock {
            $0.runnerBundles.send(RunnerBundle(runner: .default, frame: .preset("cat-frame-0")))
        }
        let sut = GeneralSettings(.testDependencies(appStateClient: .testDependency(appState)))
        await sut.send(.task("GeneralSettingsTests"))
        #expect(sut.currentRunner == Runner.default)
        appState.withLock {
            $0.runnerBundles.send(RunnerBundle(runner: Runner(kind: .parrot), frame: .preset("parrot-frame-0")))
            $0.runnerBundleLists.send([RunnerBundle(runner: Runner(kind: .parrot), frame: .preset("parrot-frame-0"))])
        }
        await waitUntil { sut.currentRunner == Runner(kind: .parrot) && !sut.runnerBundleList.isEmpty }
        #expect(sut.currentRunner == Runner(kind: .parrot))
        #expect(sut.runnerBundleList.map(\.runner) == [Runner(kind: .parrot)])
        await sut.send(.onDisappear)
    }

    @MainActor @Test
    func send_onDisappear_stops_observing_streams() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let sut = GeneralSettings(.testDependencies(appStateClient: .testDependency(appState)))
        await sut.send(.task("GeneralSettingsTests"))
        await sut.send(.onDisappear)
        appState.withLock {
            $0.runnerBundles.send(RunnerBundle(runner: .default, frame: .preset("cat-frame-0")))
        }
        try? await Task.sleep(for: .milliseconds(50))
        #expect(sut.currentRunner == nil)
    }

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

    @MainActor @Test
    func send_slowDownUnderLoadToggleSwitched_persists_and_updates_runner_speed() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let recorder = makeSetRecorder()
        let sut = GeneralSettings(.testDependencies(
            appStateClient: .testDependency(appState),
            userDefaultsClient: recorder.client
        ))
        await sut.send(.slowDownUnderLoadToggleSwitched(true))
        #expect(sut.speedDecreasesUnderLoad == true)
        #expect(recorder.lock.withLock(\.self) == ["set: SPEED_DECREASES_UNDER_LOAD = true"])
        #expect(appState.withLock(\.runnerSpeeds.latestValue) == 1.0)
    }

    @MainActor @Test
    func send_flipHorizontallyToggleSwitched_persists_and_resends_current_bundle() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let bundle = RunnerBundle(runner: .default, frame: .preset("cat-frame-0"))
        appState.withLock { $0.runnerBundles.send(bundle) }
        let recorder = makeSetRecorder()
        let sut = GeneralSettings(.testDependencies(
            appStateClient: .testDependency(appState),
            userDefaultsClient: recorder.client
        ))
        await sut.send(.flipHorizontallyToggleSwitched(true))
        #expect(sut.isFlippedHorizontally == true)
        #expect(recorder.lock.withLock(\.self) == ["set: IS_FLIPPED_HORIZONTALLY = true"])
        #expect(appState.withLock(\.runnerBundles.latestValue) == bundle)
    }

    @MainActor @Test
    func send_showMetricsBarToggleSwitched_persists_flag() async {
        let recorder = makeSetRecorder()
        let sut = GeneralSettings(.testDependencies(userDefaultsClient: recorder.client))
        await sut.send(.showMetricsBarToggleSwitched(true))
        #expect(sut.showsMetricsBar == true)
        #expect(recorder.lock.withLock(\.self) == ["set: SHOWS_METRICS_BAR = true"])
    }

    @MainActor @Test
    func send_launchAtLoginToggleSwitched_enables_when_register_succeeds() async {
        let registered = AllocatedUnfairLock(initialState: false)
        let sut = GeneralSettings(.testDependencies(
            smAppServiceClient: testDependency(of: SMAppServiceClient.self) {
                $0.status = { registered.withLock(\.self) ? .enabled : .notRegistered }
                $0.register = { registered.withLock { $0 = true } }
            }
        ))
        await sut.send(.launchAtLoginToggleSwitched(true))
        #expect(sut.launchesAtLogin == true)
    }

    @MainActor @Test
    func send_launchAtLoginToggleSwitched_keeps_actual_status_when_register_fails() async {
        let sut = GeneralSettings(.testDependencies(
            smAppServiceClient: testDependency(of: SMAppServiceClient.self) {
                $0.status = { .notRegistered }
                $0.register = { throw URLError(.unknown) }
            }
        ))
        await sut.send(.launchAtLoginToggleSwitched(true))
        #expect(sut.launchesAtLogin == false)
    }
}
