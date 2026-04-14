import SwiftUI

/// Animated SwiftUI-native illustrations for empty states.
enum Illustration {
    case inbox
    case signed
    case verified
    case error
}

struct AnimatedIllustration: View {
    let kind: Illustration

    @State private var anim = false

    var body: some View {
        ZStack {
            // Soft gradient backdrop
            Circle().fill(BrandGradient.hero)
                .frame(width: 140, height: 140)
                .shadow(color: BrandColor.deepBlue.opacity(0.35), radius: 24, x: 0, y: 12)
            // Orbiting dot
            Circle().fill(BrandColor.cyan)
                .frame(width: 10, height: 10)
                .offset(x: 62, y: -62)
                .rotationEffect(.degrees(anim ? 360 : 0))
                .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: anim)

            icon
        }
        .onAppear { anim = true }
    }

    @ViewBuilder private var icon: some View {
        switch kind {
        case .inbox:
            Image(systemName: "tray.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(anim ? 1.0 : 0.9)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).repeatForever(autoreverses: true), value: anim)

        case .signed:
            ZStack {
                Image(systemName: "doc.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
                Path { p in
                    p.move(to: CGPoint(x: -8, y: 6))
                    p.addCurve(
                        to: CGPoint(x: 14, y: -2),
                        control1: CGPoint(x: 0, y: -6),
                        control2: CGPoint(x: 8, y: 8)
                    )
                }
                .trim(from: 0, to: anim ? 1 : 0)
                .stroke(BrandColor.cyan, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 30, height: 20)
                .offset(x: 4, y: 10)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: anim)
            }

        case .verified:
            ZStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white)
                // Expanding ring
                Circle()
                    .stroke(BrandColor.cyan, lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(anim ? 1.3 : 0.9)
                    .opacity(anim ? 0 : 0.8)
                    .animation(.easeOut(duration: 1.8).repeatForever(autoreverses: false), value: anim)
            }

        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(anim ? 2 : -2))
                .animation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true), value: anim)
        }
    }
}

// MARK: - Enhanced EmptyState usando AnimatedIllustration
struct AnimatedEmptyState: View {
    let illustration: Illustration
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            AnimatedIllustration(kind: illustration).frame(height: 160)
            Text(title).font(BrandFont.title(20)).foregroundStyle(BrandColor.ink)
            Text(subtitle).font(BrandFont.body(14))
                .foregroundStyle(BrandColor.mute)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let t = actionTitle, let a = action {
                SecondaryButton(title: t, action: a)
                    .padding(.horizontal, 32)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
