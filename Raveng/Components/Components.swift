import SwiftUI

// MARK: - GradientButton (premium)
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
                    ZStack {
                        Circle().fill(Color.white.opacity(0.22)).frame(width: 26, height: 26)
                        Image(systemName: img).font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
                Text(title).font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    gradient
                    // inner highlight
                    LinearGradient(colors: [Color.white.opacity(0.22), Color.clear],
                                   startPoint: .top, endPoint: .bottom)
                    if pressed { Color.black.opacity(0.15) }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
            )
            .shadow(color: BrandColor.deepBlue.opacity(disabled ? 0 : 0.35), radius: 18, x: 0, y: 10)
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

// MARK: - SecondaryButton
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
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                    .fill(BrandColor.skyTint.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                    .stroke(BrandColor.midBlue.opacity(0.35), lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AppCard
struct AppCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .floatingCard()
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let text: String
    var color: Color = BrandColor.midBlue
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text.uppercased())
                .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .tracking(0.5)
        }
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(color.opacity(0.10), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.7))
    }
}

// MARK: - Empty State
struct EmptyState: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(BrandGradient.hero).frame(width: 110, height: 110)
                    .shadow(color: BrandColor.deepBlue.opacity(0.35), radius: 24, x: 0, y: 12)
                Image(systemName: systemImage)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(title).font(BrandFont.title(20)).foregroundStyle(BrandColor.ink)
            Text(subtitle).font(BrandFont.body(15))
                .foregroundStyle(BrandColor.mute)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
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
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BrandFont.title(20))
                    .foregroundStyle(BrandColor.ink)
                if let s = subtitle {
                    Text(s).font(BrandFont.body(12)).foregroundStyle(BrandColor.mute)
                }
            }
            Spacer()
            if let t = actionTitle, let a = action {
                Button(t) { Haptics.soft(); a() }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandColor.brightBlue)
            }
        }
    }
}

// MARK: - HeroHeader — premium mesh-gradient floating hero
struct HeroHeader: View {
    let title: String
    let subtitle: String
    var systemImage: String? = "shield.lefthalf.filled"
    var gradientColors: [Color] = [
        BrandColor.navy,
        BrandColor.midBlue,
        BrandColor.cyan,
        BrandColor.brightBlue
    ]
    var eyebrow: String? = nil

    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Mesh background (animated blobs)
            MeshBackground(colors: gradientColors, animated: true)
                .clipShape(RoundedRectangle(cornerRadius: BrandRadius.xl, style: .continuous))

            // Fine overlay gradient for readability
            LinearGradient(
                colors: [Color.black.opacity(0.10), Color.black.opacity(0.28)],
                startPoint: .top, endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: BrandRadius.xl, style: .continuous))

            // Soft light streak
            LinearGradient(
                colors: [Color.white.opacity(0.22), .clear, .clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: BrandRadius.xl, style: .continuous))

            // Content
            VStack(alignment: .leading, spacing: 10) {
                // eyebrow row (icon chip + optional small tag)
                HStack(spacing: 10) {
                    if let img = systemImage {
                        ZStack {
                            Circle().fill(.ultraThinMaterial).frame(width: 38, height: 38)
                                .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 0.8))
                            Image(systemName: img)
                                .font(.system(size: 17, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    if let e = eyebrow {
                        Text(e.uppercased())
                            .font(BrandFont.caption(10.5))
                            .foregroundStyle(.white.opacity(0.85))
                            .tracking(1.2)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.white.opacity(0.18), in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                    }
                    Spacer()
                }
                .padding(.top, 2)

                Spacer(minLength: 0)

                Text(title)
                    .font(BrandFont.display(32))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)

                Text(subtitle)
                    .font(BrandFont.body(14))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(2)
            }
            .padding(22)
        }
        .frame(height: 180)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .scaleEffect(appeared ? 1 : 0.96)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }
}

// MARK: - Inline error
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
        .overlay(
            RoundedRectangle(cornerRadius: BrandRadius.sm, style: .continuous)
                .stroke(BrandColor.danger.opacity(0.2), lineWidth: 0.8)
        )
    }
}

// MARK: - ListRowCard — carta per righe lista (documento, template, submission)
struct ListRowCard<Leading: View, Content: View>: View {
    @ViewBuilder var leading: Leading
    @ViewBuilder var content: Content
    var accentGradient: LinearGradient = BrandGradient.primary
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            // Accent strip
            accentGradient
                .frame(width: 4)
                .clipShape(
                    UnevenRoundedRectangle(
                        cornerRadii: .init(topLeading: BrandRadius.md,
                                           bottomLeading: BrandRadius.md,
                                           bottomTrailing: 0,
                                           topTrailing: 0)
                    )
                )

            HStack(spacing: 14) {
                leading
                content
                Spacer(minLength: 6)
                if showChevron {
                    ZStack {
                        Circle().fill(BrandColor.surfaceAlt).frame(width: 28, height: 28)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(BrandColor.midBlue)
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.leading, 12)
            .padding(.trailing, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                .fill(BrandGradient.subtleCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 0.8)
        )
        .shadow(color: BrandColor.deepBlue.opacity(0.08), radius: 14, x: 0, y: 7)
        .contentShape(RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous))
    }
}

// MARK: - IconTile — icona in tessera gradient (riusabile in list cards / stat cards)
struct IconTile: View {
    let systemImage: String
    var size: CGFloat = 46
    var radius: CGFloat = 13
    var gradient: LinearGradient = BrandGradient.primary

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(gradient)
                .shadow(color: BrandColor.deepBlue.opacity(0.25), radius: 10, x: 0, y: 6)
            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - KV row
struct KVRow: View {
    let key: String
    let value: String
    var mono: Bool = false
    var body: some View {
        HStack(alignment: .top) {
            Text(key).font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(BrandColor.mute)
            Spacer()
            Text(value)
                .font(mono ? BrandFont.mono(12) : .system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(BrandColor.ink)
                .multilineTextAlignment(.trailing)
        }
    }
}
