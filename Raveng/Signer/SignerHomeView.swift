import SwiftUI

@MainActor
final class SignerVM: ObservableObject {
    @Published var items: [PendingSubmitter] = []
    @Published var loading = false
    @Published var error: String?

    func load() async {
        loading = true; error = nil
        do {
            struct Resp: Decodable { let submitters: [PendingSubmitter] }
            let r: Resp = try await APIClient.shared.send(API.Signer.pending())
            items = r.submitters
        } catch let e as APIError where e.isCancelled {
            // silenzioso
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

struct SignerHomeView: View {
    @StateObject var vm = SignerVM()
    @EnvironmentObject var auth: AuthService

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.surface.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HeroHeader(
                            title: "Da firmare",
                            subtitle: "I documenti che ti aspettano",
                            systemImage: "signature",
                            eyebrow: vm.items.isEmpty ? "RAVENG" : "\(vm.items.count) in attesa"
                        )

                        if vm.loading && vm.items.isEmpty {
                            LoadingView().frame(height: 200)
                        } else if let err = vm.error {
                            VStack(spacing: 12) {
                                InlineError(message: err)
                                SecondaryButton(title: "Riprova", systemImage: "arrow.clockwise") {
                                    Task { await vm.load() }
                                }
                            }
                            .padding(.horizontal, 16)
                        } else if vm.items.isEmpty {
                            EmptyState(
                                systemImage: "tray",
                                title: "Tutto pulito!",
                                subtitle: "Non hai documenti in attesa di firma."
                            )
                            .frame(minHeight: 320)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(vm.items.enumerated()), id: \.element.id) { idx, item in
                                    NavigationLink(value: item) {
                                        SignerDocRow(item: item, index: idx)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                    }
                }
                .refreshable { await vm.load() }
            }
            .navigationDestination(for: PendingSubmitter.self) { s in
                SignerDetailView(slug: s.slug)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await vm.load() }
    }
}

// MARK: - Document row (WOW)
private struct SignerDocRow: View {
    let item: PendingSubmitter
    let index: Int

    @State private var appeared = false

    private var displayTitle: String {
        let name = item.templateName?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (name?.isEmpty == false ? name! : "Documento")
    }

    private var displaySubtitle: String {
        if let email = item.email, !email.isEmpty { return email }
        if let name = item.name, !name.isEmpty { return name }
        return "Firma richiesta"
    }

    private var feaBadge: (String, Color)? {
        guard let mode = item.feaMode, mode != "none" else { return nil }
        switch mode {
        case "spid":      return ("FEA SPID", BrandColor.success)
        case "qes":       return ("FEQ", BrandColor.violet)
        case "cdc":       return ("CDC TEST", BrandColor.warning)
        case "cdc_live":  return ("CDC LIVE", BrandColor.brightBlue)
        default:          return (mode.uppercased(), BrandColor.midBlue)
        }
    }

    var body: some View {
        ListRowCard(
            leading: {
                IconTile(systemImage: "doc.text.fill", size: 48, gradient: BrandGradient.primary)
            },
            content: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayTitle)
                        .font(.system(size: 15.5, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandColor.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        if let b = feaBadge {
                            StatusBadge(text: b.0, color: b.1)
                        } else {
                            StatusBadge(text: "In attesa", color: BrandColor.midBlue)
                        }
                        Spacer(minLength: 0)
                    }

                    Text(displaySubtitle)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(BrandColor.muteSoft)
                        .lineLimit(1)
                }
            },
            accentGradient: accentForMode
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(Double(index) * 0.03)) {
                appeared = true
            }
        }
    }

    private var accentForMode: LinearGradient {
        guard let mode = item.feaMode else { return BrandGradient.primary }
        switch mode {
        case "cdc", "cdc_live": return BrandGradient.warm
        case "qes":             return LinearGradient(colors: [BrandColor.violet, BrandColor.brightBlue],
                                                      startPoint: .top, endPoint: .bottom)
        case "spid":            return BrandGradient.success
        default:                return BrandGradient.primary
        }
    }
}
