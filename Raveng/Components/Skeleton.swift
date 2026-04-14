import SwiftUI

// MARK: - Shimmer modifier (riutilizzabile)
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1.0
    var duration: Double = 1.3
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let w = geo.size.width
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.55),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: w * 0.6)
                    .offset(x: phase * (w * 1.6))
                    .blendMode(.plusLighter)
                }
                .mask(content)
                .allowsHitTesting(false)
            )
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

extension View {
    func shimmering(_ active: Bool = true, duration: Double = 1.3) -> some View {
        Group {
            if active { self.modifier(Shimmer(duration: duration)) }
            else { self }
        }
    }
}

// MARK: - Primitive skeleton shapes
struct SkeletonBar: View {
    var height: CGFloat = 12
    var width: CGFloat? = nil
    var radius: CGFloat = 6
    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(BrandColor.surfaceAlt)
            .frame(width: width, height: height)
    }
}

struct SkeletonCircle: View {
    var size: CGFloat = 44
    var body: some View {
        Circle().fill(BrandColor.surfaceAlt).frame(width: size, height: size)
    }
}

struct SkeletonTile: View {
    var size: CGFloat = 46
    var radius: CGFloat = 12
    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(BrandColor.surfaceAlt)
            .frame(width: size, height: size)
    }
}

// MARK: - Row skeleton (imita SignerDocRow/TemplateDocRow)
struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 0) {
            BrandColor.surfaceAlt
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
                SkeletonTile(size: 46)
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonBar(height: 14, width: 200)
                    SkeletonBar(height: 10, width: 120)
                }
                Spacer()
                SkeletonCircle(size: 28)
            }
            .padding(.vertical, 14).padding(.leading, 12).padding(.trailing, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                .fill(BrandGradient.subtleCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 0.8)
        )
        .shadow(color: BrandColor.deepBlue.opacity(0.05), radius: 10, x: 0, y: 4)
        .shimmering()
    }
}

// MARK: - Hero skeleton
struct SkeletonHero: View {
    var body: some View {
        RoundedRectangle(cornerRadius: BrandRadius.xl, style: .continuous)
            .fill(BrandColor.surfaceAlt)
            .frame(height: 180)
            .overlay(
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Circle().fill(Color.white.opacity(0.4)).frame(width: 38, height: 38)
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 80, height: 18)
                        Spacer()
                    }
                    Spacer()
                    RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.45))
                        .frame(width: 240, height: 28)
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.35))
                        .frame(width: 180, height: 14)
                }
                .padding(22)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .shimmering()
    }
}

// MARK: - Stat card skeleton
struct SkeletonStat: View {
    var body: some View {
        RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
            .fill(BrandColor.surfaceAlt)
            .frame(height: 140)
            .overlay(
                VStack(alignment: .leading, spacing: 10) {
                    Circle().fill(Color.white.opacity(0.4)).frame(width: 38, height: 38)
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.45))
                        .frame(width: 70, height: 26)
                    RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.35))
                        .frame(width: 100, height: 12)
                }
                .padding(16), alignment: .topLeading
            )
            .shimmering()
    }
}
