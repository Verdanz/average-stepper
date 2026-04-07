import SwiftUI

/// Soft, wellness-oriented burst — not toy-like.
struct CelebrationConfettiView: View {
    private struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat
        let drift: CGFloat
        let size: CGFloat
    }

    @State private var pieces: [Piece] = []
    @State private var phase: CGFloat = 0

    private let palette: [Color] = [
        Color(red: 0.42, green: 0.62, blue: 0.58),
        Color(red: 0.82, green: 0.70, blue: 0.52),
        Color(red: 0.52, green: 0.56, blue: 0.62),
        Color(red: 0.65, green: 0.72, blue: 0.68)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(pieces.enumerated()), id: \.element.id) { index, piece in
                    Circle()
                        .fill(palette[index % palette.count].opacity(0.45))
                        .frame(width: piece.size, height: piece.size)
                        .offset(
                            x: piece.x + piece.drift * phase,
                            y: geo.size.height * 0.35 * phase + CGFloat(index % 4) * 6
                        )
                        .opacity(1 - 0.55 * phase)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                let w = geo.size.width
                pieces = (0..<32).map { _ in
                    Piece(
                        x: CGFloat.random(in: -w * 0.45 ... w * 0.45),
                        drift: CGFloat.random(in: -18 ... 18),
                        size: CGFloat.random(in: 4 ... 9)
                    )
                }
                withAnimation(.easeOut(duration: 1.35)) {
                    phase = 1
                }
            }
        }
        .allowsHitTesting(false)
    }
}
