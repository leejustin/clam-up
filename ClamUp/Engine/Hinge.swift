import SwiftUI
import UIKit

/// A device-independent view of the hinge, so the rest of the app doesn't care which OS it runs on.
struct HingeReading: Equatable {
    enum Status: Equatable {
        case unavailable, closed, partiallyOpen, fullyOpen

        var isOpen: Bool { self == .partiallyOpen || self == .fullyOpen }
    }

    var status: Status
    var degrees: Double?

    static let unavailable = HingeReading(status: .unavailable, degrees: nil)
}

@available(iOS 27.1, *)
extension HingeReading {
    init(_ hinge: UIHinge?) {
        guard let hinge else {
            self = .unavailable
            return
        }
        let status: Status = switch hinge.status {
        case .closed: .closed
        case .partiallyOpen: .partiallyOpen
        case .fullyOpen: .fullyOpen
        default: .unavailable
        }
        self.init(status: status, degrees: Double(hinge.angle) * 180 / .pi)
    }
}

/// An invisible view that reports hinge changes. UIKit's interaction delivers the initial state as well as every change.
@available(iOS 27.1, *)
private struct HingeProbe: UIViewRepresentable {
    var onChange: (HingeReading) -> Void

    final class Coordinator {
        var onChange: (HingeReading) -> Void
        init(onChange: @escaping (HingeReading) -> Void) { self.onChange = onChange }
    }

    func makeCoordinator() -> Coordinator { Coordinator(onChange: onChange) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        let coordinator = context.coordinator
        let interaction = UIHingeInteraction { _, update in
            coordinator.onChange(HingeReading(update.hinge))
        }
        view.addInteraction(interaction)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onChange = onChange
    }
}

extension View {
    /// Calls `action` with the current hinge state and on every change. Does nothing on devices without a hinge.
    @ViewBuilder
    func onHinge(_ action: @escaping (HingeReading) -> Void) -> some View {
        if #available(iOS 27.1, *) {
            background(HingeProbe(onChange: action).allowsHitTesting(false))
        } else {
            self
        }
    }
}
