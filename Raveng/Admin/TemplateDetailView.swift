import SwiftUI

@MainActor
final class TemplateDetailVM: ObservableObject {
    @Published var detail: TemplateDetail?
    @Published var loading = false
    @Published var error: String?
    @Published var working = false
    @Published var successMessage: String?

    func load(id: Int) async {
        loading = true; error = nil
        do {
            detail = try await APIClient.shared.send(API.Admin.templateDetail(id: id))
        } catch let e as APIError where e.isCancelled {
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    func archive(id: Int) async -> Bool {
        working = true; error = nil
        defer { working = false }
        do {
            try await APIClient.shared.sendVoid(API.Admin.templateArchive(id: id))
            successMessage = "Template archiviato"
            Haptics.success()
            return true
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
            return false
        }
    }

    func unarchive(id: Int) async -> Bool {
        working = true; error = nil
        defer { working = false }
        do {
            try await APIClient.shared.sendVoid(API.Admin.templateUnarchive(id: id))
            await load(id: id)
            Haptics.success()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func duplicate(id: Int) async -> (Int, String)? {
        working = true; error = nil
        defer { working = false }
        struct Resp: Decodable {
            let ok: Bool
            let template_id: Int
            let name: String
        }
        do {
            let r: Resp = try await APIClient.shared.send(API.Admin.templateDuplicate(id: id))
            successMessage = "Duplicato: \(r.name)"
            Haptics.success()
            return (r.template_id, r.name)
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
            return nil
        }
    }
}

struct TemplateDetailView: View {
    let template: TemplateSummary
    @StateObject private var vm = TemplateDetailVM()
    @Environment(\.dismiss) private var dismiss
    @State private var confirmArchive = false
    @State private var openWebAdmin = false

    var body: some View {
        ZStack {
            BrandColor.surface.ignoresSafeArea()

            if vm.loading && vm.detail == nil {
                LoadingView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HeroHeader(
                            title: vm.detail?.template.name ?? template.name,
                            subtitle: subtitleText,
                            systemImage: "doc.on.doc.fill",
                            gradientColors: [
                                BrandColor.navy,
                                BrandColor.deepBlue,
                                BrandColor.violet,
                                BrandColor.brightBlue
                            ],
                            eyebrow: "TEMPLATE"
                        )

                        if let stats = vm.detail?.stats {
                            statsGrid(stats)
                                .padding(.horizontal, 16)
                        }

                        actionsRow
                            .padding(.horizontal, 16)

                        infoCard
                            .padding(.horizontal, 16)

                        if let submissions = vm.detail?.submissions, !submissions.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionHeader(
                                    title: "Invii",
                                    subtitle: "\(submissions.count) mostrati"
                                )
                                .padding(.horizontal, 16)

                                LazyVStack(spacing: 12) {
                                    ForEach(submissions) { s in
                                        SubmissionMiniRow(sub: s)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        if let err = vm.error {
                            InlineError(message: err).padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(id: template.id) }
        .confirmationDialog(
            "Archiviare questo template?",
            isPresented: $confirmArchive,
            titleVisibility: .visible
        ) {
            Button("Archivia", role: .destructive) {
                Task {
                    if await vm.archive(id: template.id) {
                        dismiss()
                    }
                }
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("Il template non sarà più visibile nelle liste. Potrai ripristinarlo solo da web admin.")
        }
        .fullScreenCover(isPresented: $openWebAdmin) {
            WebAdminView(path: "/templates/\(template.id)")
        }
    }

    private var subtitleText: String {
        if let s = vm.detail?.stats {
            return "\(s.total) invii · \(s.completed) completati · \(s.pending) in corso"
        }
        if let n = template.submittersCount { return "\(n) firmatari" }
        return "Dettaglio template"
    }

    private func statsGrid(_ s: TemplateStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                  spacing: 12) {
            MiniStat(value: "\(s.total)",      label: "Invii totali", icon: "paperplane.fill",
                     gradient: BrandGradient.primary)
            MiniStat(value: "\(s.completed)",  label: "Completati",   icon: "checkmark.seal.fill",
                     gradient: BrandGradient.success)
            MiniStat(value: "\(s.pending)",    label: "In corso",     icon: "hourglass",
                     gradient: LinearGradient(colors: [BrandColor.warning, BrandColor.gold],
                                              startPoint: .topLeading, endPoint: .bottomTrailing))
            MiniStat(value: "\(s.submitters)", label: "Firmatari",    icon: "person.2.fill",
                     gradient: LinearGradient(colors: [BrandColor.violet, BrandColor.brightBlue],
                                              startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    private var actionsRow: some View {
        VStack(spacing: 10) {
            GradientButton(title: "Apri in admin web",
                           systemImage: "globe",
                           gradient: BrandGradient.primary) {
                openWebAdmin = true
            }
            HStack(spacing: 10) {
                SecondaryButton(title: "Duplica", systemImage: "plus.square.on.square") {
                    Task {
                        _ = await vm.duplicate(id: template.id)
                    }
                }
                SecondaryButton(title: "Archivia", systemImage: "archivebox") {
                    confirmArchive = true
                }
            }
            if vm.working { ProgressView().padding(.top, 4) }
            if let ok = vm.successMessage {
                Text(ok).font(BrandFont.body(13)).foregroundStyle(BrandColor.success)
            }
        }
    }

    private var infoCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill").foregroundStyle(BrandColor.midBlue)
                    Text("Informazioni").font(BrandFont.title(16))
                    Spacer()
                }
                Divider()
                KVRow(key: "ID", value: "\(template.id)")
                if let d = vm.detail?.template {
                    KVRow(key: "Nome", value: d.name)
                    if let slug = d.slug, !slug.isEmpty {
                        KVRow(key: "Slug", value: slug, mono: true)
                    }
                    if let f = d.fieldsCount {
                        KVRow(key: "Campi", value: "\(f)")
                    }
                    if let a = d.author, !a.isEmpty {
                        KVRow(key: "Autore", value: a)
                    }
                    if let c = d.createdAt {
                        KVRow(key: "Creato", value: humanDate(c))
                    }
                    if let u = d.updatedAt {
                        KVRow(key: "Aggiornato", value: humanDate(u))
                    }
                    if let arc = d.archivedAt {
                        KVRow(key: "Archiviato", value: humanDate(arc))
                    }
                }
            }
        }
    }

    private func humanDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) {
            let out = DateFormatter()
            out.locale = Locale(identifier: "it_IT")
            out.dateStyle = .medium
            out.timeStyle = .short
            return out.string(from: d)
        }
        return iso
    }
}

// MARK: - MiniStat
private struct MiniStat: View {
    let value: String
    let label: String
    let icon: String
    let gradient: LinearGradient
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous).fill(gradient)
            LinearGradient(colors: [Color.white.opacity(0.22), .clear],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).foregroundStyle(.white).font(.system(size: 15, weight: .heavy))
                Text(value).font(BrandFont.display(26)).foregroundStyle(.white).minimumScaleFactor(0.7)
                Text(label).font(BrandFont.caption(11)).foregroundStyle(.white.opacity(0.9))
            }
            .padding(14)
        }
        .frame(height: 110)
        .shadow(color: BrandColor.deepBlue.opacity(0.18), radius: 10, x: 0, y: 6)
    }
}

// MARK: - SubmissionMiniRow
private struct SubmissionMiniRow: View {
    let sub: SubmissionSummary
    var body: some View {
        ListRowCard(
            leading: { IconTile(systemImage: "paperplane.fill", size: 40,
                                gradient: BrandGradient.primary) },
            content: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sub.templateName ?? "Submission #\(sub.id)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandColor.ink)
                        .lineLimit(1)
                    if let s = sub.status {
                        StatusBadge(
                            text: s == "completed" ? "Completato"
                                 : s == "in_progress" ? "In corso" : "In attesa",
                            color: s == "completed" ? BrandColor.success
                                  : s == "in_progress" ? BrandColor.brightBlue
                                  : BrandColor.warning
                        )
                    }
                }
            },
            showChevron: false
        )
    }
}

