import Foundation
import Testing
@testable import Core

@Suite("UVIndex")
struct UVIndexTests {

    // MARK: - Decoding validation

    @Test("Decoding a negative value throws DecodingError")
    func decodeNegativeThrows() {
        let data = Data(#"{"raw":-1.0}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(UVIndex.self, from: data)
        }
    }

    @Test("A valid value round-trips through encode/decode")
    func validValueRoundTrips() throws {
        let encoded = try JSONEncoder().encode(UVIndex(value: 6.8))
        let decoded = try JSONDecoder().decode(UVIndex.self, from: encoded)
        #expect(decoded.value == 6.8)
    }

    @Test("Raw value is preserved")
    func rawValueRoundtrip() {
        let uv = UVIndex(value: 5.3)
        #expect(uv.value == 5.3)
    }

    // Severity boundaries
    @Test("Below 3 is low")
    func lowSeverity() {
        #expect(UVIndex(value: 0).severity == .low)
        #expect(UVIndex(value: 2.9).severity == .low)
    }

    @Test("3 is the start of moderate")
    func moderateLowerBoundary() {
        #expect(UVIndex(value: 3.0).severity == .moderate)
    }

    @Test("5.9 is still moderate")
    func moderateUpperBoundary() {
        #expect(UVIndex(value: 5.9).severity == .moderate)
    }

    @Test("6 is the start of high")
    func highLowerBoundary() {
        #expect(UVIndex(value: 6.0).severity == .high)
    }

    // Previously untested: nothing pinned the high/veryHigh boundary from the "high" side
    // (only veryHighLowerBoundary below tests 8.0 from the veryHigh side). A mutation
    // narrowing `case 6..<8` to e.g. `6..<7` would have fallen through to the
    // "unreachable" default branch (.extreme) for 7.9, and no existing test would catch it.
    @Test("7.9 is still high, not veryHigh")
    func highUpperBoundary() {
        #expect(UVIndex(value: 7.9).severity == .high)
    }

    @Test("UV above 8 and less than 11 is very high")
    func veryHighLowerBoundary() {
        #expect(UVIndex(value: 8.0).severity  == .veryHigh)
        #expect(UVIndex(value: 10.9).severity == .veryHigh)
    }

    @Test("11 and above is extreme")
    func extremeSeverity() {
        #expect(UVIndex(value: 11.0).severity == .extreme)
        #expect(UVIndex(value: 15.0).severity == .extreme)
    }
}