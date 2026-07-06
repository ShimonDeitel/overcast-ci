import SwiftUI

/// Overcast's identity: an overcast-sky backdrop (cool slate-blue-grey) that
/// literally brightens toward a warm sunbeam-yellow accent as logged mood
/// improves — distinct from every sibling palette (no cream/amber/plum/teal/
/// violet/terracotta/graphite reuse).
enum OCTheme {
    static let backdrop = Color(red: 0.867, green: 0.882, blue: 0.898)   // overcast sky grey-blue
    static let surface = Color.white
    static let surfaceRaised = Color(red: 0.812, green: 0.831, blue: 0.855)
    static let ink = Color(red: 0.145, green: 0.169, blue: 0.204)        // storm-cloud ink
    static let inkFaded = Color(red: 0.145, green: 0.169, blue: 0.204).opacity(0.56)
    static let rule = Color.black.opacity(0.09)

    static let slate = Color(red: 0.365, green: 0.451, blue: 0.545)
    static let slateDeep = Color(red: 0.220, green: 0.298, blue: 0.400)
    static let sunbeam = Color(red: 0.984, green: 0.749, blue: 0.180)
    static let sunbeamBright = Color(red: 1.0, green: 0.827, blue: 0.235)
    static let danger = Color(red: 0.729, green: 0.290, blue: 0.243)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)

    /// Interpolates backdrop color from slate-overcast (low mood) to
    /// sunbeam-yellow (high mood), on a 1...5 scale — the literal visual
    /// hook of the app: the sky itself "clears up" as mood improves.
    static func skyColor(forMood mood: Int) -> Color {
        let t = max(0, min(1, Double(mood - 1) / 4.0))
        return Color(
            red: slate.components.r + (sunbeam.components.r - slate.components.r) * t,
            green: slate.components.g + (sunbeam.components.g - slate.components.g) * t,
            blue: slate.components.b + (sunbeam.components.b - slate.components.b) * t
        )
    }
}

private extension Color {
    var components: (r: Double, g: Double, b: Double) {
        let resolved = self.resolve(in: EnvironmentValues())
        return (Double(resolved.red), Double(resolved.green), Double(resolved.blue))
    }
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
