// ConfettiView.swift
import SwiftUI

struct ConfettiView: View {
    @State private var particles: [Particle] = []
    let colors: [Color] = [.red, .green, .blue, .yellow, .purple, .orange]

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            emitConfetti()
        }
    }

    private func emitConfetti() {
        for i in 0..<50 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                let newParticle = Particle(
                    id: UUID(),
                    position: CGPoint(x: UIScreen.main.bounds.width / 2,
                                      y: UIScreen.main.bounds.height / 2),
                    color: colors.randomElement() ?? .blue,
                    size: CGFloat.random(in: 8...16),
                    opacity: 1.0,
                    velocity: CGSize(
                        width: CGFloat.random(in: -150...150),
                        height: CGFloat.random(in: -200...0)
                    )
                )
                particles.append(newParticle)
                animate(particleID: newParticle.id)
            }
        }
    }

    // ⬇️ estos métodos deben ser fileprivate (no private) para evitar errores
    fileprivate func animate(particleID: UUID) {
        guard let index = particles.firstIndex(where: { $0.id == particleID }) else { return }
        withAnimation(.easeOut(duration: 2)) {
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
