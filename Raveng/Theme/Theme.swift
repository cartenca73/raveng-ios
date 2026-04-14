import SwiftUI

// MARK: - Brand Palette
enum BrandColor {
    static let deepBlue   = Color(hex: 0x0F4C75)
    static let midBlue    = Color(hex: 0x1B6CA8)
    static let brightBlue = Color(hex: 0x3B82F6)
    static let cyan       = Color(hex: 0x06B6D4)
    static let skyTint    = Color(hex: 0xE0F2FE)
    static let surface    = Color(hex: 0xF8FAFC)
    static let ink        = Color(hex: 0x0B1220)
    static let mute       = Color(hex: 0x64748B)
    static let success    = Color(hex: 0x10B981)
    static let warning    = Color(hex: 0xF59E0B)
    static let danger     = Color(hex: 0xEF4444)
}

// MARK: - Gradients
enum BrandGradient {
    static let primary = LinearGradient(
        colors: [BrandColor.deepBlue, BrandColor.midBlue, BrandColor.brightBlue],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let hero = LinearGradient(
        colors: [BrandColor.deepBlue, BrandColor.brightBlue, BrandColor.cyan],
        startPoint: .top, endPoint: .bottom
    )
    static let glass = LinearGradient(
        colors: [Color.white.opacity(0.55), Color.white.opacity(0.18)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let success = LinearGradient(
        colors: [Color(hex: 0x059669), Color(hex: 0x10B981)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Typography
enum BrandFont {
    static func display(_ size: CGFloat = 34) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func title(_ size: CGFloat = 22)   -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func body(_ size: CGFloat = 16)    -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func mono(_ size: CGFloat = 13)    -> Font { .system(size: size, weight: .medium, design: .monospaced) }
}

// MARK: - Spacing & Radius
enum BrandRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 22
    static let xl: CGFloat = 28
}

// MARK: - Haptics
enum Haptics {
    static func tap()     { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func soft()    { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func heavy()   { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
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

// MARK: - View modifiers
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
            .shadow(color: BrandColor.deepBlue.opacity(0.10), radius: 18, x: 0, y: 8)
    }
}

extension View {
    func glassCard(radius: CGFloat = BrandRadius.lg) -> some View {
        modifier(GlassCardModifier(radius: radius))
    }
}
