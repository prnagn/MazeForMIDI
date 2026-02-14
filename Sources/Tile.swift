import Foundation

public enum Dir: Int {
    case up, right, down, left
    
    public func left() -> Dir  { Dir(rawValue: (rawValue + 3) % 4)! }
    public func right() -> Dir { Dir(rawValue: (rawValue + 1) % 4)! }
    
    public var delta: (dx: Int, dy: Int) {
        switch self {
        case .up: return (0, -1)
        case .right: return (1, 0)
        case .down: return (0, 1)
        case .left: return (-1, 0)
        }
    }
    
    public var glyph: String { ["↑","→","↓","←"][rawValue] }
}

public enum Tile: Int {
    case path = 0
    case wall = 1
    case goal = 2
    case key = 3
    case door = 4
    case switchTile = 5
    case bridgeOff = 6
    case bridgeOn = 7
}
