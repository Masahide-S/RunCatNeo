import AllocatedUnfairLock
import Foundation

@testable import DataSource

extension UserDefaultsClient {
    struct Storage {
        let lock: AllocatedUnfairLock<[String: Data]>
        let client: UserDefaultsClient

        func currentConfiguration() -> CustomMetricsConfiguration? {
            guard let data = lock.withLock({ $0[.customMetricsConfiguration] }) else {
                return nil
            }
            return try? JSONDecoder().decode(CustomMetricsConfiguration.self, from: data)
        }
    }

    static func storage(initialSources: [CustomMetricsSource] = []) -> Storage {
        var initial = [String: Data]()
        if !initialSources.isEmpty,
           let encoded = try? JSONEncoder().encode(CustomMetricsConfiguration(sources: initialSources)) {
            initial[.customMetricsConfiguration] = encoded
        }
        let lock = AllocatedUnfairLock<[String: Data]>(initialState: initial)
        let client = testDependency(of: UserDefaultsClient.self) {
            $0.data = { key in lock.withLock { $0[key] } }
            $0.set = { rawValue, key in
                let dataValue = rawValue as? Data
                lock.withLock { $0[key] = dataValue }
            }
            $0.removeObject = { key in
                lock.withLock { $0[key] = nil }
            }
        }
        return Storage(lock: lock, client: client)
    }
}
