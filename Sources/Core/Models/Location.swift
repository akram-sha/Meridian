import Foundation

public struct Location: Sendable, Identifiable {
    public let id:        UUID
    public let name:      String
    public let latitude:  Double
    public let longitude: Double

    public init(name: String, latitude: Double, longitude: Double) {
        self.id        = UUID()
        self.name      = name
        self.latitude  = latitude
        self.longitude = longitude
    }
}