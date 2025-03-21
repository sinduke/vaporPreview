import Vapor

actor RateLimiter {
    let requestsPerSecond: Int
    let timeWindow: TimeInterval = 1.0

    private var lastRequest: [String: Date] = [:]
    private var requestCount: [String: Int] = [:]

    init(requestsPerSecond: Int) {
        self.requestsPerSecond = requestsPerSecond
    }

    func allow(ip: String) -> Bool {
        let now = Date()

        if let last = lastRequest[ip], now.timeIntervalSince(last) > timeWindow {
            requestCount[ip] = 1
        } else {
            requestCount[ip] = (requestCount[ip] ?? 0) + 1
        }

        lastRequest[ip] = now

        return requestCount[ip]! <= requestsPerSecond
    }
}

final class RateLimitMiddleware: AsyncMiddleware {
    private let limiter: RateLimiter

    init(requestsPerSecond: Int) {
        self.limiter = RateLimiter(requestsPerSecond: requestsPerSecond)
    }

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let ip = request.remoteAddress?.ipAddress ?? "unknown"
        
        let allowed = await limiter.allow(ip: ip)
        if !allowed {
            return Response(status: .tooManyRequests, body: .init(string: "Rate limit exceeded"))
        }

        return try await next.respond(to: request)
    }
}
