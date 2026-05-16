//
//  ConfettiBurst.swift
//  FreeHabits
//

import SwiftUI

// MARK: - Particle model

private struct Particle: Identifiable {
    let id = UUID()
    /// Angle in radians pointing away from centre.
    let angle: Double
    /// How far the particle travels (pt).
    let radius: Double
    /// Random rotation of the shape itself.
    let spin: Double
    /// 0 = dot, 1 = slash, 2 = star
    let shape: Int
    let color: Color
}

// MARK: - ConfettiBurst

/// Overlays a one-shot particle burst centred on its parent view.
/// Set `trigger` to `true` to fire; it resets itself once done.
struct ConfettiBurst: View {
    /// Bind to a Bool that you flip to `true` to fire the burst.
    @Binding var trigger: Bool
    /// Tint used for the particles — pass the habit's colour.
    var color: Color = .yellow

    @State private var particles: [Particle] = []
    @State private var progress: Double = 0          // 0 → 1 over lifetime
    @State private var isAnimating = false

    private let particleCount = 18
    private let lifetime: Double = 0.65              // seconds

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                particleShape(p)
                    .frame(width: shapeSize(p), height: shapeSize(p))
                    .foregroundStyle(p.color)
                    // Fan outward
                    .offset(x: isAnimating ? cos(p.angle) * p.radius : 0,
                            y: isAnimating ? sin(p.angle) * p.radius : 0)
                    // Spin + shrink + fade
                    .rotationEffect(.radians(isAnimating ? p.spin : 0))
                    .scaleEffect(isAnimating ? 0.1 : 1.0)
                    .opacity(isAnimating ? 0.0 : 1.0)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            guard newValue else { return }
            fire()
        }
    }

    // MARK: Helpers

    @ViewBuilder
    private func particleShape(_ p: Particle) -> some View {
        switch p.shape {
        case 1:
            Capsule()           // slash
                .frame(width: 5, height: 12)
        case 2:
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
        default:
            Circle()            // dot
        }
    }

    private func shapeSize(_ p: Particle) -> CGFloat {
        p.shape == 1 ? 12 : 10
    }

    private func fire() {
        // Build fresh particles
        particles = (0..<particleCount).map { i in
            let angle = Double(i) / Double(particleCount) * .pi * 2 + Double.random(in: -0.2...0.2)
            let radius = Double.random(in: 28...56)
            // Alternate between habit colour, white, and a lighter tint
            let colors: [Color] = [color, color.opacity(0.7), .white, color.mix(with: .white, by: 0.4)]
            return Particle(
                angle: angle,
                radius: radius,
                spin: Double.random(in: -3...3),
                shape: Int.random(in: 0...2),
                color: colors[i % colors.count]
            )
        }

        isAnimating = false
        progress = 0

        withAnimation(.easeOut(duration: lifetime)) {
            isAnimating = true
        }

        // Reset trigger and clean up particles after the animation ends
        DispatchQueue.main.asyncAfter(deadline: .now() + lifetime + 0.05) {
            trigger = false
            particles = []
            isAnimating = false
        }
    }
}
