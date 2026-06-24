import Testing
@testable import Core

struct WaveHeightTests {

    // MARK: swimmingSafety — lower-bound boundaries
    // Each test pins the exact value where the category flips,
    // so a threshold change in WaveHeight will break exactly one test.

    @Test func waveBelowHalfMetreIsCalm() {
        #expect(WaveHeight(metres: 0.49).swimmingSafety == .calm)
    }

    @Test func waveAtExactHalfMetreIsModerateNotCalm() {
        #expect(WaveHeight(metres: 0.5).swimmingSafety == .moderate)
    }

    @Test func waveJustBelowOneMetreIsModerate() {
        #expect(WaveHeight(metres: 0.99).swimmingSafety == .moderate)
    }

    @Test func waveAtExactOneMetreIsConcerningNotModerate() {
        #expect(WaveHeight(metres: 1.0).swimmingSafety == .concerning)
    }

    @Test func waveJustBelowTwoMetresIsConcerning() {
        #expect(WaveHeight(metres: 1.99).swimmingSafety == .concerning)
    }

    @Test func waveAtExactTwoMetresIsDangerousNotConcerning() {
        #expect(WaveHeight(metres: 2.0).swimmingSafety == .dangerous)
    }

    @Test func waveWellAboveTwoMetresIsDangerous() {
        #expect(WaveHeight(metres: 4.0).swimmingSafety == .dangerous)
    }

    // MARK: unit conversions

    @Test func inMetresReturnsStoredValue() {
        #expect(WaveHeight(metres: 1.5).inMetres == 1.5)
    }

    // 1 m × 3.28084 = 3.28084 ft
    @Test func inFeetConversionIsCorrect() {
        #expect(abs(WaveHeight(metres: 1.0).inFeet - 3.28084) < 0.00001)
    }
}