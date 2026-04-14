import SwiftUI
import PencilKit

@MainActor
final class SignerDetailVM: ObservableObject {
    @Published var detail: SubmitterDetail?
    @Published var loading = false
    @Published var error: String?

    func load(slug: String) async {
        loading = true; error = nil
        do {
            detail = try await APIClient.shared.send(API.Signer.detail(slug: slug))
        } catch let e as APIError where e.isCancelled {
            // silenzioso
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    func sign(slug: String, signaturePNG: Data) async -> Bool {
        do {
            let b64 = signaturePNG.base64EncodedString()
            try await APIClient.shared.sendVoid(
                API.Signer.sign(slug: slug, signaturePNGBase64: b64, values: nil)
            )
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}

struct SignerDetailView: View {
    let slug: String
    @StateObject var vm = SignerDetailVM()
    @State private var showWebSign = false
    @State private var showPayment = false

    var body: some View {
        ZStack {
            BrandColor.surface.ignoresSafeArea()
            if vm.loading {
                LoadingView()
            } else if let d = vm.detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HeroHeader(
                            title: d.templateName ?? "Documento",
                            subtitle: "Firmatario: \(d.name ?? d.email ?? "—")",
                            systemImage: "doc.richtext.fill"
                        )

                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "info.circle.fill").foregroundStyle(BrandColor.midBlue)
                                    Text("Informazioni").font(BrandFont.title(16))
                                    Spacer()
                                }
                                Divider()
                                rowKV("Stato", d.status?.capitalized ?? "Pending")
                                rowKV("Email", d.email ?? "—")
                                if let p = d.phone, !p.isEmpty { rowKV("Telefono", p) }
                                rowKV("Modalità FEA", (d.feaMode ?? "none").uppercased())
                            }
                        }
                        .padding(.horizontal, 16)

                        if let url = d.documentUrl, let _ = URL(string: url) {
                            AppCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Anteprima documento").font(BrandFont.title(16))
                                    PDFRemoteView(url: URL(string: url)!)
                                        .frame(height: 360)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        VStack(spacing: 10) {
                            GradientButton(title: "Firma il documento",
                                           systemImage: "signature") {
                                showWebSign = true
                            }
                            if (d.feaMode ?? "").contains("cdc") {
                                GradientButton(title: "Procedi con CDC + Apple Pay",
                                               systemImage: "applelogo",
                                               gradient: LinearGradient(
                                                colors: [BrandColor.ink, BrandColor.deepBlue],
                                                startPoint: .topLeading, endPoint: .bottomTrailing
                                               )) {
                                    showPayment = true
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }
            } else if let err = vm.error {
                InlineError(message: err).padding()
            }
        }
        .navigationTitle("Documento")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(slug: slug) }
        .fullScreenCover(isPresented: $showWebSign) {
            WebSignView(slug: slug) {
                // Completion detected in WebView — chiudi e ricarica lista
                showWebSign = false
                Task { await vm.load(slug: slug) }
            }
        }
        .sheet(isPresented: $showPayment) {
            ApplePayPaymentView(slug: slug)
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func rowKV(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(.system(size: 13, weight: .semibold)).foregroundStyle(BrandColor.mute)
            Spacer()
            Text(v).font(.system(size: 14, weight: .medium)).foregroundStyle(BrandColor.ink)
        }
    }
}

// MARK: - Signature Capture (PencilKit)
struct SignatureCaptureView: View {
    let onConfirm: (Data) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var canvas = PKCanvasView()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Firma qui sotto").font(BrandFont.title(20))
                Spacer()
                Button("Pulisci") {
                    Haptics.tap(); canvas.drawing = PKDrawing()
                }
                .foregroundStyle(BrandColor.brightBlue)
            }
            .padding(.horizontal, 20).padding(.top, 20)

            CanvasRepresentable(canvas: $canvas)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(BrandColor.midBlue.opacity(0.3), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                GradientButton(title: "Conferma firma", systemImage: "checkmark.seal.fill") {
                    let img = canvas.drawing.image(
                        from: canvas.drawing.bounds, scale: UIScreen.main.scale
                    )
                    if let png = img.pngData(), !canvas.drawing.bounds.isEmpty {
                        onConfirm(png)
                    }
                }
                SecondaryButton(title: "Annulla") { dismiss() }
            }
            .padding(20)
        }
    }
}

private struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: 4)
        canvas.backgroundColor = .white
        return canvas
    }
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

// MARK: - PDF remote viewer
import PDFKit

struct PDFRemoteView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView {
        let v = PDFView(); v.autoScales = true; v.backgroundColor = .clear
        Task.detached {
            if let doc = PDFDocument(url: url) {
                await MainActor.run { v.document = doc }
            }
        }
        return v
    }
    func updateUIView(_ uiView: PDFView, context: Context) {}
}