// MARK: - Web admin with auto-login bridge
import WebKit

/// Opens a DocuSeal admin page in a WKWebView, auto-logging-in the current
/// app user via the JWT -> Devise session bridge endpoint.
struct WebAdminView: View {
    let path: String                        // e.g. "/templates/new"
    var title: String = "Admin"
    @Environment(\.dismiss) private var dismiss
    @State private var progress: Double = 0
    @State private var isLoading = true

    private var bridgeURL: URL {
        // The webview loads the bridge; backend signs in via cookie then redirects to `path`.
        var comps = URLComponents(string: "https://docusign.ce4u.it/api/app/v1/auth/web_session")!
        var items = [URLQueryItem(name: "redirect_to", value: path)]
        if let tok = KeychainService.get(.accessToken), !tok.isEmpty {
            items.append(URLQueryItem(name: "token", value: tok))
        }
        comps.queryItems = items
        return comps.url!
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            AdminWebRepresentable(url: bridgeURL,
                                  progress: $progress,
                                  isLoading: $isLoading)
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                HStack {
                    Button {
                        Haptics.tap(); dismiss()
                    } label: {
                        ZStack {
                            Circle().fill(.ultraThinMaterial).frame(width: 34, height: 34)
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(BrandColor.ink)
                        }
                    }
                    Spacer()
                    Text(title).font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(BrandColor.ink)
                    Spacer()
                    Color.clear.frame(width: 34, height: 34)
                }
                .padding(.horizontal, 16).padding(.top, 8)

                if isLoading {
                    GeometryReader { geo in
                        Rectangle().fill(BrandGradient.primary)
                            .frame(width: geo.size.width * progress, height: 2)
                    }
                    .frame(height: 2)
                }
            }
        }
    }
}

private struct AdminWebRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var progress: Double
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coord { Coord(progress: $progress, isLoading: $isLoading) }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.websiteDataStore = .default()
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.navigationDelegate = context.coordinator
        wv.scrollView.contentInsetAdjustmentBehavior = .always
        context.coordinator.observe(wv)
        wv.load(URLRequest(url: url))
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coord) {
        coordinator.invalidate(uiView)
    }

    final class Coord: NSObject, WKNavigationDelegate {
        @Binding var progress: Double
        @Binding var isLoading: Bool
        private var obs: NSKeyValueObservation?

        init(progress: Binding<Double>, isLoading: Binding<Bool>) {
            self._progress = progress
            self._isLoading = isLoading
        }

        func observe(_ wv: WKWebView) {
            obs = wv.observe(\.estimatedProgress, options: .new) { [weak self] wv, _ in
                Task { @MainActor in self?.progress = wv.estimatedProgress }
            }
        }
        func invalidate(_ wv: WKWebView) {
            obs?.invalidate(); obs = nil; wv.stopLoading()
        }
        func webView(_ wv: WKWebView, didStartProvisionalNavigation nav: WKNavigation!) {
            Task { @MainActor in isLoading = true }
        }
        func webView(_ wv: WKWebView, didFinish nav: WKNavigation!) {
            Task { @MainActor in isLoading = false; progress = 0 }
        }
    }
}
