import SwiftUI

struct OnboardingView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("uIN")
                .font(.largeTitle)
                .bold()

            Text("Group plans, zero chaos")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.top, 6)

            Spacer().frame(height: 48)

            VStack(spacing: 24) {
                StepRow(
                    step: "Step 1",
                    icon: "envelope.fill",
                    instruction: "Open Messages"
                )
                StepRow(
                    step: "Step 2",
                    icon: "plus.circle.fill",
                    instruction: "Tap the + button"
                )
                StepRow(
                    step: "Step 3",
                    icon: "app.badge.checkmark",
                    instruction: "Select uIN"
                )
            }

            Spacer().frame(height: 48)

            Text("That's it! Create your first invite in any group chat.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }
}

private struct StepRow: View {
    let step: String
    let icon: String
    let instruction: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(step)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.secondary)
                Text(instruction)
                    .font(.body)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
