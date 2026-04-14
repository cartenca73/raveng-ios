import SwiftUI

// MARK: - Brand Palette
enum BrandColor {
    // Primary spectrum
    static let navy        = Color(hex: 0x0A1F3A)
    static let deepBlue    = Color(hex: 0x0F4C75)
    static let midBlue     = Color(hex: 0x1B6CA8)
    static let brightBlue  = Color(hex: 0x3B82F6)
    static let cyan        = Color(hex: 0x06B6D4)
    static let teal        = Color(hex: 0x0EA5E9)
    static let violet      = Color(hex: 0x6366F1)
    static let skyTint     = Color(hex: 0xE0F2FE)
    static let surface     = Color(hex: 0xF6F9FC)
    static let surfaceAlt  = Color(hex: 0xEEF4FB)
    static let ink         = Color(hex: 0x0B1220)
    static let inkSoft     = Color(hex: 0x1E293B)
    static let mute        = Color(hex: 0x64748B)
    static let muteSoft    = Color(hex: 0x94A3B8)
    static let success     = Color(hex: 0x10B981)
    static let warning     = Color(hex: 0xF59E0B)
    static let danger      = Color(hex: 0xEF4444)
    static let gold        = Color(hex: 0xEAB308)
}

// MARK: - Gradients
enum BrandGradient {
    static let primary = LinearGradient(
        colors: [BrandColor.deepBlue, BrandColor.midBlue, BrandColor.brightBlue],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let hero = LinearGradient(
        colors: [BrandColor.navy, BrandColor.deepBlue, BrandColor.brightBlue],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let heroCyan = LinearGradient(
        colors: [BrandColor.deepBlue, BrandColor.brightBlue, BrandColor.cyan],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let success = LinearGradient(
        colors: [Color(hex: 0x059669), Color(hex: 0x10B981), Color(hex: 0x34D399)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let glass = LinearGradient(
        colors: [Color.white.opacity(0.55), Color.white.opacity(0.18)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let dark = LinearGradient(
        colors: [BrandColor.ink, BrandColor.deepBlue],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let warm = LinearGradient(
        colors: [Color(hex: 0xF59E0B), Color(hex: 0xEF4444)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let subtleCard = LinearGradient(
        colors: [Color.white, Color(hex: 0xF7FAFC)],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Typography (SF Rounded + variable weights)
enum BrandFont {
    static func display(_ size: CGFloat = 34) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func title(_ size: CGFloat = 22)   -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func body(_ size: CGFloat = 16)    -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func mono(_ size: CGFloat = 13)    -> Font { .system(size: size, weight: .medium, design: .monospaced) }
    static func caption(_ size: CGFloat = 11) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
}

// MARK: - Spacing & Radius
enum BrandRadius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 18
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Haptics
enum Haptics {
    static func tap()     { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func soft()    { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func heavy()   { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func rigid()   { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func error()   { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}

// MARK: - Color hex helper
extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - Shadow tokens
enum BrandShadow {
    static func soft(_ color: Color = BrandColor.deepBlue.opacity(0.10)) -> some View {
        Rectangle().fill(Color.clear)
            .shadow(color: color, radius: 16, x: 0, y: 8)
    }
}

// MARK: - Reusable view modifiers

/// Floating card with subtle vertical gradient + colored soft shadow.
struct FloatingCardModifier: ViewModifier {
    var radius: CGFloat = BrandRadius.lg
    var shadowColor: Color = BrandColor.deepBlue.opacity(0.10)
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(BrandGradient.subtleCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 0.8)
                    )
            )
            .shadow(color: shadowColor, radius: 18, x: 0, y: 10)
    }
}

struct GlassCardModifier: ViewModifier {
    var radius: CGFloat = BrandRadius.lg
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
            )
            .shadow(color: BrandColor.deepBlue.opacity(0.15), radius: 22, x: 0, y: 12)
    }
}

extension View {
    func floatingCard(radius: CGFloat = BrandRadius.lg,
                      shadow: Color = BrandColor.deepBlue.opacity(0.10)) -> some View {
        modifier(FloatingCardModifier(radius: radius, shadowColor: shadow))
    }
    func glassCard(radius: CGFloat = BrandRadius.lg) -> some View {
        modifier(GlassCardModifier(radius: radius))
    }
}

// MARK: - Mesh-like background (compatible iOS 17)
/// Three overlapping radial gradients that approximate a mesh gradient.
/// Used as the hero background for a premium, depth-rich look.
struct MeshBackground: View {
    let colors: [Color]
    var animated: Bool = true
    @State private var t: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                colors[0]

                Circle()
                    .fill(colors[1])
                    .frame(width: geo.size.width * 1.2)
                    .blur(radius: 70)
                    .offset(
                        x: geo.size.width * (animated ? (-0.2 + 0.1 * sin(t)) : -0.2),
                        y: geo.size.height * (animated ? (-0.25 + 0.08 * cos(t)) : -0.25)
                    )

                Circle()
                    .fill(colors[2])
                    .frame(width: geo.size.width * 1.0)
                    .blur(radius: 80)
                    .offset(
                        x: geo.size.width * (animated ? (0.35 + 0.08 * cos(t)) : 0.35),
                        y: geo.size.height * (animated ? (0.30 + 0.08 * sin(t)) : 0.30)
                    )

                if colors.count > 3 {
                    Circle()
                        .fill(colors[3])
                        .frame(width: geo.size.width * 0.7)
                        .blur(radius: 70)
                        .offset(
                            x: geo.size.width * (animated ? (-0.3 + 0.10 * sin(t + .pi / 2)) : -0.3),
                            y: geo.size.height * (animated ? (0.40 + 0.05 * cos(t)) : 0.40)
                        )
                }
            }
        }
        .onAppear {
            guard animated else { return }
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                t = .pi * 2
            }
        }
    }
}

// MARK: - Accent strip (used on cards)
struct AccentStrip: View {
    var gradient: LinearGradient = BrandGradient.primary
    var body: some View {
        gradient
            .frame(width: 4)
            .clipShape(Capsule())
    }
}
