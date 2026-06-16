public protocol ActivityConditions: Sendable {
    var verdict: Verdict { get }
    var activity: Activity { get }
}