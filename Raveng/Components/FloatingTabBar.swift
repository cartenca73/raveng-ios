import SwiftUI

struct FloatingTab: Identifiable, Equatable {
    let id: Int
    let title: String
    let systemImage: String
}

struct FloatingTabBar: View {
    let tabs: [FloatingTab]
    @Binding var selection: Int
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs) { tab in
                Button {
                    if selection != tab.id {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) {
                            selection = tab.id
                        }
                        Haptics.soft()
                    }
                } label: {
                    ZStack {
                        if selection == tab.id {
                            Capsule()
                                .fill(BrandGradient.primary)
                                .matchedGeometryEffect(id: "pill", in: ns)
                                .shadow(color: BrandColor.deepBlue.opacity(0.30),
                                        radius: 10, x: 0, y: 6)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 16, weight: .semibold))
                            if selection == tab.id {
                                Text(tab.title)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                        }
                        .foregroundStyle(selection == tab.id ? Color.white : BrandColor.mute)
                        .padding(.horizontal, selection == tab.id ? 14 : 10)
                        .padding(.vertical, 10)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.4), lineWidth: 0.6)
                )
        )
        .shadow(color: BrandColor.deepBlue.opacity(0.15), radius: 18, x: 0, y: 10)
        .padding(.horizontal, 16)
    }
}
