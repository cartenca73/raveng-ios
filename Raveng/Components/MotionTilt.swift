import SwiftUI
import CoreMotion

/// Subtly tilts a view in 3D using the gyroscope (like Apple Wallet cards).
@MainActor
final class MotionManager: ObservableObject {
    static let shared = MotionManager()

    @Published var pitch: Double = 0
    @Published var roll: Double = 0

    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] m, _ in
            guard let self, let m else { return }
            // low-pass filter
            let alpha = 0.15
            self.pitch = alpha * m.attitude.pitch + (1 - alpha) * self.pitch
            self.roll  = alpha * m.attitude.roll  + (1 - alpha) * self.roll
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}

struct TiltModifier: ViewModifier {
    @ObservedObject private var motion = MotionManager.shared
    var intensity: Double = 6 // gradi massimi

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(motion.roll * intensity),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.6
            )
            .rotation3DEffect(
                .degrees(motion.pitch * intensity * -1),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.6
            )
            .onAppear { motion.start() }
    }
}

extension View {
    /// Apply subtle gyroscope-driven tilt. Intensity 4=subtle, 8=medium, 12=strong.
    func motionTilt(intensity: Double = 6) -> some View {
        modifier(TiltModifier(intensity: intensity))
    }
}
