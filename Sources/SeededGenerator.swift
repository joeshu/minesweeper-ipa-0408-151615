import Foundation

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed == 0 ? 0x123456789abcdef : seed
    }
    
    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}

func stableDailySeed(for date: Date = Date()) -> UInt64 {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
    formatter.dateFormat = "yyyyMMdd"
    let text = formatter.string(from: date)
    return UInt64(text) ?? 20260410
}
