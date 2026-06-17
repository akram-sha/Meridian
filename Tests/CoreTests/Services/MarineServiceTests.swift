import Foundation
import Testing
@testable import Core

@Suite("MarineService")
struct MarineServiceTests {

    // MARK: — JSON decoding
    @Test("Decodes sea surface temperature from valid JSON")
    func decodesSeaSurfaceTemperature() throws {
        let json = """
                   {
                       "current": {
                           "sea_surface_temperature": 17.4
                       }
                   }
                   """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(MarineResponse.self, from: json)
        #expect(decoded.current.seaSurfaceTemperature == 17.4)
    }

    @Test("toWaterTemperature returns correct celsius value")
    func toWaterTemperatureReturnsCelsius() throws {
        let json = """
                   {
                       "current": {
                           "sea_surface_temperature": 21.0
                       }
                   }
                   """.data(using: .utf8)!

        let decoded   = try JSONDecoder().decode(MarineResponse.self, from: json)
        let waterTemp = decoded.toWaterTemperature()
        #expect(waterTemp.inCelsius == 21.0)
    }

    @Test("Decoding fails when sea_surface_temperature key is missing")
    func failsWithMissingKey() {
        let json = """
                   {
                       "current": {}
                   }
                   """.data(using: .utf8)!

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(MarineResponse.self, from: json)
        }
    }

    @Test("Decoding fails when current block is missing")
    func failsWithMissingCurrentBlock() {
        let json = """
        {}
        """.data(using: .utf8)!

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(MarineResponse.self, from: json)
        }
    }

    // MARK: — Protocol contract
    @Test("StubMarineService returns a WaterTemperature")
    func stubReturnsWaterTemperature() async throws {
        let stub   = StubMarineService()
        let result = try await stub.fetch(latitude: 52.37, longitude: 4.90)
        #expect(result.inCelsius == 18.0)
    }

    @Test("StubMarineService ignores coordinates")
    func stubIgnoresCoordinates() async throws {
        let stub      = StubMarineService()
        let amsterdam = try await stub.fetch(latitude: 52.37, longitude: 4.90)
        let inland    = try await stub.fetch(latitude: 51.50, longitude: 5.50)
        #expect(amsterdam.inCelsius == inland.inCelsius)
    }

    // MARK: — OWS safety integration
    @Test("17.4°C sea surface maps to restricted OWS safety")
        func owsSafetyForColdSeaTemp() throws {
        let json = """
        {
            "current": {
                "sea_surface_temperature": 17.4
            }
        }
        """.data(using: .utf8)!

        let decoded   = try JSONDecoder().decode(MarineResponse.self, from: json)
        let waterTemp = decoded.toWaterTemperature()
        #expect(waterTemp.owsSafety == .restricted)
    }

    @Test("22.0°C sea surface maps to ideal OWS safety")
    func owsSafetyForWarmSeaTemp() throws {
        let json = """
        {
            "current": {
                "sea_surface_temperature": 22.0
            }
        }
        """.data(using: .utf8)!

        let decoded   = try JSONDecoder().decode(MarineResponse.self, from: json)
        let waterTemp = decoded.toWaterTemperature()
        #expect(waterTemp.owsSafety == .ideal)
    }
}