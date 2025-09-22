// FrutigerAeroUI.swift
// Componentes y estilos Frutiger Aero (listas para usar)
//

import SwiftUI

// MARK: - Theme manager (soft / neon)
public enum AeroVariant { case soft, neon }

public final class AeroTheme: ObservableObject {
    @Published public var variant: AeroVariant = .soft
    public init(variant: AeroVariant = .soft) { self.variant = variant }

    public var primaryStart: Color {
        variant == .soft ? Color(hex: "00A8FF") : Color(hex: "00D4FF")
    }
    public var primaryEnd: Color {
        variant == .soft ? Color(hex: "00D4FF") : Color(hex: "00F0FF")
    }
    public var accent: Color {
        variant == .soft ? Color(hex: "FF8C42") : Color(hex: "FFB26B")
    }
    public var mint: Color { Color(hex: "00C37A") }

    // Fondo "fondo fondo" — agradable y no intrusivo
    public var bgGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "A1C4FD").opacity(0.95), // azul suave
                Color(hex: "C2E9FB").opacity(0.92), // celeste
                Color.white.opacity(0.92)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var strongBgGradient: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [primaryStart, primaryEnd]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Color hex initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Background wrapper view (usa theme desde environmentObject)
public struct FrutigerAeroBackground<Content: View>: View {
    @EnvironmentObject var theme: AeroTheme
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack {
            theme.bgGradient
                .ignoresSafeArea()

            BubbleOverlay()
                .opacity(theme.variant == .neon ? 0.12 : 0.06)
                .ignoresSafeArea()

            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.0), Color.black.opacity(0.02)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .blendMode(.overlay)

            content
                .accentColor(theme.accent)
        }
    }
}

// Helper para usar como modifier (pero cuidado con el orden de modifiers)
public extension View {
    func frutigerAeroBackground() -> some View {
        FrutigerAeroBackground { self }
    }
}

// MARK: - GlassCard: reusable card with glass effect
public struct GlassCard<Content: View>: View {
    @EnvironmentObject var theme: AeroTheme
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(theme.strongBgGradient.opacity(0.045))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        .blendMode(.overlay)
                )

            content
                .padding()
        }
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Button style for Aero look
public struct AeroButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: AeroTheme
    var filled: Bool = true

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background {
                if filled {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(gradient: Gradient(colors: [theme.primaryStart, theme.primaryEnd]), startPoint: .topLeading, endPoint: .bottomTrailing))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06)))
                }
            }
            .foregroundColor(filled ? Color.white : theme.primaryStart)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: filled ? theme.primaryStart.opacity(0.16) : Color.black.opacity(0.02), radius: configuration.isPressed ? 2 : 6, x: 0, y: 4)
    }
}

// MARK: - Icon helper
public extension Image {
    func aeroIconStyle(size: CGFloat = 28) -> some View {
        self
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Decorative bubble overlay
public struct BubbleOverlay: View {
    @State private var anim = false
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Circle().fill(Color.white.opacity(0.06)).frame(width: min(w,h)*0.7).offset(x: -w*0.15, y: -h*0.35).blur(radius: 20)
                Circle().fill(Color.white.opacity(0.03)).frame(width: min(w,h)*0.5).offset(x: w*0.35, y: -h*0.1).blur(radius: 18)
                Circle().fill(Color.white.opacity(0.02)).frame(width: min(w,h)*0.4).offset(x: -w*0.4, y: h*0.4).blur(radius: 22)
            }
            .compositingGroup()
            .blendMode(.overlay)
            .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: anim)
            .onAppear { anim = true }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Small header component
public struct AeroHeader: View {
    @EnvironmentObject var theme: AeroTheme
    let title: String
    let subtitle: String?
    public init(_ title: String, subtitle: String? = nil) { self.title = title; self.subtitle = subtitle }
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.title2).bold()
            if let s = subtitle { Text(s).font(.caption).foregroundColor(.secondary) }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - AeroTextField: estilo para campos de texto
public struct AeroTextField: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.4),
                                        Color.clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
}

// ✅ Helper para aplicar fácilmente
public extension View {
    func aeroTextField() -> some View {
        self.modifier(AeroTextField())
    }
}
