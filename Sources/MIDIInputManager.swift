import Foundation
import CoreMIDI
import Combine

public final class MIDIInputManager: ObservableObject {
    @Published public private(set) var activeNotes: Set<Int> = []   // MIDI note numbers
    @Published public private(set) var detectedChord: String = "—"
    
    private var client = MIDIClientRef()
    private var inputPort = MIDIPortRef()
    private var sources: [MIDIEndpointRef] = []
    
    private let queue = DispatchQueue(label: "midi.queue")
    private var debounceWorkItem: DispatchWorkItem?
    
    // 게임에서 쓸 코드만 좁히면 오인식이 훨씬 줄어듦
    private let allowedChords: Set<String> = ["C", "F", "G", "Am"]
    
    public init() {
        setupMIDI()
    }
    
    private func setupMIDI() {
        MIDIClientCreateWithBlock("PlaygroundMIDIClient" as CFString, &client) { _ in }
        
        MIDIInputPortCreateWithBlock(client, "InputPort" as CFString, &inputPort) { [weak self] packetList, _ in
            guard let self else { return }
            self.handle(packetList: packetList.pointee)
        }
        
        refreshSourcesAndConnect()
    }
    
    private func refreshSourcesAndConnect() {
        sources.removeAll()
        let count = MIDIGetNumberOfSources()
        for i in 0..<count {
            let src = MIDIGetSource(i)
            sources.append(src)
            MIDIPortConnectSource(inputPort, src, nil)
        }
    }
    
    private func handle(packetList: MIDIPacketList) {
        queue.async {
            var packet = packetList.packet
            for _ in 0..<packetList.numPackets {
                let data = self.packetData(packet)
                self.parseMIDIBytes(data)
                packet = MIDIPacketNext(&packet).pointee
            }
        }
    }
    
    private func packetData(_ packet: MIDIPacket) -> [UInt8] {
        // packet.data는 튜플처럼 보이므로 Mirror로 꺼내기
        let children = Mirror(reflecting: packet.data).children
        return children.prefix(Int(packet.length)).map { UInt8($0.value as! UInt8) }
    }
    
    private func parseMIDIBytes(_ data: [UInt8]) {
        guard data.count >= 3 else { return }
        
        let status = data[0] & 0xF0
        let note = Int(data[1])
        let vel  = Int(data[2])
        
        // NoteOn(0x90) vel>0, NoteOff(0x80) 또는 NoteOn vel=0
        if status == 0x90, vel > 0 {
            activeNotes.insert(note)
            scheduleChordDetection()
        } else if status == 0x80 || (status == 0x90 && vel == 0) {
            activeNotes.remove(note)
            scheduleChordDetection()
        }
    }
    
    private func scheduleChordDetection() {
        debounceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.detectChordNow()
        }
        debounceWorkItem = work
        queue.asyncAfter(deadline: .now() + 0.10, execute: work) // 100ms 디바운스
    }
    
    private func detectChordNow() {
        let pcs = Set(activeNotes.map { $0 % 12 })
        let chord = ChordDetector.detect(pitchClasses: pcs, activeNotes: activeNotes)
        
        let filtered: String
        if let chord, allowedChords.contains(chord) {
            filtered = chord
        } else {
            filtered = "—"
        }
        
        DispatchQueue.main.async {
            self.detectedChord = filtered
        }
    }
}

