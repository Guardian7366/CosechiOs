// ConfettiView.swift
import SwiftUI

struct ConfettiView: View {
    @State private var particles: [Particle] = []
    let colors: [Color] = [
        .red, .green, .blue, .yellow, .purple, .orange,
        .mint, .pink, .teal
    ]

    var body: some View {
        ZStack {
            // Fondo Aero translúcido
            LinearGradient(
                colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Confeti
            ForEach(particles) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [particle.color, particle.color.opacity(0.4)],
                            center: .center,
                            startRadius: 0,
                            endRadius: particle.size
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .shadow(color: particle.color.opacity(0.6), radius: 4, x: 0, y: 2)
            }
        }
        .onAppear {
            emitConfetti()
        }
    }

    private func emitConfetti() {
        for i in 0..<50 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                let newParticle = Particle(
                    id: UUID(),
                    position: CGPoint(
                        x: UIScreen.main.bounds.width / 2,
                        y: UIScreen.main.bounds.height / 2
                    ),
                    color: colors.randomElement() ?? .blue,
                    size: CGFloat.random(in: 10...18),
                    opacity: 1.0,
                    velocity: CGSize(
                        width: CGFloat.random(in: -160...160),
                        height: CGFloat.random(in: -220...0)
                    )
                )
                particles.append(newParticle)
                animate(particleID: newParticle.id)
            }
        }
    }

    // ⬇️ mantener fileprivate para evitar errores de acceso
    fileprivate func animate(particleID: UUID) {
        guard let index = particles.firstIndex(where: { $0.id == particleID }) else { return }
        withAnimation(.easeOut(duration: 2.2)) {
            particles[index].position.x += particles[index].velocity.width
            particles[index].position.y += particles[index].velocity.height
            particles[index].opacity = 0
        }
    }
}

fileprivate struct Particle: Identifiable {
    let id: UUID
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
    let velocity: CGSize
}
