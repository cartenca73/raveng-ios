import SwiftUI

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let illustration: Illustration
    let title: String
    let subtitle: String
    let gradient: LinearGradient
}

struct OnboardingView: View {
    @AppStorage("onboarding.completed") private var completed: Bool = false
    @State private var index = 0

    private let slides: [OnboardingSlide] = [
        .init(illustration: .signed,
              title: "Firma digitale certificata",
              subtitle: "Firma i tuoi documenti dal telefono con valore legale. SPID, FEQ o CDC con ancoraggio blockchain.",
              gradient: BrandGradient.hero),
        .init(illustration: .verified,
              title: "Verifica blockchain",
              subtitle: "Controlla l'autenticità di qualsiasi PDF firmato: SHA-256 sul tuo dispositivo + ancoraggio Bitcoin.",
              gradient: LinearGradient(colors: [BrandColor.deepBlue, BrandColor.teal, BrandColor.cyan],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)),
        .init(illustration: .inbox,
              title: "Tutto a portata di mano",
              subtitle: "Documenti pendenti, gestione template, pagamento CDC con Apple Pay. Veloce, sicuro, elegante.",
              gradient: LinearGradient(colors: [BrandColor.violet, BrandColor.brightBlue, BrandColor.cyan],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
    ]

    var body: some View {
        ZStack {
            slides[index].gradient.ignoresSafeArea()
                .animation(.easeInOut(duration: 0.45), value: index)

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("Salta") { complete() }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 20).padding(.top, 14)

                TabView(selection: $index) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { (i, s) in
                        VStack(spacing: 28) {
                            Spacer()
                            AnimatedIllustration(kind: s.illustration)
                                .frame(height: 200)
                            VStack(spacing: 12) {
                                Text(s.title)
                                    .font(BrandFont.display(28))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                Text(s.subtitle)
                                    .font(BrandFont.body(15))
                                    .foregroundStyle(.white.opacity(0.88))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 28)
                            }
                            Spacer()
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { i in
                        Capsule()
                            .fill(i == index ? Color.white : Color.white.opacity(0.35))
                            .frame(width: i == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: index)
                    }
                }
                .padding(.bottom, 16)

                Button {
                    if index < slides.count - 1 {
                        withAnimation { index += 1 }
                        Haptics.tap()
                    } else {
                        complete()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(index < slides.count - 1 ? "Avanti" : "Inizia")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(BrandColor.deepBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: BrandRadius.md))
                    .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20).padding(.bottom, 24)
            }
        }
    }

    private func complete() {
        withAnimation(.easeInOut) { completed = true }
        Haptics.success()
    }
}
