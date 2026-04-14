import SwiftUI

/// Parallax-aware hero: embed inside a ScrollView using:
///   ScrollView { VStack { ParallaxHero { HeroHeader(...) } ... } }
/// When user pulls down: the hero stretches vertically (like App Store).
/// When user scrolls up: hero sticks to top and fades into a blurred bar.
struct ParallaxHero<Content: View>: View {
    let baseHeight: CGFloat
    @ViewBuilder var content: Content

    init(baseHeight: CGFloat = 196, @ViewBuilder content: () -> Content) {
        self.baseHeight = baseHeight
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let stretch = max(minY, 0)
            let squash  = max(-minY, 0)
            let appliedHeight = baseHeight + stretch
            let scale = 1 + (stretch / 300)
            let opacity: Double = max(0, 1.0 - Double(squash) / 140.0)

            content
                .frame(width: geo.size.width, height: appliedHeight)
                .scaleEffect(scale, anchor: .top)
                .offset(y: -stretch)
                .opacity(opacity)
        }
        .frame(height: baseHeight)
    }
}
