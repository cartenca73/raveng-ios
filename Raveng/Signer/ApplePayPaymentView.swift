import SwiftUI
import PassKit

@MainActor
final class ApplePayVM: NSObject, ObservableObject, PKPaymentAuthorizationControllerDelegate {
    @Published var creating = false
    @Published var error: String?
    @Published var success = false

    let slug: String
    private(set) var checkout: CdcCheckout?
    private var pendingCompletion: ((PKPaymentAuthorizationResult) -> Void)?

    init(slug: String) { self.slug = slug }

    func startCheckout() async {
        creating = true; error = nil
        do {
            checkout = try await APIClient.shared.send(API.Cdc.createCheckout(slug: slug))
            creating = false
            presentApplePay()
        } catch {
            self.error = error.localizedDescription
            creating = false
            Haptics.error()
        }
    }

    private func presentApplePay() {
        guard let c = checkout else { return }

        let req = PKPaymentRequest()
        req.merchantIdentifier = c.merchantIdentifier
        req.supportedNetworks = [.visa, .masterCard, .amex, .maestro]
        req.merchantCapabilities = .threeDSecure
        req.countryCode = "IT"
        req.currencyCode = c.currency
        req.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "RAVENG — Certificazione CDC",
                                 amount: NSDecimalNumber(value: c.amount))
        ]

        let ctrl = PKPaymentAuthorizationController(paymentRequest: req)
        ctrl.delegate = self
        ctrl.present { ok in
            if !ok { Task { @MainActor in self.error = "Apple Pay non disponibile su questo device." } }
        }
    }

    // MARK: PKPaymentAuthorizationControllerDelegate

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss(completion: nil)
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        guard checkout?.checkoutId != nil else {
            completion(.init(status: .failure, errors: nil)); return
        }

        // Build the payment_token dictionary expected by SumUp
        var tokenDict: [String: Any] = [:]
        if let pdJSON = try? JSONSerialization.jsonObject(with: payment.token.paymentData) {
            tokenDict["paymentData"] = pdJSON
        }
        let pm = payment.token.paymentMethod
        var pmDict: [String: Any] = [:]
        if let dn = pm.displayName { pmDict["displayName"] = dn }
        if let net = pm.network    { pmDict["network"] = net.rawValue }
        pmDict["type"] = "credit"
        tokenDict["paymentMethod"] = pmDict
        tokenDict["transactionIdentifier"] = payment.token.transactionIdentifier

        // Wrap in AnyCodable for our endpoint
        let pd = (tokenDict["paymentData"] as? [String: Any]) ?? [:]
        let pmCodable = (tokenDict["paymentMethod"] as? [String: Any]) ?? [:]
        let body = API.Cdc.ApplePayProcessBody(
            payment_token: API.Cdc.PaymentTokenDict(
                paymentData: pd.mapValues(AnyCodable.init),
                paymentMethod: pmCodable.mapValues(AnyCodable.init),
                transactionIdentifier: payment.token.transactionIdentifier
            )
        )

        let slug = self.slug
        Task {
            do {
                struct Resp: Decodable { let status: String? }
                let _: Resp = try await APIClient.shared.send(API.Cdc.processApplePay(slug: slug, body: body))
                await MainActor.run {
                    self.success = true
                    Haptics.success()
                    completion(.init(status: .success, errors: nil))
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    Haptics.error()
                    completion(.init(status: .failure, errors: [error]))
                }
            }
        }
    }
}

struct ApplePayPaymentView: View {
    let slug: String
    @StateObject private var vm: ApplePayVM
    @Environment(\.dismiss) var dismiss

    init(slug: String) {
        self.slug = slug
        _vm = StateObject(wrappedValue: ApplePayVM(slug: slug))
    }

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle().fill(BrandGradient.primary).frame(width: 96, height: 96)
                Image(systemName: "applelogo")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 32)

            Text("Pagamento sicuro Apple Pay")
                .font(BrandFont.title(20))
            Text("La certificazione CDC verrà rilasciata appena il pagamento è confermato dal tuo Wallet.")
                .multilineTextAlignment(.center)
                .font(BrandFont.body(14))
                .foregroundStyle(BrandColor.mute)
                .padding(.horizontal, 24)

            if let err = vm.error { InlineError(message: err).padding(.horizontal, 20) }
            if vm.success {
                StatusBadge(text: "Pagamento ricevuto", color: BrandColor.success)
            }

            Spacer()

            Group {
                if PKPaymentAuthorizationController.canMakePayments() {
                    GradientButton(title: vm.success ? "Chiudi" : "Paga con Apple Pay",
                                   systemImage: "applelogo",
                                   gradient: LinearGradient(
                                    colors: [BrandColor.ink, BrandColor.deepBlue],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                   ),
                                   isLoading: vm.creating) {
                        if vm.success { dismiss() }
                        else { Task { await vm.startCheckout() } }
                    }
                } else {
                    InlineError(message: "Apple Pay non disponibile. Configura una carta nel Wallet.")
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 20)
        }
    }
}
