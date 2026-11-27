import SwiftUI

#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(macOS)
import AppKit
#endif

struct PoliteAnnouncement: ViewModifier {
    let text: String

    func body(content: Content) -> some View {
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *) {
            content.onChange(of: text) { _, spoken in Announcer.announce(spoken) }
        } else {
            content.onChange(of: text) { spoken in Announcer.announce(spoken) }
        }
    }
}

@MainActor
enum Announcer {
    static func announce(_ text: String) {
        guard !text.isEmpty else { return }
        #if os(iOS) || os(tvOS) || os(visionOS)
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: politeText(text))
        #elseif os(watchOS)
        guard WKAccessibilityIsVoiceOverRunning() else { return }
        var spoken = AttributedString(text)
        spoken.accessibilitySpeechAnnouncementPriority = .low
        AccessibilityNotification.Announcement(spoken).post()
        #elseif os(macOS)
        let element: Any = NSApplication.shared.mainWindow ?? NSApplication.shared
        NSAccessibility.post(
            element: element,
            notification: .announcementRequested,
            userInfo: [
                .announcement: text,
                .priority: NSAccessibilityPriorityLevel.medium.rawValue,
            ]
        )
        #endif
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
    private static func politeText(_ text: String) -> NSAttributedString {
        #if os(visionOS)
        return prioritized(text)
        #else
        if #available(iOS 17, tvOS 17, *) { return prioritized(text) }
        return NSAttributedString(string: text, attributes: [.accessibilitySpeechQueueAnnouncement: true])
        #endif
    }

    @available(iOS 17, tvOS 17, visionOS 1, *)
    private static func prioritized(_ text: String) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [.accessibilitySpeechAnnouncementPriority: UIAccessibilityPriority.low]
        )
    }
    #endif
}
