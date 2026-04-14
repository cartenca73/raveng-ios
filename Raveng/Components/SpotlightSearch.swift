import SwiftUI

struct SpotlightResult: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String
    let accent: LinearGradient
    let destination: SpotlightDestination

    static func == (l: SpotlightResult, r: SpotlightResult) -> Bool { l.id == r.id }
}

enum SpotlightDestination: Equatable {
    case signerDetail(slug: String)
    case templateDetail(id: Int)
    case tab(Int)
    case action(String)
}

@MainActor
final class SpotlightVM: ObservableObject {
    @Published var query: String = ""
    @Published var results: [SpotlightResult] = []
    @Published var recent: [String] = []
    @Published var loading = false

    private var task: Task<Void, Never>?

    func search(pending: [PendingSubmitter], templates: [TemplateSummary]) {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 180_000_000) // debounce 180ms
            guard !Task.isCancelled else { return }
            self.performSearch(q: self.query, pending: pending, templates: templates)
        }
    }

    private func performSearch(q: String, pending: [PendingSubmitter], templates: [TemplateSummary]) {
        let trimmed = q.trimmingCharacters(in: .whitespaces).lowercased()
        var out: [SpotlightResult] = []

        // Always: quick actions prefixed by `/`
        let quickActions: [(String, String, String, SpotlightDestination)] = [
            ("Vai a Da firmare",    "signature",              "FIRMA",     .tab(0)),
            ("Vai ad Amministra",   "rectangle.stack.fill",   "ADMIN",     .tab(1)),
            ("Verifica un PDF",     "checkmark.shield.fill",  "VERIFICA",  .tab(2)),
            ("Profilo e sicurezza", "person.crop.circle.fill","PROFILO",   .tab(3))
        ]

        for (title, icon, _, dest) in quickActions
            where trimmed.isEmpty || title.lowercased().contains(trimmed) {
            out.append(.init(id: "qa:\(title)", title: title, subtitle: "Azione rapida",
                             icon: icon, accent: BrandGradient.primary, destination: dest))
        }

        // Pending documents
        for p in pending {
            let name = p.documentName ?? p.name ?? "Documento"
            let match = trimmed.isEmpty || name.lowercased().contains(trimmed)
                     || (p.email ?? "").lowercased().contains(trimmed)
            if match {
                out.append(.init(
                    id: "p:\(p.id)",
                    title: name,
                    subtitle: "Da firmare · \(p.email ?? p.name ?? "")",
                    icon: "doc.text.fill",
                    accent: LinearGradient(colors: [BrandColor.deepBlue, BrandColor.brightBlue],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                    destination: .signerDetail(slug: p.slug)
                ))
            }
        }

        // Templates
        for t in templates {
            if trimmed.isEmpty || t.name.lowercased().contains(trimmed) {
                out.append(.init(
                    id: "t:\(t.id)",
                    title: t.name,
                    subtitle: "Template · \(t.submittersCount ?? 0) invii",
                    icon: "doc.on.doc.fill",
                    accent: LinearGradient(colors: [BrandColor.violet, BrandColor.brightBlue],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                    destination: .templateDetail(id: t.id)
                ))
            }
        }

        self.results = out
    }
}

struct SpotlightSearchView: View {
    @Binding var query: String
    let pending: [PendingSubmitter]
    let templates: [TemplateSummary]
    let onSelect: (SpotlightDestination) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SpotlightVM()
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.surface.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(BrandColor.mute)
                        TextField("Cerca documenti, template, azioni…", text: $vm.query)
                            .focused($focused)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: vm.query) { _, _ in
                                vm.search(pending: pending, templates: templates)
                            }
                        if !vm.query.isEmpty {
                            Button { vm.query = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(BrandColor.mute)
                            }
                        }
                    }
                    .padding(14)
                    .background(BrandGradient.subtleCard,
                                in: RoundedRectangle(cornerRadius: BrandRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: BrandRadius.md)
                            .stroke(Color.white.opacity(0.6), lineWidth: 0.8)
                    )
                    .shadow(color: BrandColor.deepBlue.opacity(0.08), radius: 14, x: 0, y: 6)
                    .padding(.horizontal, 16).padding(.top, 10)

                    Divider().padding(.vertical, 14).padding(.horizontal, 16)

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if vm.results.isEmpty && !vm.query.isEmpty {
                                VStack(spacing: 12) {
                                    AnimatedIllustration(kind: .inbox).frame(height: 140)
                                    Text("Nessun risultato")
                                        .font(BrandFont.title(16))
                                        .foregroundStyle(BrandColor.ink)
                                }
                                .frame(maxWidth: .infinity).padding(.top, 40)
                            } else {
                                ForEach(vm.results) { r in
                                    Button {
                                        Haptics.soft()
                                        onSelect(r.destination)
                                        dismiss()
                                    } label: {
                                        SpotlightRow(result: r)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Cerca")
                        .font(BrandFont.title(17))
                        .foregroundStyle(BrandColor.ink)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
        .onAppear {
            vm.query = query
            focused = true
            vm.search(pending: pending, templates: templates)
        }
    }
}

private struct SpotlightRow: View {
    let result: SpotlightResult
    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemImage: result.icon, size: 42, gradient: result.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text(result.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandColor.ink)
                    .lineLimit(1)
                if let s = result.subtitle {
                    Text(s).font(BrandFont.caption(11.5)).foregroundStyle(BrandColor.mute)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BrandColor.mute)
        }
        .padding(12)
        .background(BrandGradient.subtleCard,
                    in: RoundedRectangle(cornerRadius: BrandRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: BrandRadius.md)
                .stroke(Color.white.opacity(0.7), lineWidth: 0.8)
        )
        .shadow(color: BrandColor.deepBlue.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
