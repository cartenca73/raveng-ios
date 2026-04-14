import SwiftUI

@MainActor
final class AdminVM: ObservableObject {
    @Published var templates: [TemplateSummary] = []
    @Published var submissions: [SubmissionSummary] = []
    @Published var loading = false
    @Published var error: String?

    func load() async {
        loading = true; error = nil
        do {
            struct TR: Decodable { let templates: [TemplateSummary] }
            struct SR: Decodable { let submissions: [SubmissionSummary] }
            async let t: TR = APIClient.shared.send(API.Admin.templates())
            async let s: SR = APIClient.shared.send(API.Admin.submissions(page: 1))
            let (tr, sr) = try await (t, s)
            self.templates   = tr.templates
            self.submissions = sr.submissions
        } catch let e as APIError where e.isCancelled {
            // silenzioso
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

struct AdminHomeView: View {
    @StateObject var vm = AdminVM()
    @EnvironmentObject var spotlight: SpotlightDataHub
    @State private var showNewTemplate = false
    @State private var showNewSubmission = false
    @State private var pickSubmissionTemplate = false
    @State private var showDocumentPicker = false
    @State private var uploadingPDF = false
    @State private var uploadError: String?
    @State private var openEditorForTemplateId: Int?

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.surface.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HeroHeader(
                            title: "Amministrazione",
                            subtitle: "Templates, invii e statistiche",
                            systemImage: "rectangle.stack.badge.person.crop",
                            gradientColors: [
                                BrandColor.navy,
                                BrandColor.deepBlue,
                                BrandColor.violet,
                                BrandColor.cyan
                            ],
                            eyebrow: "DASHBOARD"
                        )

                        HStack(spacing: 12) {
                            StatCard(value: "\(vm.templates.count)",
                                     label: "Templates attivi",
                                     icon: "doc.on.doc.fill",
                                     gradient: BrandGradient.primary)
                            StatCard(value: "\(vm.submissions.count)",
                                     label: "Invii recenti",
                                     icon: "paperplane.fill",
                                     gradient: BrandGradient.success)
                        }
                        .padding(.horizontal, 16)

                        // Quick actions
                        VStack(spacing: 10) {
                            GradientButton(title: "Carica un PDF e invia",
                                           systemImage: "square.and.arrow.up.fill",
                                           gradient: LinearGradient(
                                            colors: [BrandColor.violet, BrandColor.brightBlue, BrandColor.cyan],
                                            startPoint: .leading, endPoint: .trailing
                                           ),
                                           isLoading: uploadingPDF) {
                                showDocumentPicker = true
                            }
                            HStack(spacing: 10) {
                                GradientButton(title: "Nuovo template",
                                               systemImage: "plus",
                                               gradient: BrandGradient.primary) {
                                    showNewTemplate = true
                                }
                                GradientButton(title: "Nuovo invio",
                                               systemImage: "paperplane",
                                               gradient: BrandGradient.success) {
                                    pickSubmissionTemplate = true
                                }
                            }
                            if let err = uploadError {
                                InlineError(message: err)
                            }
                        }
                        .padding(.horizontal, 16)

                        if vm.loading && vm.templates.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(0..<3) { _ in SkeletonRow() }
                            }
                            .padding(.horizontal, 16)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Templates",
                                              subtitle: "\(vm.templates.count) totali")
                                    .padding(.horizontal, 16)

                                if vm.templates.isEmpty {
                                    emptyInline("Nessun template attivo")
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(Array(vm.templates.prefix(6).enumerated()), id: \.element.id) { idx, t in
                                            NavigationLink(value: t) {
                                                TemplateDocRow(template: t, index: idx)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Invii recenti",
                                              subtitle: "Ultimi 50")
                                    .padding(.horizontal, 16)
                                if vm.submissions.isEmpty {
                                    emptyInline("Nessun invio recente")
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(Array(vm.submissions.prefix(10).enumerated()), id: \.element.id) { idx, s in
                                            SubmissionDocRow(sub: s, index: idx)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.bottom, 90)
                        }

                        if let err = vm.error {
                            InlineError(message: err).padding(.horizontal, 16)
                        }
                    }
                }
                .refreshable { await vm.load() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: TemplateSummary.self) { t in
                TemplateDetailView(template: t)
            }
        }
        .task { await vm.load() }
        .onChange(of: vm.templates) { _, new in spotlight.templates = new }
        .fullScreenCover(isPresented: $showNewTemplate, onDismiss: {
            Task { await vm.load() }
        }) {
            WebAdminView(path: "/templates/new", title: "Nuovo template")
        }
        .sheet(isPresented: $pickSubmissionTemplate) {
            TemplatePickerSheet(templates: vm.templates) { t in
                pickSubmissionTemplate = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    self.pickedTemplateForSubmission = t
                }
            }
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(item: $pickedTemplateForSubmission, onDismiss: {
            Task { await vm.load() }
        }) { t in
            WebAdminView(path: "/templates/\(t.id)/submissions/new",
                         title: "Nuovo invio")
        }
        .fileImporter(isPresented: $showDocumentPicker,
                      allowedContentTypes: [.pdf],
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task { await uploadPDF(url) }
            case .failure(let e):
                uploadError = e.localizedDescription
            }
        }
        .fullScreenCover(item: Binding(
            get: { openEditorForTemplateId.map { TemplateIdWrapper(id: $0) } },
            set: { openEditorForTemplateId = $0?.id }
        ), onDismiss: { Task { await vm.load() } }) { w in
            WebAdminView(path: "/templates/\(w.id)", title: "Editor documento")
        }
    }

    private struct TemplateIdWrapper: Identifiable { let id: Int }

    @State private var pickedTemplateForSubmission: TemplateSummary?

    private func uploadPDF(_ url: URL) async {
        uploadingPDF = true; uploadError = nil
        defer { uploadingPDF = false }
        struct Resp: Decodable {
            let ok: Bool
            let template_id: Int
            let name: String
        }
        do {
            let r: Resp = try await APIClient.shared.uploadMultipart(
                path: "admin/templates/from_pdf",
                fileURL: url,
                extraFields: ["extract_fields": "1"]
            )
            Haptics.success()
            openEditorForTemplateId = r.template_id
        } catch {
            uploadError = error.localizedDescription
            Haptics.error()
        }
    }

    @ViewBuilder
    private func emptyInline(_ text: String) -> some View {
        Text(text)
            .font(BrandFont.body(13))
            .foregroundStyle(BrandColor.mute)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .floatingCard()
            .padding(.horizontal, 16)
    }
}

