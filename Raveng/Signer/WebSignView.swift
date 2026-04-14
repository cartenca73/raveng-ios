import SwiftUI
import WebKit

/// Presenta l'esperienza di firma completa di DocuSeal dentro una WKWebView.
/// La pagina `/s/{slug}` è pubblica (auth via slug) quindi non servono cookie.
struct WebSignView: View {
    let slug: String
    var onCompleted: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var progress: Double = 0
    @State private var isLoading = true
    @State private var didComplete = false

    private var url: URL {
        URL(string: "https://docusign.ce4u.it/s/\(slug)")!
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            WebSignViewRepresentable(
                url: url,
                progress: $progress,
                isLoading: $isLoading,
                onCompleted: {
                    if !didComplete {
                        didComplete = true
                        Haptics.success()
                        onCompleted?()
                    }
                }
            )
            .ignoresSafeArea(edges: .bottom)

            // Top bar
            HStack(spacing: 12) {
                Button {
                    Haptics.tap(); dismiss()
                } label: {
                    ZStack {
                        Circle().fill(.ultraThinMaterial).frame(width: 34, height: 34)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(BrandColor.ink)
                    }
                }
                Spacer()
                Text("Firma documento")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(BrandColor.ink)
                Spacer()
                Color.clear.frame(width: 34, height: 34)
            }
            .padding(.horizontal, 16).padding(.top, 8)

            // Progress bar
            if isLoading {
                GeometryReader { geo in
                    Rectangle()
                        .fill(BrandGradient.primary)
                        .frame(width: geo.size.width * progress, height: 2)
                }
                .frame(height: 2)
                .padding(.top, 50)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - WKWebView wrapper

struct WebSignViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var progress: Double
    @Binding var isLoading: Bool
    var onCompleted: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(progress: $progress, isLoading: $isLoading, onCompleted: onCompleted)
    }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.websiteDataStore = .default()
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.navigationDelegate = context.coordinator
        wv.allowsBackForwardNavigationGestures = false
        wv.scrollView.contentInsetAdjustmentBehavior = .always

        // KVO for progress
        context.coordinator.observe(webView: wv)
        wv.load(URLRequest(url: url))
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.invalidate(webView: uiView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var progress: Double
        @Binding var isLoading: Bool
        let onCompleted: () -> Void
        private var progressObs: NSKeyValueObservation?

        init(progress: Binding<Double>, isLoading: Binding<Bool>, onCompleted: @escaping () -> Void) {
            self._progress = progress
            self._isLoading = isLoading
            self.onCompleted = onCompleted
        }

        func observe(webView: WKWebView) {
            progressObs = webView.observe(\.estimatedProgress, options: .new) { [weak self] wv, _ in
                Task { @MainActor in
                    self?.progress = wv.estimatedProgress
                }
            }
        }

        func invalidate(webView: WKWebView) {
            progressObs?.invalidate(); progressObs = nil
            webView.stopLoading()
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in isLoading = true }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                isLoading = false
                progress = 0
            }
            // Detect completion via URL path heuristic
            if let path = webView.url?.path.lowercased(),
               path.contains("/completed") || path.contains("/cdc/") && path.contains("/completed") {
                onCompleted()
            }
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Always allow navigation but flag completed pages
            if let path = navigationAction.request.url?.path.lowercased(),
               path.contains("/completed") {
                onCompleted()
            }
            decisionHandler(.allow)
        }
    }
}
