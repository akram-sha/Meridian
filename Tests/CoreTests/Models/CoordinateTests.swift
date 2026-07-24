import Testing
@testable import Core

@Suite("Coordinate")
struct CoordinateTests {

    // MARK: - Privacy rounding

    @Test("Input is rounded to two decimal places at construction")
    func roundsToTwoDecimalPlaces() throws {
        let coordinate = try Coordinate(latitude: 52.3717, longitude: 4.5333)
        #expect(coordinate.latitude  == 52.37)
        #expect(coordinate.longitude == 4.53)
    }

    @Test("Two-decimal input is stored unchanged")
    func twoDecimalInputUnchanged() throws {
        let coordinate = try Coordinate(latitude: -33.89, longitude: 151.27)
        #expect(coordinate.latitude  == -33.89)
        #expect(coordinate.longitude == 151.27)
    }

    @Test("Coordinates within rounding tolerance compare equal")
    func nearbyCoordinatesCompareEqual() throws {
        let a = try Coordinate(latitude: 52.3717, longitude: 4.5333)
        let b = try Coordinate(latitude: 52.3721, longitude: 4.5328)
        #expect(a == b)
    }

    @Test("Negative values rounding to zero are normalized to positive zero")
    func negativeZeroIsNormalized() throws {
        let coordinate = try Coordinate(latitude: -0.001, longitude: -0.004)
        #expect(coordinate.latitude.sign  == .plus)
        #expect(coordinate.longitude.sign == .plus)
        #expect(coordinate.canonicalLatitude  == "0.00")
        #expect(coordinate.canonicalLongitude == "0.00")
    }

    // MARK: - Canonical strings

    @Test("Canonical strings always carry exactly two decimals")
    func canonicalStringsAreFixedWidth() throws {
        let coordinate = try Coordinate(latitude: 4.5, longitude: 151.2744)
        #expect(coordinate.canonicalLatitude  == "4.50")
        #expect(coordinate.canonicalLongitude == "151.27")
    }

    // MARK: - Range validation (boundary pairs)

    @Test("Latitude boundaries ±90 are valid")
    func latitudeBoundariesAreValid() throws {
        #expect(try Coordinate(latitude:  90, longitude: 0).latitude ==  90)
        #expect(try Coordinate(latitude: -90, longitude: 0).latitude == -90)
    }

    @Test("Latitude beyond ±90 throws")
    func latitudeBeyondRangeThrows() {
        #expect(throws: CoordinateError.latitudeOutOfRange(90.01)) {
            try Coordinate(latitude: 90.01, longitude: 0)
        }
        #expect(throws: CoordinateError.latitudeOutOfRange(-90.01)) {
            try Coordinate(latitude: -90.01, longitude: 0)
        }
    }

    @Test("Longitude boundaries ±180 are valid")
    func longitudeBoundariesAreValid() throws {
        #expect(try Coordinate(latitude: 0, longitude:  180).longitude ==  180)
        #expect(try Coordinate(latitude: 0, longitude: -180).longitude == -180)
    }

    @Test("Longitude beyond ±180 throws")
    func longitudeBeyondRangeThrows() {
        #expect(throws: CoordinateError.longitudeOutOfRange(180.01)) {
            try Coordinate(latitude: 0, longitude: 180.01)
        }
        #expect(throws: CoordinateError.longitudeOutOfRange(-180.01)) {
            try Coordinate(latitude: 0, longitude: -180.01)
        }
    }

    @Test("Non-finite input throws rather than trapping")
    func nonFiniteInputThrows() {
        #expect(throws: CoordinateError.self) {
            try Coordinate(latitude: Double.nan, longitude: 0)
        }
        #expect(throws: CoordinateError.self) {
            try Coordinate(latitude: 0, longitude: .infinity)
        }
    }
}