// MARK: - Template picker (per Nuovo invio)
struct TemplatePickerSheet: View {
    let templates: [TemplateSummary]
    let onPick: (TemplateSummary) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var filtered: [TemplateSummary] {
        guard !query.isEmpty else { return templates }
        return templates.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.surface.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Scegli un template")
                            .font(BrandFont.title(22))
                            .foregroundStyle(BrandColor.ink)
                            .padding(.horizontal, 16).padding(.top, 12)

                        HStack {
                            Image(systemName: "magnifyingglass").foregroundStyle(BrandColor.mute)
                            TextField("Cerca…", text: $query)
                                .textInputAutocapitalization(.never)
                        }
                        .padding(12)
                        .background(BrandGradient.subtleCard,
                                    in: RoundedRectangle(cornerRadius: BrandRadius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: BrandRadius.sm)
                                .stroke(Color.white.opacity(0.6), lineWidth: 0.8)
                        )
                        .padding(.horizontal, 16)

                        if filtered.isEmpty {
                            Text("Nessun template").foregroundStyle(BrandColor.mute)
                                .padding(.horizontal, 16).padding(.top, 20)
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(filtered) { t in
                                    Button {
                                        Haptics.tap(); onPick(t)
                                    } label: {
                                        ListRowCard(
                                            leading: {
                                                IconTile(systemImage: "doc.on.doc.fill",
                                                         size: 42, gradient: BrandGradient.primary)
                                            },
                                            content: {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(t.name)
                                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                                        .foregroundStyle(BrandColor.ink)
                                                        .lineLimit(2)
                                                    if let c = t.submissionsCount {
                                                        Text("\(c) invii").font(BrandFont.caption(11))
                                                            .foregroundStyle(BrandColor.mute)
                                                    }
                                                }
                                            }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") { dismiss() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Stat card
private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let gradient: LinearGradient

    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                .fill(gradient)

            // inner highlight
            LinearGradient(colors: [Color.white.opacity(0.25), .clear],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.22)).frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .foregroundStyle(.white).font(.system(size: 17, weight: .heavy))
                }
                Text(value)
                    .font(BrandFont.display(32))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(BrandFont.caption(11.5))
                    .foregroundStyle(.white.opacity(0.88))
                    .tracking(0.6)
                    .lineLimit(2)
            }
            .padding(16)
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .shadow(color: BrandColor.deepBlue.opacity(0.22), radius: 14, x: 0, y: 8)
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }
}

// MARK: - Template row
private struct TemplateDocRow: View {
    let template: TemplateSummary
    let index: Int
    @State private var appeared = false

    var body: some View {
        ListRowCard(
            leading: { IconTile(systemImage: "doc.on.doc.fill", size: 44,
                                gradient: BrandGradient.primary) },
            content: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandColor.ink)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        if let n = template.submissionsCount {
                            Text("\(n) invii")
                                .font(BrandFont.caption(11))
                                .foregroundStyle(BrandColor.mute)
                        }
                    }
                }
            },
            accentGradient: BrandGradient.primary,
            showChevron: true
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(Double(index) * 0.03)) {
                appeared = true
            }
        }
    }
}

// MARK: - Submission row
private struct SubmissionDocRow: View {
    let sub: SubmissionSummary
    let index: Int
    @State private var appeared = false

    private var statusColor: Color {
        switch (sub.status ?? "").lowercased() {
        case let s where s.contains("complet"): return BrandColor.success
        case let s where s.contains("progr"):   return BrandColor.brightBlue
        default:                                 return BrandColor.warning
        }
    }

    private var statusText: String {
        switch (sub.status ?? "").lowercased() {
        case let s where s.contains("complet"): return "Completato"
        case let s where s.contains("progr"):   return "In corso"
        default:                                 return "In attesa"
        }
    }

    private var accent: LinearGradient {
        switch (sub.status ?? "").lowercased() {
        case let s where s.contains("complet"): return BrandGradient.success
        default:                                 return BrandGradient.primary
        }
    }

    var body: some View {
        ListRowCard(
            leading: {
                IconTile(systemImage: "paperplane.fill", size: 44, gradient: accent)
            },
            content: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(sub.templateName ?? "Submission #\(sub.id)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandColor.ink)
                        .lineLimit(2)
                    StatusBadge(text: statusText, color: statusColor)
                }
            },
            accentGradient: accent,
            showChevron: true
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(Double(index) * 0.03)) {
                appeared = true
            }
        }
    }
}
