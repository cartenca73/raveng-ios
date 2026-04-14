import SwiftUI
import CryptoKit
import UniformTypeIdentifiers

private func readDataCoordinated(from url: URL) throws -> Data {
    var coordErr: NSError?
    var result: Result<Data, Error> = .failure(CocoaError(.fileReadUnknown))
    NSFileCoordinator().coordinate(readingItemAt: url, options: [.withoutChanges], error: &coordErr) { newURL in
        do { result = .success(try Data(contentsOf: newURL)) }
        catch { result = .failure(error) }
    }
    if let e = coordErr { throw e }
    return try result.get()
}

@MainActor
final class VerifyVM: ObservableObject {
    @Published var loading = false
    @Published var error: String?
    @Published var info: BlockchainInfo?
    @Published var pickedFileName: String?
    @Published var computedHash: String?

    func verify(fileURL: URL) async {
        let didStartAccess = fileURL.startAccessingSecurityScopedResource()
        defer { if didStartAccess { fileURL.stopAccessingSecurityScopedResource() } }

        loading = true; error = nil; info = nil; computedHash = nil
        do {
            // Usa NSFileCoordinator per leggere in modo sicuro anche file su iCloud Drive
            let data = try readDataCoordinated(from: fileURL)
            let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            self.computedHash = hash
            self.pickedFileName = fileURL.lastPathComponent
            self.info = try await APIClient.shared.send(API.Verify.byHash(hash))
            Haptics.success()
        } catch let e as APIError {
            switch e {
            case .http(404, _):
                self.error = "Documento NON trovato sulla blockchain. Non risulta firmato dal sistema FirmaCDC."
            default:
                self.error = e.localizedDescription
            }
            Haptics.warning()
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
        loading = false
    }
}

struct VerifyHomeView: View {
    @StateObject var vm = VerifyVM()
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.surface.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HeroHeader(
                            title: "Verifica blockchain",
                            subtitle: "Carica un PDF firmato per controllarne l'autenticità",
                            systemImage: "checkmark.shield.fill",
                            gradientColors: [
                                BrandColor.deepBlue,
                                BrandColor.midBlue,
                                BrandColor.teal,
                                BrandColor.cyan
                            ],
                            eyebrow: "OPENTIMESTAMPS · BITCOIN"
                        )

                        AppCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Come funziona", systemImage: "lightbulb.fill")
                                    .font(BrandFont.title(15))
                                    .foregroundStyle(BrandColor.ink)
                                Text("Il file viene processato esclusivamente sul tuo dispositivo. " +
                                     "Calcoliamo l'hash SHA-256 e cerchiamo l'ancoraggio Bitcoin tramite OpenTimestamps.")
                                    .font(BrandFont.body(13))
                                    .foregroundStyle(BrandColor.mute)
                            }
                        }
                        .padding(.horizontal, 16)

                        VStack(spacing: 12) {
                            GradientButton(title: "Seleziona PDF", systemImage: "doc.fill.badge.plus") {
                                showPicker = true
                            }
                            if vm.loading { ProgressView() }
                        }
                        .padding(.horizontal, 16)

                        if let name = vm.pickedFileName {
                            AppCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label(name, systemImage: "doc.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    if let h = vm.computedHash {
                                        Text("SHA-256:")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(BrandColor.mute)
                                        Text(h).font(BrandFont.mono(11))
                                            .foregroundStyle(BrandColor.deepBlue)
                                            .lineLimit(2).truncationMode(.middle)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        if let err = vm.error {
                            InlineError(message: err).padding(.horizontal, 16)
                        }

                        if let info = vm.info {
                            ResultCard(info: info).padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .fileImporter(
            isPresented: $showPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first { Task { await vm.verify(fileURL: url) } }
            case .failure(let e):
                vm.error = e.localizedDescription
            }
        }
    }
}

private struct ResultCard: View {
    let info: BlockchainInfo
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(BrandGradient.success).frame(width: 50, height: 50)
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.white).font(.system(size: 24, weight: .bold))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Documento autentico").font(BrandFont.title(17))
                            .foregroundStyle(BrandColor.success)
                        Text("Verificato sulla blockchain Bitcoin")
                            .font(BrandFont.body(12))
                            .foregroundStyle(BrandColor.mute)
                    }
                    Spacer()
                }

                Divider()

                kv("Firmatario", info.signerName ?? "—")
                kv("Firmato il", info.signedAt ?? "—")
                if let tx = info.bitcoinTxId {
                    kv("Bitcoin TX", String(tx.prefix(20)) + "…", mono: true)
                }
                if let h = info.blockHeight {
                    kv("Block height", "\(h)")
                }
                if let m = info.merkleRoot {
                    kv("Merkle root", String(m.prefix(20)) + "…", mono: true)
                }
                kv("Hash documento", String(info.documentHash.prefix(24)) + "…", mono: true)

                if let att = info.attestation, !att.isEmpty {
                    Text(att).font(BrandFont.body(12))
                        .foregroundStyle(BrandColor.mute)
                        .padding(.top, 6)
                }
            }
        }
    }

    @ViewBuilder
    private func kv(_ k: String, _ v: String, mono: Bool = false) -> some View {
        HStack(alignment: .top) {
            Text(k).font(.system(size: 12, weight: .semibold)).foregroundStyle(BrandColor.mute)
            Spacer()
            Text(v)
                .font(mono ? BrandFont.mono(12) : .system(size: 13, weight: .medium))
                .foregroundStyle(BrandColor.ink)
                .multilineTextAlignment(.trailing)
        }
    }
}
