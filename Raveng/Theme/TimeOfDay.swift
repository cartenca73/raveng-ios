import SwiftUI
import Combine

/// Time-of-day dynamic theming. Observes the current clock and
/// exposes the appropriate brand gradient stops that morph every minute.
@MainActor
final class TimeOfDay: ObservableObject {
    static let shared = TimeOfDay()

    enum Phase: String { case dawn, morning, day, afternoon, dusk, night }

    @Published var phase: Phase = .day
    @Published var updatedAt: Date = .init()

    private var timer: AnyCancellable?

    init() {
        recompute()
        // refresh every minute
        timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in self?.recompute() }
    }

    private func recompute() {
        let hour = Calendar.current.component(.hour, from: Date())
        let next: Phase = switch hour {
        case 5...6:   .dawn
        case 7...9:   .morning
        case 10...15: .day
        case 16...18: .afternoon
        case 19...21: .dusk
        default:      .night
        }
        if next != phase {
            withAnimation(.easeInOut(duration: 1.2)) { phase = next }
        }
        updatedAt = Date()
    }

    // MARK: - Brand gradient adjusted to time of day
    var heroColors: [Color] {
        switch phase {
        case .dawn:
            return [Color(hex: 0x2A1A3A), Color(hex: 0x4B2E5C), Color(hex: 0xEB5E66), Color(hex: 0xF9A26C)]
        case .morning:
            return [BrandColor.deepBlue, Color(hex: 0x1E6FB8), Color(hex: 0x3B82F6), Color(hex: 0xFFD28D)]
        case .day:
            return [BrandColor.navy, BrandColor.midBlue, BrandColor.cyan, BrandColor.brightBlue]
        case .afternoon:
            return [Color(hex: 0x123E70), Color(hex: 0x2E75B6), Color(hex: 0x6FB4F5), Color(hex: 0xFFBE5C)]
        case .dusk:
            return [Color(hex: 0x2A0E4B), Color(hex: 0x4B2E83), Color(hex: 0xE87E5F), Color(hex: 0xFDB36A)]
        case .night:
            return [Color(hex: 0x05070E), Color(hex: 0x0A1F3A), Color(hex: 0x1E3A5F), Color(hex: 0x4A7BB5)]
        }
    }

    var eyebrowLabel: String {
        switch phase {
        case .dawn:      return "ALBA"
        case .morning:   return "MATTINA"
        case .day:       return "GIORNO"
        case .afternoon: return "POMERIGGIO"
        case .dusk:      return "TRAMONTO"
        case .night:     return "NOTTE"
        }
    }

    var greeting: String {
        switch phase {
        case .dawn, .morning:  return "Buongiorno"
        case .day:             return "Ciao"
        case .afternoon:       return "Buon pomeriggio"
        case .dusk:            return "Buonasera"
        case .night:           return "Buonanotte"
        }
    }
}
