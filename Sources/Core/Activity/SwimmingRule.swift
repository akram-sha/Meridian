/// A single swimming safety check.
/// Return `.noGo` or `.caution` to flag a concern; return `nil` for no objection.
/// Hard guards short-circuit evaluation; scoring rules all run and accumulate.
internal protocol SwimmingRule: Sendable {
    func evaluate(_ weather: WeatherResult) -> Verdict?
}