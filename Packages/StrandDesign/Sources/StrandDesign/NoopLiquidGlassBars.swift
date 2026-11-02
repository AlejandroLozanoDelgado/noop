import SwiftUI

// MARK: - Liquid Glass bars and floating surfaces
//
// Companions to `NoopLiquidGlassSearchField.swift` for the functional layer: a bar pinned to the bottom
// of a scrolling screen, and a floating capsule that sits above content. iOS 26 uses the system
// pieces (`safeAreaBar` + scroll edge effect, `glassEffect`); macOS and older iOS keep the previous
// material surfaces unchanged. Glass APIs stay behind `#if os(iOS)` so macOS (deployment 13) never
// type-checks them.

public extension View {
    /// Pins `bar` under this scrolling content. iOS 26 attaches it with `safeAreaBar`, so it joins the
    /// system scroll edge effect; the hard style gives the bar's labels a backing even at rest. macOS and
    /// older iOS stack it below the content on the thin material with a top hairline, as before.
    ///
    /// Not for a bar holding a focused `TextField`: `@FocusState` does not work inside `safeAreaBar`
    /// (iOS 26.1 known issue), so such a bar keeps `safeAreaInset`.
    @ViewBuilder
    func noopPinnedBottomBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            self
                .scrollEdgeEffectStyle(.hard, for: .bottom)
                .safeAreaBar(edge: .bottom, spacing: 0) { bar() }
        } else {
            noopLegacyBottomBar(bar())
        }
        #else
        noopLegacyBottomBar(bar())
        #endif
    }

    /// Floating capsule surface for a tappable control above content (e.g. the running-session bar over
    /// the tab bar). iOS 26 uses interactive Liquid Glass; the stage colour stays on the bar's own icon
    /// and clock rather than on the glass. macOS and older iOS keep the thin material with a tinted stroke.
    @ViewBuilder
    func noopFloatingGlassCapsule(fallbackStroke: Color) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            noopLegacyFloatingCapsule(stroke: fallbackStroke)
        }
        #else
        noopLegacyFloatingCapsule(stroke: fallbackStroke)
        #endif
    }

    /// Wraps a row of neighbouring glass controls in one `GlassEffectContainer` on iOS 26, so they render
    /// together and sample the same backdrop (glass cannot sample other glass). `spacing` is the blend
    /// distance: keep it below the row's own gap so the controls stay separate shapes. No-op elsewhere.
    @ViewBuilder
    func noopGlassGroup(spacing: CGFloat = 0) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { self }
        } else {
            self
        }
        #else
        self
        #endif
    }

    private func noopLegacyBottomBar<Bar: View>(_ bar: Bar) -> some View {
        VStack(spacing: 0) {
            self
            bar
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle().fill(StrandPalette.textTertiary.opacity(0.15)).frame(height: 0.5)
                }
        }
    }

    private func noopLegacyFloatingCapsule(stroke: Color) -> some View {
        self
            .background(.ultraThinMaterial, in: Capsule())
            .overlay { Capsule().stroke(stroke.opacity(0.35), lineWidth: 1) }
    }
}
