import SwiftUI

// MARK: - GradientButton
struct GradientButton: View {
    let title: String
    var systemImage: String? = nil
    var gradient: LinearGradient = BrandGradient.primary
    var isLoading: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(.white)
                } else if let img = systemImage {
                    Image(systemName: img).font(.system(size: 17, weight: .semibold))
                }
                Text(title).font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                ZStack {
                    gradient
                    if pressed {
                        Color.black.opacity(0.18)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous))
            .shadow(color: BrandColor.deepBlue.opacity(disabled ? 0 : 0.30), radius: 14, x: 0, y: 8)
            .scaleEffect(pressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
            .opacity(disabled ? 0.55 : 1)
        }
        .disabled(disabled || isLoading)
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }
}

// MARK: - SecondaryButton (outline)
struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap(); action()
        } label: {
            HStack(spacing: 8) {
                if let img = systemImage { Image(systemName: img) }
                Text(title).font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(BrandColor.deepBlue)
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                    .stroke(BrandColor.midBlue.opacity(0.4), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card container
struct AppCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                    .fill(Color.white)
            )
            .shadow(color: BrandColor.deepBlue.opacity(0.08), radius: 14, x: 0, y: 6)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let text: String
    var color: Color = BrandColor.midBlue
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(color.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 0.8))
    }
}

// MARK: - Empty State
struct EmptyState: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(BrandGradient.glass).frame(width: 96, height: 96)
                Image(systemName: systemImage)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(BrandGradient.primary)
            }
            Text(title).font(BrandFont.title()).foregroundStyle(BrandColor.ink)
            Text(subtitle).font(BrandFont.body(15))
                .foregroundStyle(BrandColor.mute)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading
struct LoadingView: View {
    var label: String = "Caricamento…"
    var body: some View {
        VStack(spacing: 14) {
            ProgressView().scaleEffect(1.3).tint(BrandColor.brightBlue)
            Text(label).font(BrandFont.body(14)).foregroundStyle(BrandColor.mute)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Section header
struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        HStack {
            Text(title).font(BrandFont.title(18)).foregroundStyle(BrandColor.ink)
            Spacer()
            if let t = actionTitle, let a = action {
                Button(t) { Haptics.soft(); a() }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(BrandColor.brightBlue)
            }
        }
    }
}

// MARK: - Hero header (gradient + title)
struct HeroHeader: View {
    let title: String
    let subtitle: String
    var systemImage: String? = "shield.lefthalf.filled"
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            BrandGradient.hero
                .clipShape(RoundedRectangle(cornerRadius: BrandRadius.xl, style: .continuous))
            // soft glow blobs
            Circle().fill(Color.white.opacity(0.18)).frame(width: 220, height: 220)
                .offset(x: 140, y: -90).blur(radius: 30)
            Circle().fill(BrandColor.cyan.opacity(0.45)).frame(width: 160, height: 160)
                .offset(x: -80, y: 60).blur(radius: 40)

            VStack(alignment: .leading, spacing: 8) {
                if let img = systemImage {
                    Image(systemName: img)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white.opacity(0.92))
                }
                Text(title)
                    .font(BrandFont.display(30))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(BrandFont.body(15))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(22)
        }
        .frame(height: 180)
        .padding(.horizontal, 16)
    }
}

// MARK: - Toast / inline error
struct InlineError: View {
    let message: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(BrandColor.danger)
            Text(message).font(BrandFont.body(14)).foregroundStyle(BrandColor.ink)
        }
        .padding(12)
        .background(BrandColor.danger.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: BrandRadius.sm, style: .continuous))
    }
}
