import AppIntents
import SwiftUI

// MARK: - Intent: apri firma pendenti
@available(iOS 17.0, *)
struct OpenPendingIntent: AppIntent {
    static var title: LocalizedStringResource = "Mostra documenti da firmare"
    static var description = IntentDescription("Apre la lista dei documenti in attesa di firma su FirmaCDC.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .openTab, object: 0)
        return .result()
    }
}

// MARK: - Intent: verifica documento
@available(iOS 17.0, *)
struct VerifyDocumentIntent: AppIntent {
    static var title: LocalizedStringResource = "Verifica un documento"
    static var description = IntentDescription("Apre la verifica blockchain di un PDF su FirmaCDC.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .openTab, object: 2)
        return .result()
    }
}

// MARK: - Intent: nuovo template da PDF
@available(iOS 17.0, *)
struct NewTemplateIntent: AppIntent {
    static var title: LocalizedStringResource = "Nuovo template"
    static var description = IntentDescription("Apre la creazione di un nuovo template FirmaCDC.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .openTab, object: 1)
        return .result()
    }
}

// MARK: - Shortcuts donation
@available(iOS 17.0, *)
struct FirmaCDCShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenPendingIntent(),
            phrases: [
                "Apri documenti da firmare su \(.applicationName)",
                "Mostrami i documenti in attesa su \(.applicationName)",
                "\(.applicationName) da firmare"
            ],
            shortTitle: "Da firmare",
            systemImageName: "signature"
        )
        AppShortcut(
            intent: VerifyDocumentIntent(),
            phrases: [
                "Verifica un PDF con \(.applicationName)",
                "\(.applicationName) verifica blockchain"
            ],
            shortTitle: "Verifica blockchain",
            systemImageName: "checkmark.shield.fill"
        )
        AppShortcut(
            intent: NewTemplateIntent(),
            phrases: [
                "Crea un nuovo template su \(.applicationName)",
                "\(.applicationName) nuovo template"
            ],
            shortTitle: "Nuovo template",
            systemImageName: "plus.rectangle.on.rectangle"
        )
    }
}

// MARK: - NotificationCenter names
extension Notification.Name {
    static let openTab = Notification.Name("firmacdc.openTab")
}
