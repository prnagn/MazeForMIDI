import Foundation

public struct ChordDetector {
    // C=0, C#=1 ... B=11
    public static let noteNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
    
    /// pitchClasses: 현재 눌린 노트들의 피치클래스(0~11) 집합
    /// activeNotes: 실제 MIDI 노트넘버(0~127) 집합 (베이스 판단용)
    public static func detect(pitchClasses: Set<Int>, activeNotes: Set<Int>) -> String? {
        guard pitchClasses.count >= 3 else { return nil }
        
        // 베이스(가장 낮은 음)를 우선 루트로
        let bass = activeNotes.min() ?? 60
        let bassPC = bass % 12
        let candidates = [bassPC] + (0..<12).filter { $0 != bassPC }
        
        for root in candidates {
            if isMajorTriad(root: root, pcs: pitchClasses) { return "\(noteNames[root])" }
            if isMinorTriad(root: root, pcs: pitchClasses) { return "\(noteNames[root])m" }
        }
        return nil
    }
    
    private static func isMajorTriad(root: Int, pcs: Set<Int>) -> Bool {
        let triad: Set<Int> = [root, (root + 4) % 12, (root + 7) % 12]
        return triad.isSubset(of: pcs)
    }
    
    private static func isMinorTriad(root: Int, pcs: Set<Int>) -> Bool {
        let triad: Set<Int> = [root, (root + 3) % 12, (root + 7) % 12]
        return triad.isSubset(of: pcs)
    }
}
