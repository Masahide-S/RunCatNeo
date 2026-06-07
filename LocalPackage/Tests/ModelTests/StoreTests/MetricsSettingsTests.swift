import AllocatedUnfairLock
import Foundation
import SystemInfoKit
import Testing

@testable import DataSource
@testable import Model

struct MetricsSettingsTests {
    @MainActor @Test
    func send_task_refreshes_failed_source_ids_when_metrics_change() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let snapshot = CustomMetricsSnapshot(title: "Card", lastUpdatedDate: Date(timeIntervalSince1970: 0))
        let failedBundle = CustomMetricsBundle(id: UUID(1), snapshot: snapshot, isFailed: true)
        appState.withLock { $0.metrics.send(Metrics(customMetricsBundles: [failedBundle])) }
        let sut = MetricsSettings(.testDependencies(appStateClient: .testDependency(appState)))
        await sut.send(.task("MetricsSettingsTests"))
        #expect(sut.failedCustomMetricsSourceIDs == [UUID(1)])
        let recoveredBundle = CustomMetricsBundle(id: UUID(1), snapshot: snapshot, isFailed: false)
        appState.withLock { $0.metrics.send(Metrics(customMetricsBundles: [recoveredBundle])) }
        await waitUntil { sut.failedCustomMetricsSourceIDs.isEmpty }
        #expect(sut.failedCustomMetricsSourceIDs.isEmpty)
        await sut.send(.onDisappear)
    }

    @MainActor @Test
    func send_task_refreshes_configuration_when_change_event_is_emitted() async throws {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let storage = UserDefaultsClient.storage()
        let sut = MetricsSettings(.testDependencies(
            appStateClient: .testDependency(appState),
            userDefaultsClient: storage.client
        ))
        await sut.send(.task("MetricsSettingsTests"))
        #expect(sut.systemMetricsConfiguration == .default)
        let updatedConfiguration = SystemMetricsConfiguration(
            monitorsMemory: false,
            monitorsStorage: false,
            monitorsBattery: false,
            monitorsNetwork: false
        )
        let encodedConfiguration = try JSONEncoder().encode(updatedConfiguration)
        storage.lock.withLock { $0[.systemMetricsConfiguration] = encodedConfiguration }
        appState.withLock { $0.systemMetricsConfigurationChanges.send() }
        await waitUntil { sut.systemMetricsConfiguration == updatedConfiguration }
        #expect(sut.systemMetricsConfiguration == updatedConfiguration)
        await sut.send(.onDisappear)
    }

    @MainActor @Test
    func send_onDisappear_stops_observing_configuration_changes() async throws {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let storage = UserDefaultsClient.storage()
        let sut = MetricsSettings(.testDependencies(
            appStateClient: .testDependency(appState),
            userDefaultsClient: storage.client
        ))
        await sut.send(.task("MetricsSettingsTests"))
        await sut.send(.onDisappear)
        let updatedConfiguration = SystemMetricsConfiguration(
            monitorsMemory: false,
            monitorsStorage: false,
            monitorsBattery: false,
            monitorsNetwork: false
        )
        let encodedConfiguration = try JSONEncoder().encode(updatedConfiguration)
        storage.lock.withLock { $0[.systemMetricsConfiguration] = encodedConfiguration }
        appState.withLock { $0.systemMetricsConfigurationChanges.send() }
        try? await Task.sleep(for: .milliseconds(50))
        #expect(sut.systemMetricsConfiguration == .default)
    }

    @MainActor @Test
    func send_monitorsSystemInfoToggleSwitched_persists_configurations_and_notifies() async throws {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let activationRequests = AllocatedUnfairLock<[SystemInfoType: Bool]?>(initialState: nil)
        let storage = UserDefaultsClient.storage()
        let initialBarConfiguration = MetricsBarConfiguration(
            showsCPU: true,
            showsMemory: true,
            showsStorage: false,
            showsBattery: false,
            showsNetwork: false
        )
        let encodedBarConfiguration = try JSONEncoder().encode(initialBarConfiguration)
        storage.lock.withLock { $0[.metricsBarConfiguration] = encodedBarConfiguration }
        let sut = MetricsSettings(.testDependencies(
            appStateClient: .testDependency(appState),
            systemInfoObserverClient: testDependency(of: SystemInfoObserverClient.self) {
                $0.toggleActivation = { requests in
                    activationRequests.withLock { $0 = requests }
                }
            },
            userDefaultsClient: storage.client
        ))
        await sut.send(.monitorsSystemInfoToggleSwitched(.memory, false))
        #expect(sut.systemMetricsConfiguration.monitorsMemory == false)
        let storedConfigurationData = storage.lock.withLock { $0[.systemMetricsConfiguration] }
        let storedConfiguration = try JSONDecoder().decode(
            SystemMetricsConfiguration.self,
            from: try #require(storedConfigurationData)
        )
        #expect(storedConfiguration.monitorsMemory == false)
        let storedBarConfigurationData = storage.lock.withLock { $0[.metricsBarConfiguration] }
        let storedBarConfiguration = try JSONDecoder().decode(
            MetricsBarConfiguration.self,
            from: try #require(storedBarConfigurationData)
        )
        #expect(storedBarConfiguration.showsMemory == false)
        #expect(activationRequests.withLock(\.self) == [.memory: false])
        #expect(appState.withLock(\.systemMetricsConfigurationChanges.latestValue) != nil)
    }

    @MainActor @Test
    func send_monitorsSystemInfoToggleSwitched_cpu_is_noop() async {
        let toggleActivationCount = AllocatedUnfairLock<Int>(initialState: 0)
        let sut = MetricsSettings(.testDependencies(
            systemInfoObserverClient: testDependency(of: SystemInfoObserverClient.self) {
                $0.toggleActivation = { _ in
                    toggleActivationCount.withLock { $0 += 1 }
                }
            }
        ))
        await sut.send(.monitorsSystemInfoToggleSwitched(.cpu, false))
        #expect(toggleActivationCount.withLock(\.self) == 0)
    }

    @MainActor @Test
    func send_task_reloads_customMetricsSources_from_user_defaults() async {
        let storage = UserDefaultsClient.storage(initialSources: [
            CustomMetricsSource(
                id: UUID(1),
                displayName: "Existing",
                fileURL: URL(filePath: "/tmp/existing.json"),
                bookmark: Data([0x42]),
                createdAt: Date(timeIntervalSince1970: 0)
            )
        ])
        let sut = MetricsSettings(.testDependencies(
            userDefaultsClient: storage.client
        ))
        await sut.send(.task("MetricsSettingsTests"))
        #expect(sut.customMetricsSources.count == 1)
        #expect(sut.customMetricsSources.first?.displayName == "Existing")
    }

    @MainActor @Test
    func send_addCustomMetricsSourceButtonTapped_shows_file_importer() async {
        let sut = MetricsSettings(.testDependencies())
        await sut.send(.addCustomMetricsSourceButtonTapped)
        #expect(sut.showingFileImporter == true)
    }

    @MainActor @Test
    func send_onCompletionFileImporter_success_appends_source_and_emits_change() async throws {
        let storage = UserDefaultsClient.storage()
        let emittedChange = AllocatedUnfairLock<Int>(initialState: 0)
        let appStateClient = AppStateClient.testDependency(.init(initialState: .init()))
        Task {
            let stream = appStateClient.withLock(\.customMetricsConfigurationChanges.stream)
            for await _ in stream {
                emittedChange.withLock { $0 += 1 }
            }
        }
        let fileURL = URL(filePath: "/tmp/metrics.json")
        let json = #"{ "title": "Imported", "metrics": [], "lastUpdatedDate": "2026-06-05T04:50:40Z" }"#
        let dataClient = testDependency(of: DataClient.self) {
            $0.read = { _ in Data(json.utf8) }
        }
        let urlClient = testDependency(of: URLClient.self) {
            $0.startAccessingSecurityScopedResource = { _ in true }
            $0.stopAccessingSecurityScopedResource = { _ in }
            $0.bookmarkData = { _, _ in Data([0xAB]) }
        }
        let sut = MetricsSettings(.testDependencies(
            appStateClient: appStateClient,
            dataClient: dataClient,
            urlClient: urlClient,
            userDefaultsClient: storage.client
        ))
        await sut.send(.onCompletionFileImporter(.success(fileURL)))
        #expect(sut.customMetricsSources.count == 1)
        #expect(sut.customMetricsSources.first?.displayName == "Imported")
        #expect(sut.customMetricsSources.first?.bookmark == Data([0xAB]))
        try? await Task.sleep(for: .milliseconds(50))
        #expect(emittedChange.withLock(\.self) >= 1)
    }

    @MainActor @Test
    func send_helpButtonTapped_shows_help_popover() async {
        let sut = MetricsSettings(.testDependencies())
        await sut.send(.helpButtonTapped)
        #expect(sut.showingHelpPopover == true)
    }

    @MainActor @Test
    func send_onCompletionFileImporter_shows_alert_when_file_is_unreadable() async {
        let storage = UserDefaultsClient.storage()
        let sut = MetricsSettings(.testDependencies(
            dataClient: testDependency(of: DataClient.self) {
                $0.read = { _ in throw URLError(.unknown) }
            },
            urlClient: testDependency(of: URLClient.self) {
                $0.startAccessingSecurityScopedResource = { _ in true }
            },
            userDefaultsClient: storage.client
        ))
        await sut.send(.onCompletionFileImporter(.success(URL(filePath: "/tmp/metrics.json"))))
        #expect(sut.error == .customMetrics(.fileUnreadable))
        #expect(sut.showingAlert == true)
        #expect(sut.customMetricsSources.isEmpty)
    }

    @MainActor @Test
    func send_onCompletionFileImporter_shows_alert_when_json_is_invalid() async {
        let storage = UserDefaultsClient.storage()
        let sut = MetricsSettings(.testDependencies(
            dataClient: testDependency(of: DataClient.self) {
                $0.read = { _ in Data("not json".utf8) }
            },
            urlClient: testDependency(of: URLClient.self) {
                $0.startAccessingSecurityScopedResource = { _ in true }
            },
            userDefaultsClient: storage.client
        ))
        await sut.send(.onCompletionFileImporter(.success(URL(filePath: "/tmp/metrics.json"))))
        #expect(sut.error == .customMetrics(.invalidFormat))
        #expect(sut.showingAlert == true)
        #expect(sut.customMetricsSources.isEmpty)
    }

    @MainActor @Test
    func send_onCompletionFileImporter_failure_does_not_throw() async {
        struct DummyError: Error {}
        let storage = UserDefaultsClient.storage()
        let sut = MetricsSettings(.testDependencies(
            userDefaultsClient: storage.client
        ))
        await sut.send(.onCompletionFileImporter(.failure(DummyError())))
        #expect(sut.customMetricsSources.isEmpty)
    }

    @MainActor @Test
    func send_removeCustomMetricsSourceButtonTapped_marks_pending_and_shows_dialog() async {
        let existingID = UUID(2)
        let storage = UserDefaultsClient.storage(initialSources: [
            CustomMetricsSource(
                id: existingID,
                displayName: "Pending",
                fileURL: URL(filePath: "/tmp/pending.json"),
                bookmark: Data(),
                createdAt: Date(timeIntervalSince1970: 0)
            )
        ])
        let sut = MetricsSettings(.testDependencies(
            userDefaultsClient: storage.client
        ))
        await sut.send(.task("MetricsSettingsTests"))
        await sut.send(.removeCustomMetricsSourceButtonTapped(existingID))
        #expect(sut.pendingRemovalSourceID == existingID)
        #expect(sut.showingConfirmationDialog == true)
        #expect(sut.customMetricsSources.count == 1)
    }

    @MainActor @Test
    func send_removingCustomMetricsSourceConfirmed_removes_pending_source() async {
        let existingID = UUID(3)
        let storage = UserDefaultsClient.storage(initialSources: [
            CustomMetricsSource(
                id: existingID,
                displayName: "Doomed",
                fileURL: URL(filePath: "/tmp/doomed.json"),
                bookmark: Data(),
                createdAt: Date(timeIntervalSince1970: 0)
            )
        ])
        let sut = MetricsSettings(.testDependencies(
            userDefaultsClient: storage.client
        ))
        await sut.send(.task("MetricsSettingsTests"))
        await sut.send(.removeCustomMetricsSourceButtonTapped(existingID))
        await sut.send(.removingCustomMetricsSourceConfirmed)
        #expect(sut.customMetricsSources.isEmpty)
        #expect(sut.pendingRemovalSourceID == nil)
    }

    @MainActor @Test
    func send_removingCustomMetricsSourceConfirmed_with_no_pending_is_noop() async {
        let existingID = UUID(4)
        let storage = UserDefaultsClient.storage(initialSources: [
            CustomMetricsSource(
                id: existingID,
                displayName: "Safe",
                fileURL: URL(filePath: "/tmp/safe.json"),
                bookmark: Data(),
                createdAt: Date(timeIntervalSince1970: 0)
            )
        ])
        let sut = MetricsSettings(.testDependencies(
            userDefaultsClient: storage.client
        ))
        await sut.send(.task("MetricsSettingsTests"))
        await sut.send(.removingCustomMetricsSourceConfirmed)
        #expect(sut.customMetricsSources.count == 1)
    }

    @MainActor @Test
    func send_removingCustomMetricsSourceCancelled_clears_pending_without_removing() async {
        let existingID = UUID(5)
        let storage = UserDefaultsClient.storage(initialSources: [
            CustomMetricsSource(
                id: existingID,
                displayName: "Spared",
                fileURL: URL(filePath: "/tmp/spared.json"),
                bookmark: Data(),
                createdAt: Date(timeIntervalSince1970: 0)
            )
        ])
        let sut = MetricsSettings(.testDependencies(
            userDefaultsClient: storage.client
        ))
        await sut.send(.task("MetricsSettingsTests"))
        await sut.send(.removeCustomMetricsSourceButtonTapped(existingID))
        await sut.send(.removingCustomMetricsSourceCancelled)
        #expect(sut.pendingRemovalSourceID == nil)
        #expect(sut.customMetricsSources.count == 1)
    }

    @MainActor @Test
    func send_customMetricsSourceLinkTapped_activates_file_viewer_with_resolved_url() async {
        let resolvedURL = URL(filePath: "/tmp/resolved.json")
        let activatedURLs = AllocatedUnfairLock<[URL]>(initialState: [])
        let source = CustomMetricsSource(
            id: UUID(6),
            displayName: "Linked",
            fileURL: URL(filePath: "/tmp/linked.json"),
            bookmark: Data([0xAA]),
            createdAt: Date(timeIntervalSince1970: 0)
        )
        let urlClient = testDependency(of: URLClient.self) {
            $0.create = { _, _ in (false, resolvedURL) }
            $0.startAccessingSecurityScopedResource = { _ in true }
            $0.stopAccessingSecurityScopedResource = { _ in }
        }
        let nsWorkspaceClient = testDependency(of: NSWorkspaceClient.self) {
            $0.activateFileViewerSelecting = { urls in
                activatedURLs.withLock { $0 = urls }
            }
        }
        let sut = MetricsSettings(.testDependencies(
            nsWorkspaceClient: nsWorkspaceClient,
            urlClient: urlClient
        ))
        await sut.send(.customMetricsSourceLinkTapped(source))
        #expect(activatedURLs.withLock(\.self) == [resolvedURL])
    }

    @MainActor @Test
    func send_customMetricsSourceLinkTapped_persists_refreshed_bookmark_when_stale() async {
        let resolvedURL = URL(filePath: "/tmp/resolved.json")
        let refreshedBookmark = Data([0xBB, 0xCC])
        let existingID = UUID(7)
        let storage = UserDefaultsClient.storage(initialSources: [
            CustomMetricsSource(
                id: existingID,
                displayName: "Stale",
                fileURL: URL(filePath: "/tmp/stale.json"),
                bookmark: Data([0xAA]),
                createdAt: Date(timeIntervalSince1970: 0)
            )
        ])
        let source = CustomMetricsSource(
            id: existingID,
            displayName: "Stale",
            fileURL: URL(filePath: "/tmp/stale.json"),
            bookmark: Data([0xAA]),
            createdAt: Date(timeIntervalSince1970: 0)
        )
        let urlClient = testDependency(of: URLClient.self) {
            $0.create = { _, _ in (true, resolvedURL) }
            $0.bookmarkData = { _, _ in refreshedBookmark }
            $0.startAccessingSecurityScopedResource = { _ in true }
            $0.stopAccessingSecurityScopedResource = { _ in }
        }
        let nsWorkspaceClient = testDependency(of: NSWorkspaceClient.self) {
            $0.activateFileViewerSelecting = { _ in }
        }
        let sut = MetricsSettings(.testDependencies(
            nsWorkspaceClient: nsWorkspaceClient,
            urlClient: urlClient,
            userDefaultsClient: storage.client
        ))
        await sut.send(.customMetricsSourceLinkTapped(source))
        let configuration = storage.currentConfiguration()
        #expect(configuration?.sources.first?.bookmark == refreshedBookmark)
    }

    @MainActor @Test
    func send_customMetricsSourceLinkTapped_does_not_activate_when_create_throws() async {
        let activatedURLs = AllocatedUnfairLock<[URL]>(initialState: [])
        let source = CustomMetricsSource(
            id: UUID(8),
            displayName: "Broken",
            fileURL: URL(filePath: "/tmp/broken.json"),
            bookmark: Data(),
            createdAt: Date(timeIntervalSince1970: 0)
        )
        let urlClient = testDependency(of: URLClient.self) {
            $0.create = { _, _ in throw URLError(.unknown) }
        }
        let nsWorkspaceClient = testDependency(of: NSWorkspaceClient.self) {
            $0.activateFileViewerSelecting = { urls in
                activatedURLs.withLock { $0 = urls }
            }
        }
        let sut = MetricsSettings(.testDependencies(
            nsWorkspaceClient: nsWorkspaceClient,
            urlClient: urlClient
        ))
        await sut.send(.customMetricsSourceLinkTapped(source))
        #expect(activatedURLs.withLock(\.self).isEmpty)
        #expect(sut.error == .customMetrics(.fileUnreadable))
        #expect(sut.showingAlert == true)
    }

}
