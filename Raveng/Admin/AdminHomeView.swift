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
                    VStack(alignment: .leading, spacing: 22) {
                        HeroHeader(
                            title: "Amministrazione",
                            subtitle: "Templates, invii, statistiche",
                            systemImage: "rectangle.stack.badge.person.crop"
                        )

                        // Stat cards
                        HStack(spacing: 12) {
                            StatCard(value: "\(vm.templates.count)",
                                     label: "Templates",
                                     icon: "doc.on.doc.fill",
                                     gradient: BrandGradient.primary)
                            StatCard(value: "\(vm.submissions.count)",
                                     label: "Invii recenti",
                                     icon: "paperplane.fill",
                                     gradient: BrandGradient.success)
                        }
                        .padding(.horizontal, 16)

                        if vm.loading {
                            ProgressView().padding()
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Templates").padding(.horizontal, 16)
                                if vm.templates.isEmpty {
                                    Text("Nessun template").foregroundStyle(BrandColor.mute)
                                        .padding(.horizontal, 16)
                                } else {
                                    ForEach(vm.templates) { t in
                                        TemplateRow(template: t).padding(.horizontal, 16)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Invii recenti").padding(.horizontal, 16)
                                if vm.submissions.isEmpty {
                                    Text("Nessun invio").foregroundStyle(BrandColor.mute)
                                        .padding(.horizontal, 16)
                                } else {
                                    ForEach(vm.submissions) { s in
                                        SubmissionRow(sub: s).padding(.horizontal, 16)
                                    }
                                }
                            }
                            .padding(.bottom, 24)
                        }

                        if let err = vm.error { InlineError(message: err).padding(.horizontal, 16) }
                    }
                }
                .refreshable { await vm.load() }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await vm.load() }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let gradient: LinearGradient
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous).fill(gradient)
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon).foregroundStyle(.white).font(.system(size: 22, weight: .bold))
                Text(value).font(BrandFont.display(28)).foregroundStyle(.white)
                Text(label).font(BrandFont.body(13)).foregroundStyle(.white.opacity(0.85))
            }
            .padding(16)
        }
        .frame(height: 130)
        .frame(maxWidth: .infinity)
        .shadow(color: BrandColor.deepBlue.opacity(0.18), radius: 12, x: 0, y: 6)
    }
}

private struct TemplateRow: View {
    let template: TemplateSummary
    var body: some View {
        AppCard(padding: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(BrandColor.skyTint).frame(width: 42, height: 42)
                    Image(systemName: "doc.text").foregroundStyle(BrandColor.midBlue)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name).font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandColor.ink).lineLimit(2)
                    if let n = template.submissionsCount {
                        Text("\(n) invii").font(.system(size: 12)).foregroundStyle(BrandColor.mute)
                    }
                }
                Spacer()
            }
        }
    }
}

private struct SubmissionRow: View {
    let sub: SubmissionSummary
    var body: some View {
        AppCard(padding: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(BrandColor.skyTint).frame(width: 42, height: 42)
                    Image(systemName: "paperplane.fill").foregroundStyle(BrandColor.midBlue)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(sub.templateName ?? "Submission #\(sub.id)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(BrandColor.ink)
                    if let s = sub.status {
                        StatusBadge(text: s, color: s.lowercased().contains("complet")
                                    ? BrandColor.success : BrandColor.midBlue)
                    }
                }
                Spacer()
                if let date = sub.createdAt {
                    Text(date).font(.system(size: 11)).foregroundStyle(BrandColor.mute)
                }
            }
        }
    }
}
