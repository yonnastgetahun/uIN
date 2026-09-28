import SwiftUI

struct NonIMessageView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("uIN works in iMessage group chats.")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("To use uIN, make sure everyone in the chat is using iMessage.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
