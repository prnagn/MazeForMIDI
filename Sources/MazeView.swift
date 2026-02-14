import SwiftUI

public struct MazeView: View {
    @StateObject private var game = MazeGame()
    @StateObject private var midi = MIDIInputManager()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            Text("Chord Maze: Keys & Switches")
                .font(.title3).bold()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Detected: \(midi.detectedChord)")
                        .font(.headline)
                    Text("Facing: \(game.dir.glyph)   Moves: \(game.moves)   Keys: \(game.keys)")
                        .font(.subheadline)
                    Text("Bridge: \(game.bridgeEnabled ? "ON" : "OFF")")
                        .font(.subheadline)
                }
                Spacer()
                Button("Reset") { game.loadSampleLevel() }
            }
            .padding(.horizontal)
            
            Text(game.message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            gridView(cell: 28)
            
            legend
        }
        .padding()
        .onChange(of: midi.detectedChord) { _, chord in
            game.handleChord(chord)
        }
    }
    
    private func gridView(cell: CGFloat) -> some View {
        VStack(spacing: 2) {
            ForEach(0..<game.grid.count, id: \.self) { y in
                HStack(spacing: 2) {
                    ForEach(0..<game.grid[0].count, id: \.self) { x in
                        ZStack {
                            Rectangle()
                                .frame(width: cell, height: cell)
                                .foregroundStyle(color(for: game.grid[y][x]))
                            
                            if let symbol = symbol(for: game.grid[y][x]) {
                                Text(symbol).font(.system(size: cell * 0.6))
                            }
                            
                            if game.x == x && game.y == y {
                                Text(game.dir.glyph)
                                    .font(.system(size: cell * 0.8, weight: .bold))
                            }
                        }
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black.opacity(0.12), lineWidth: 1))
    }
    
    private func color(for t: Tile) -> Color {
        switch t {
        case .wall: return .gray.opacity(0.75)
        case .goal: return .green.opacity(0.7)
        case .key: return .yellow.opacity(0.75)
        case .door: return .orange.opacity(0.75)
        case .switchTile: return .purple.opacity(0.7)
        case .bridgeOff: return .black.opacity(0.25)
        case .bridgeOn: return .blue.opacity(0.6)
        default: return .white
        }
    }
    
    private func symbol(for t: Tile) -> String? {
        switch t {
        case .goal: return "🏁"
        case .key: return "🗝️"
        case .door: return "🚪"
        case .switchTile: return "🔀"
        case .bridgeOn: return "🟦"
        case .bridgeOff: return "⬛️"
        default: return nil
        }
    }
    
    private var legend: some View {
        HStack(spacing: 10) {
            Text("🗝️키")
            Text("🚪문")
            Text("🔀스위치(Am)")
            Text("🟦브리지")
            Text("🏁골")
        }
        .font(.caption)
        .padding(.top, 6)
    }
}
