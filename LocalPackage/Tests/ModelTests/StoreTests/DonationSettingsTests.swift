import AllocatedUnfairLock
import Foundation
import Testing

@testable import DataSource
@testable import Model

struct DonationSettingsTests {
    @MainActor @Test
    func send_task_forwards_action_to_parent() async {
        let receivedActionCount = AllocatedUnfairLock<Int>(initialState: 0)
        let sut = DonationSettings(.testDependencies()) { _ in
            receivedActionCount.withLock { $0 += 1 }
        }
        await sut.send(.task("DonationSettingsTests"))
        #expect(receivedActionCount.withLock(\.self) == 1)
    }

    @MainActor @Test
    func send_linkButtonTapped_opens_url() async {
        let openedURL = AllocatedUnfairLock<URL?>(initialState: nil)
        let nsWorkspaceClient = testDependency(of: NSWorkspaceClient.self) {
            $0.open = { url in
                openedURL.withLock { $0 = url }
                return true
            }
        }
        let sut = DonationSettings(.testDependencies(nsWorkspaceClient: nsWorkspaceClient))
        let url = URL(string: "https://example.com/donate")!
        await sut.send(.linkButtonTapped(url))
        #expect(openedURL.withLock(\.self) == url)
    }
}
