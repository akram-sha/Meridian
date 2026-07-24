import Foundation
import Testing
@testable import Core

struct WaveHeightTests {

    // MARK: - Decoding validation

    @Test func decodeNegativeMetersThrows() {
        let data = Data(#"{"meters":-0.5}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(WaveHeight.self, from: data)
        }
    }

    @Test func validValueRoundTripsThroughEncodeDecode() throws {
        let encoded = try JSONEncoder().encode(WaveHeight(meters: 0.3))
        let decoded = try JSONDecoder().decode(WaveHeight.self, from: encoded)
        #expect(decoded.inMeters == 0.3)
    }

    // MARK: swimmingSafety — lower-bound boundaries
    // Each test pins the exact value where the category flips,
    // so a threshold change in WaveHeight will break exactly one test.

    @Test func waveBelowHalfMeterIsCalm() {
        #expect(WaveHeight(meters: 0.49).swimmingSafety == .calm)
    }

    @Test func waveAtExactHalfMeterIsModerateNotCalm() {
        #expect(WaveHeight(meters: 0.5).swimmingSafety == .moderate)
    }

    @Test func waveJustBelowOneMeterIsModerate() {
        #expect(WaveHeight(meters: 0.99).swimmingSafety == .moderate)
    }

    @Test func waveAtExactOneMeterIsConcerningNotModerate() {
        #expect(WaveHeight(meters: 1.0).swimmingSafety == .concerning)
    }

    @Test func waveJustBelowTwoMetersIsConcerning() {
        #expect(WaveHeight(meters: 1.99).swimmingSafety == .concerning)
    }

    @Test func waveAtExactTwoMetersIsDangerousNotConcerning() {
        #expect(WaveHeight(meters: 2.0).swimmingSafety == .dangerous)
    }

    @Test func waveWellAboveTwoMetersIsDangerous() {
        #expect(WaveHeight(meters: 4.0).swimmingSafety == .dangerous)
    }

    // MARK: unit conversions

    @Test func inMetersReturnsStoredValue() {
        #expect(WaveHeight(meters: 1.5).inMeters == 1.5)
    }

    // 1 m × 3.28084 = 3.28084 ft
    @Test func inFeetConversionIsCorrect() {
        #expect(abs(WaveHeight(meters: 1.0).inFeet - 3.28084) < 0.00001)
    }
}