import Testing
@testable import MeridianLambdaCore
import Core

// Request parsing is where the wire contract's privacy rule is enforced, so every branch
// gets boundary pairs on both params independently: 0/1/2 decimal places accepted, 3
// rejected — the precision check must run on the raw string, before Double conversion.
@Suite("ForecastRequest parsing")
struct ForecastRequestTests {

    private func query(
        latitude: String? = "52.37", longitude: String? = "4.53", activity: String? = "swimming"
    ) -> [String: String] {
        var parameters: [String: String] = [:]
        if let latitude { parameters["latitude"] = latitude }
        if let longitude { parameters["longitude"] = longitude }
        if let activity { parameters["activity"] = activity }
        return parameters
    }

    private func parseError(_ parameters: [String: String]) -> ForecastAPIError? {
        do {
            _ = try ForecastRequest.parse(queryParameters: parameters)
            return nil
        } catch {
            return error
        }
    }

    // MARK: - Accepted precision: 0, 1, and 2 decimal places, each param independently

    @Test(arguments: ["52", "-52", "52.3", "-52.3", "52.37", "-52.37"])
    func latitudeWithUpToTwoDecimalPlacesIsAccepted(raw: String) throws {
        let request = try ForecastRequest.parse(queryParameters: query(latitude: raw))
        #expect(request.coordinate.latitude == Double(raw))
    }

    @Test(arguments: ["4", "-4", "4.5", "-4.5", "4.53", "-4.53"])
    func longitudeWithUpToTwoDecimalPlacesIsAccepted(raw: String) throws {
        let request = try ForecastRequest.parse(queryParameters: query(longitude: raw))
        #expect(request.coordinate.longitude == Double(raw))
    }

    // MARK: - Rejected precision: 3 decimal places, each param independently

    @Test func threeDecimalLatitudeIsRejectedAsTooPrecise() {
        let error = parseError(query(latitude: "52.371"))
        #expect(error == .coordinateTooPrecise(
            message: "latitude must have at most 2 decimal places, got 52.371"))
    }

    @Test func threeDecimalLongitudeIsRejectedAsTooPrecise() {
        let error = parseError(query(longitude: "4.533"))
        #expect(error == .coordinateTooPrecise(
            message: "longitude must have at most 2 decimal places, got 4.533"))
    }

    // A trailing zero doesn't change the Double value ("52.370" == "52.37"), which is
    // exactly why the check must look at the raw string — this pins that behavior.
    @Test func trailingZeroThirdDecimalIsStillTooPrecise() {
        let error = parseError(query(latitude: "52.370"))
        #expect(error == .coordinateTooPrecise(
            message: "latitude must have at most 2 decimal places, got 52.370"))
    }

    // MARK: - Missing / non-numeric coordinates

    @Test func missingLatitudeIsOutOfRange() {
        #expect(parseError(query(latitude: nil))
            == .coordinateOutOfRange(message: "latitude is required"))
    }

    @Test func missingLongitudeIsOutOfRange() {
        #expect(parseError(query(longitude: nil))
            == .coordinateOutOfRange(message: "longitude is required"))
    }

    @Test(arguments: ["abc", "1e3", ".5", "52.", "+52", "52,37", "52.3.7", "٥٢", "NaN", "inf"])
    func nonPlainDecimalLatitudeIsOutOfRange(raw: String) {
        #expect(parseError(query(latitude: raw)) == .coordinateOutOfRange(
            message: "latitude must be a plain decimal number, got '\(raw)'"))
    }

    // MARK: - Range violations (delegated to Coordinate, message passed through)

    @Test func latitudeAboveNinetyIsOutOfRange() {
        #expect(parseError(query(latitude: "99")) == .coordinateOutOfRange(
            message: "latitude must be between -90 and 90, got 99.0"))
    }

    @Test func longitudeBelowMinusOneEightyIsOutOfRange() {
        #expect(parseError(query(longitude: "-180.5")) == .coordinateOutOfRange(
            message: "longitude must be between -180 and 180, got -180.5"))
    }

    @Test(arguments: [("90", "180"), ("-90", "-180")])
    func rangeEndpointsAreAccepted(latitude: String, longitude: String) throws {
        let request = try ForecastRequest.parse(
            queryParameters: query(latitude: latitude, longitude: longitude))
        #expect(request.coordinate.latitude == Double(latitude))
        #expect(request.coordinate.longitude == Double(longitude))
    }

    // MARK: - Activity

    @Test func missingActivityIsUnsupported() {
        #expect(parseError(query(activity: nil))
            == .unsupportedActivity(message: "activity is required"))
    }

    @Test func emptyActivityIsUnsupported() {
        #expect(parseError(query(activity: ""))
            == .unsupportedActivity(message: "activity is required"))
    }

    @Test(arguments: ["surfing", "diving", "Swimming", "SWIMMING"])
    func nonSwimmingActivityIsUnsupported(raw: String) {
        #expect(parseError(query(activity: raw)) == .unsupportedActivity(
            message: "activity must be 'swimming', got '\(raw)'"))
    }

    @Test func swimmingActivityParses() throws {
        let request = try ForecastRequest.parse(queryParameters: query())
        #expect(request.activity == .swimming)
    }

    // MARK: - Validation order: latitude before longitude before activity

    @Test func latitudeErrorWinsOverLongitudeAndActivityErrors() {
        let error = parseError(query(latitude: "52.371", longitude: "abc", activity: "surfing"))
        #expect(error == .coordinateTooPrecise(
            message: "latitude must have at most 2 decimal places, got 52.371"))
    }

    @Test func longitudeErrorWinsOverActivityError() {
        let error = parseError(query(longitude: "abc", activity: "surfing"))
        #expect(error == .coordinateOutOfRange(
            message: "longitude must be a plain decimal number, got 'abc'"))
    }

    // MARK: - Rounding still applies downstream (defense in depth, not a substitute
    // for the reject rule — 2-dp input passes through Coordinate unchanged)

    @Test func negativeZeroCollapsesToCanonicalZero() throws {
        let request = try ForecastRequest.parse(queryParameters: query(latitude: "-0.0"))
        #expect(request.coordinate.canonicalLatitude == "0.00")
    }
}
