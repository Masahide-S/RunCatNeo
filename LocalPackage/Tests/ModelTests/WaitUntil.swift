import Foundation

func waitUntil(_ condition: @MainActor () -> Bool) async {
    for _ in 0 ..< 200 {
        if await condition() { return }
        try? await Task.sleep(for: .milliseconds(10))
    }
}
