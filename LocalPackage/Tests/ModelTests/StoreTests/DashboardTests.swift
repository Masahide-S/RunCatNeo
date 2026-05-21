import os
import Testing

@testable import DataSource
@testable import Model

struct DashboardTests {
    @MainActor @Test
    func send_settingsButtonTapped() async throws {
        let callStack = OSAllocatedUnfairLock<[String]>(initialState: [])
        let sut = Dashboard(.testDependencies(
            nsAppClient: testDependency(of: NSAppClient.self) {
                $0.activate = { value in
                    callStack.withLock { $0.append("activate: \(value)") }
                }
            }
        ))
        await sut.send(.settingsButtonTapped)
        #expect(callStack.withLock(\.self) == ["activate: true"])
    }

    @MainActor @Test
    func send_aboutButtonTapped() async throws {
        let callStack = OSAllocatedUnfairLock<[String]>(initialState: [])
        let sut = Dashboard(.testDependencies(
            nsAppClient: testDependency(of: NSAppClient.self) {
                $0.activate = { value in
                    callStack.withLock { $0.append("activate: \(value)") }
                }
                $0.orderFrontStandardAboutPanel = { _ in
                    callStack.withLock { $0.append("orderFrontStandardAboutPanel") }
                }
            }
        ))
        await sut.send(.aboutButtonTapped)
        #expect(callStack.withLock(\.self) == [
            "activate: true",
            "orderFrontStandardAboutPanel",
        ])
    }

    @MainActor @Test
    func send_quitButtonTapped() async throws {
        let callStack = OSAllocatedUnfairLock<[String]>(initialState: [])
        let sut = Dashboard(.testDependencies(
            nsAppClient: testDependency(of: NSAppClient.self) {
                $0.terminate = { _ in
                    callStack.withLock { $0.append("terminate") }
                }
            }
        ))
        await sut.send(.quitButtonTapped)
        #expect(callStack.withLock(\.self) == ["terminate"])
    }
}
