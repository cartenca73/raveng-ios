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
                VStack(spacing: 0) {
                    HeroHeader(
                        title: "Da firmare",
                        subtitle: "I documenti che ti aspettano",
                        systemImage: "signature"
                    )
                    .padding(.bottom, 8)

                    if vm.loading && vm.items.isEmpty {
                        LoadingView()
                    } else if let err = vm.error {
                        VStack(spacing: 14) {
                            InlineError(message: err)
                            SecondaryButton(title: "Riprova", systemImage: "arrow.clockwise") {
                                Task { await vm.load() }
                            }
                        }.padding(20)
                    } else if vm.items.isEmpty {
                        EmptyState(
                            systemImage: "tray",
                            title: "Tutto pulito!",
                            subtitle: "Non hai documenti in attesa di firma."
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(vm.items) { item in
                                    NavigationLink(value: item) {
                                        SignerCard(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(16)
                        }
                        .refreshable { await vm.load() }
                    }
                }
            }
            .navigationDestination(for: PendingSubmitter.self) { s in
                SignerDetailView(slug: s.slug)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await vm.load() }
    }
}

private struct SignerCard: View {
    let item: PendingSubmitter
    var body: some View {
        AppCard(padding: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(BrandGradient.primary)
                        .frame(width: 50, height: 50)
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.white).font(.system(size: 22, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.templateName ?? "Documento")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandColor.ink)
                        .lineLimit(2)
                    if let mode = item.feaMode, mode != "none" {
                        StatusBadge(text: "FEA \(mode)",
                                    color: mode.contains("cdc") ? BrandColor.midBlue : BrandColor.success)
                    }
                    if let date = item.createdAt {
                        Text(date)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(BrandColor.mute)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(BrandColor.mute)
            }
        }
    }
}
