import UIKit

enum ContactsService {
    static func displayName() async -> String {
        let deviceName = await MainActor.run { UIDevice.current.name }

        // Device name is typically "Yonnas's iPhone" — extract the person's name
        if let apostrophe = deviceName.range(of: "\u{2019}s ") ?? deviceName.range(of: "'s ") {
            let name = String(deviceName[deviceName.startIndex..<apostrophe.lowerBound])
            if !name.isEmpty {
                return name
            }
        }

        // Generic or simulator device names — return "You" with device context
        let genericPrefixes = ["iPhone", "iPad", "iPod"]
        if genericPrefixes.contains(where: { deviceName.hasPrefix($0) }) {
            return "You"
        }

        if deviceName.isEmpty {
            return "You"
        }

        return deviceName
    }
}
