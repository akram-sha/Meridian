import Testing
@testable import Core

@Suite("Location")
struct LocationTests {

    // MARK: - Stored values

    @Test("Name is stored correctly")
    func nameStoredCorrectly() throws {
        #expect(try Location(name: "Zandvoort", latitude: 52.37, longitude: 4.53).name == "Zandvoort")
    }

    @Test("Latitude and longitude expose the coordinate's rounded values")
    func coordinatesArePrivacyRounded() throws {
        let location = try Location(name: "Test", latitude: 52.3717, longitude: 4.5333)
        #expect(location.latitude  == 52.37)
        #expect(location.longitude == 4.53)
    }

    // MARK: - Validation (delegated to Coordinate)

    @Test("Out-of-range latitude throws CoordinateError")
    func outOfRangeLatitudeThrows() {
        #expect(throws: CoordinateError.latitudeOutOfRange(99.0)) {
            try Location(name: "Nowhere", latitude: 99.0, longitude: 0)
        }
    }

    @Test("Out-of-range longitude throws CoordinateError")
    func outOfRangeLongitudeThrows() {
        #expect(throws: CoordinateError.longitudeOutOfRange(-200.0)) {
            try Location(name: "Nowhere", latitude: 0, longitude: -200.0)
        }
    }
}
