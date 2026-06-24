import Testing
@testable import Core

@Suite("Location")
struct LocationTests {

    // MARK: - Stored values

    @Test("Name is stored correctly")
    func nameStoredCorrectly() {
        #expect(Location(name: "Zandvoort", latitude: 52.37, longitude: 4.53).name == "Zandvoort")
    }

    @Test("Latitude is stored correctly")
    func latitudeStoredCorrectly() {
        #expect(Location(name: "Test", latitude: 52.37, longitude: 4.53).latitude == 52.37)
    }

    @Test("Longitude is stored correctly")
    func longitudeStoredCorrectly() {
        #expect(Location(name: "Test", latitude: 52.37, longitude: 4.53).longitude == 4.53)
    }

    // MARK: - Identity

    @Test("Two locations with identical fields get different IDs")
    func identicalFieldsProduceDifferentIDs() {
        let a = Location(name: "Zandvoort", latitude: 52.37, longitude: 4.53)
        let b = Location(name: "Zandvoort", latitude: 52.37, longitude: 4.53)
        #expect(a.id != b.id)
    }

    @Test("ID is stable across repeated accesses")
    func idIsStable() {
        let loc = Location(name: "Test", latitude: 0, longitude: 0)
        #expect(loc.id == loc.id)
    }
}