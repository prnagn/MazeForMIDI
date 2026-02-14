import Foundation
import Combine

public final class MazeGame: ObservableObject {
    @Published public private(set) var grid: [[Tile]] = []
    @Published public private(set) var x: Int = 1
    @Published public private(set) var y: Int = 1
    @Published public private(set) var dir: Dir = .right
    @Published public private(set) var moves: Int = 0
    @Published public private(set) var keys: Int = 0
    @Published public private(set) var bridgeEnabled: Bool = false
    @Published public private(set) var message: String = "C=전진, F=좌회전, G=우회전, Am=액션(스위치)"
    
    private struct Snapshot {
        let x: Int; let y: Int; let dir: Dir
        let keys: Int; let bridgeEnabled: Bool
        let grid: [[Tile]]
    }
    private var history: [Snapshot] = []
    
    // 입력 안정화(연타/유지 중복 방지)
    private var lastCommandAt: Date = .distantPast
    private var lastChord: String = ""
    private let cooldown: TimeInterval = 0.18
    
    public init() {
        loadSampleLevel()
    }
    
    public func loadSampleLevel() {
        // 10x10 예시 레벨
        // 0=길 1=벽 2=골 3=키 4=문 5=스위치 6=브리지OFF(스위치로 ON)
        let raw: [[Int]] = [
            [1,1,1,1,1,1,1,1,1,1],
            [1,0,0,0,1,0,3,0,2,1],
            [1,0,1,0,1,0,1,0,1,1],
            [1,0,1,0,0,0,1,0,0,1],
            [1,0,1,1,1,0,1,1,0,1],
            [1,0,0,4,1,0,0,0,0,1],
            [1,1,1,0,1,1,1,1,6,1],
            [1,5,0,0,0,0,0,1,6,1],
            [1,0,1,1,1,1,0,0,0,1],
            [1,1,1,1,1,1,1,1,1,1],
        ]
        
        self.grid = raw.map { row in row.map { Tile(rawValue: $0)! } }
        resetPlayerOnly()
        self.message = "C=전진, F=좌회전, G=우회전, Am=액션(스위치)"
    }
    
    public func resetPlayerOnly() {
        x = 1; y = 1; dir = .right
        moves = 0
        keys = 0
        bridgeEnabled = false
        history.removeAll()
        lastChord = ""
        lastCommandAt = .distantPast
    }
    
    private var isGoal: Bool { grid[y][x] == .goal }
    
    public func handleChord(_ chord: String) {
        guard chord != "—" else { return }
        guard !isGoal else { return }
        
        let now = Date()
        
        // 같은 코드 유지로 연속 들어오는 경우 방지
        if chord == lastChord, now.timeIntervalSince(lastCommandAt) < 0.35 { return }
        // 전체 쿨다운
        guard now.timeIntervalSince(lastCommandAt) >= cooldown else { return }
        
        lastCommandAt = now
        lastChord = chord
        
        switch chord {
        case "F":
            dir = dir.left()
            moves += 1
        case "G":
            dir = dir.right()
            moves += 1
        case "C":
            forward()
        case "Am":
            action()
        default:
            break
        }
        
        if isGoal {
            message = "🎉 골인! Moves: \(moves), Keys: \(keys)"
        }
    }
    
    private func saveSnapshot() {
        history.append(Snapshot(x: x, y: y, dir: dir, keys: keys, bridgeEnabled: bridgeEnabled, grid: grid))
    }
    
    private func undoSnapshot() {
        guard let s = history.popLast() else { return }
        x = s.x; y = s.y; dir = s.dir
        keys = s.keys
        bridgeEnabled = s.bridgeEnabled
        grid = s.grid
    }
    
    private func forward() {
        saveSnapshot()
        
        let d = dir.delta
        let nx = x + d.dx
        let ny = y + d.dy
        guard inside(nx, ny) else { undoSnapshot(); return }
        
        let next = grid[ny][nx]
        
        switch next {
        case .wall:
            undoSnapshot()
            return
            
        case .bridgeOff:
            if !bridgeEnabled {
                undoSnapshot()
                return
            }
            x = nx; y = ny
            
        case .door:
            guard keys > 0 else {
                message = "🔒 문! 키가 필요해."
                undoSnapshot()
                return
            }
            keys -= 1
            grid[ny][nx] = .path
            x = nx; y = ny
            
        case .key:
            keys += 1
            grid[ny][nx] = .path
            x = nx; y = ny
            message = "🗝️ 키 획득! (Keys: \(keys))"
            
        default:
            x = nx; y = ny
        }
        
        moves += 1
    }
    
    private func action() {
        guard grid[y][x] == .switchTile else {
            message = "…(스위치 위에서 Am)"
            return
        }
        
        saveSnapshot()
        bridgeEnabled.toggle()
        
        // 브리지 표시를 토글 상태에 맞게 바꿔서 UI 직관화
        for yy in 0..<grid.count {
            for xx in 0..<grid[0].count {
                if grid[yy][xx] == .bridgeOff || grid[yy][xx] == .bridgeOn {
                    grid[yy][xx] = bridgeEnabled ? .bridgeOn : .bridgeOff
                }
            }
        }
        
        moves += 1
        message = bridgeEnabled ? "🟦 브리지 ON" : "⬛️ 브리지 OFF"
    }
    
    private func inside(_ x: Int, _ y: Int) -> Bool {
        y >= 0 && y < grid.count && x >= 0 && x < grid[0].count
    }
}
