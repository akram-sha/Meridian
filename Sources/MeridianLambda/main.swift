import AWSLambdaEvents
import AWSLambdaRuntime
import Core
import DynamoDBForecastCache
import Foundation
import HTTPTypes
import Logging
import MeridianLambdaCore
import SotoDynamoDB

// Everything below is constructed once per Lambda execution environment and reused across
// warm invocations — never rebuild the AWS client or the coordinator inside the handler body.
let environment: [String: String] = ProcessInfo.processInfo.environment
let logger: Logger = Logger(label: "meridian.lambda")

let awsClient: AWSClient = AWSClient()
// Endpoint override is what lets the same binary run against LocalStack and real AWS,
// differing only in configuration (LocalStack sets AWS_ENDPOINT_URL for hot-reload/dev
// setups; MERIDIAN_DYNAMODB_ENDPOINT wins if both are present).
let dynamoDB: DynamoDB = DynamoDB(
    client: awsClient,
    endpoint: environment["MERIDIAN_DYNAMODB_ENDPOINT"] ?? environment["AWS_ENDPOINT_URL"]
)
let tableName: String = environment["MERIDIAN_CACHE_TABLE"] ?? "meridian-forecast-cache"

let coordinator: ForecastCoordinator = ForecastCoordinator(
    weatherService: OpenMeteoService(marineService: OpenMarineService()),
    cache: DynamoDBForecastCache(client: dynamoDB, tableName: tableName)
)
let api: ForecastAPI = ForecastAPI(coordinator: coordinator, logger: logger)

// The shim proper: API Gateway v1 proxy event (REST API — required for API keys/usage
// plans) in, contract JSON out. All behavior lives in MeridianLambdaCore where it's tested.
let runtime = LambdaRuntime {
    (event: APIGatewayRequest, context: LambdaContext) async -> APIGatewayResponse in
    let response: APIResponse = await api.handle(
        queryParameters: event.queryStringParameters,
        requestID: context.requestID
    )
    return APIGatewayResponse(
        statusCode: HTTPResponse.Status(code: response.statusCode),
        headers: ["Content-Type": "application/json"],
        body: response.body
    )
}

try await runtime.run()
