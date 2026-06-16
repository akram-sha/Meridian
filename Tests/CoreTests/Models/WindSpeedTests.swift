import Testing
@testable import Core

@Suite("WindSpeed")
struct WindSpeedTests {

    // MARK: — Unit conversions
    @Test("km/h roundtrip")
    func kmhRoundtrip() {
        let wind = WindSpeed(kmh: 30.0)
        #expect(wind.inKmh == 30.0)
    }

    @Test("knots conversion")
    func knotsConversion() {
        let wind = WindSpeed(kmh: 18.52)
        #expect(abs(wind.inKnots - 10.0) < 0.01)
    }

    @Test("mph conversion")
    func mphConversion() {
        let wind = WindSpeed(kmh: 16.09344)
        #expect(abs(wind.inMph - 10.0) < 0.001)
    }

    @Test("m/s conversion")
    func msConversion() {
        let wind = WindSpeed(kmh: 36.0)
        #expect(abs(wind.inMs - 10.0) < 0.001)
    }

    // MARK: — Safety boundaries
    @Test("Below 15 is calm")
    func calmBoundary() {
        #expect(WindSpeed(kmh: 0).swimmingSafety   == .calm)
        #expect(WindSpeed(kmh: 14.9).swimmingSafety == .calm)
    }

    @Test("15 is the start of moderate")
    func moderateLowerBoundary() {
        #expect(WindSpeed(kmh: 15.0).swimmingSafety == .moderate)
    }

    @Test("27.9 is still moderate")
    func moderateUpperBoundary() {
        #expect(WindSpeed(kmh: 27.9).swimmingSafety == .moderate)
    }

    @Test("28 is the start of concerning")
    func concerningLowerBoundary() {
        #expect(WindSpeed(kmh: 28.0).swimmingSafety == .concerning)
    }

    @Test("38.9 is still concerning")
    func concerningUpperBoundary() {
        #expect(WindSpeed(kmh: 38.9).swimmingSafety == .concerning)
    }

    @Test("39 is the hard cutoff — dangerous")
    func dangerousLowerBoundary() {
        #expect(WindSpeed(kmh: 39.0).swimmingSafety == .dangerous)
    }

    @Test("Well above 39 is still dangerous")
    func dangerousHighEnd() {
        #expect(WindSpeed(kmh: 80.0).swimmingSafety == .dangerous)
    }
}