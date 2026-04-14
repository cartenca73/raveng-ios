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

                        if vm.loading && vm.templates.isEmpty {
                            ProgressView().padding(40).frame(maxWidth: .infinity)
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
                                            TemplateDocRow(template: t, index: idx)
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
                            .padding(.bottom, 24)
                        }

                        if let err = vm.error {
                            InlineError(message: err).padding(.horizontal, 16)
                        }
                    }
                }
                .refreshable { await vm.load() }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await vm.load() }
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
