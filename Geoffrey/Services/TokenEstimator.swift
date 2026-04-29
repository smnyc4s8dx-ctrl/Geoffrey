import Foundation

enum TokenEstimator {
    static func estimate(_ text: String) -> Int {
        max(1, text.count / 4)
    }

    static func estimate(messages: [ChatMessage]) -> Int {
        messages.reduce(0) { total, message in
            total + estimate(message.content) + 4 // 4 tokens overhead per message
        }
    }
}
