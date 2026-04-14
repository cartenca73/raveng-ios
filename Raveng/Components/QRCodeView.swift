import SwiftUI
import CoreImage.CIFilterBuiltins

/// Generates a QR code image from a string. Colors customizable.
struct QRCodeView: View {
    let text: String
    var size: CGFloat = 240
    var foregroundColor: Color = BrandColor.ink
    var backgroundColor: Color = .white

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                .fill(backgroundColor)
                .shadow(color: BrandColor.deepBlue.opacity(0.12), radius: 16, x: 0, y: 8)
            Group {
                if let img = generate() {
                    Image(uiImage: img)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.82, height: size * 0.82)
                } else {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(BrandColor.danger)
                }
            }
            .colorMultiply(foregroundColor)
        }
        .frame(width: size, height: size)
    }

    private func generate() -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "H" // 30%
        guard var img = filter.outputImage else { return nil }
        let scale = (size * UIScreen.main.scale) / img.extent.width
        img = img.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        if let cg = context.createCGImage(img, from: img.extent) {
            return UIImage(cgImage: cg)
        }
        return nil
    }
}

// MARK: - Share sheet wrapping the QR inside a card
struct QRShareSheet: View {
    let title: String
    let subtitle: String
    let url: String
    let hash: String?

    @Environment(\.dismiss) private var dismiss
    @State private var showShare = false

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.surface.ignoresSafeArea()
                VStack(spacing: 18) {
                    HeroHeader(
                        title: "Condividi verifica",
                        subtitle: "Chiunque scansioni il QR verificherà il documento",
                        systemImage: "qrcode",
                        eyebrow: "BLOCKCHAIN"
                    )

                    AppCard {
                        VStack(spacing: 14) {
                            QRCodeView(text: url, size: 240)
                                .padding(.vertical, 10)

                            Text(title)
                                .font(BrandFont.title(16))
                                .foregroundStyle(BrandColor.ink)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)

                            Text(subtitle)
                                .font(BrandFont.body(13))
                                .foregroundStyle(BrandColor.mute)
                                .multilineTextAlignment(.center)

                            if let h = hash {
                                Text("SHA-256: \(String(h.prefix(18)))…")
                                    .font(BrandFont.mono(11))
                                    .foregroundStyle(BrandColor.midBlue)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    GradientButton(title: "Condividi link",
                                   systemImage: "square.and.arrow.up") {
                        showShare = true
                    }
                    .padding(.horizontal, 16).padding(.bottom, 20)
                }
                .padding(.bottom, 30)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") { dismiss() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showShare) {
                ShareSheet(items: [URL(string: url) ?? (url as Any)])
            }
        }
    }
}

// MARK: - UIActivityViewController bridge
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
