import Vapor

// RateLimiter 使用 actor 确保线程安全
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

// RateLimitMiddleware 作为中间件限制请求
final class RateLimitMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let ip = request.remoteAddress?.ipAddress ?? "unknown"

        // 使用全局共享的 rateLimiter
        let allowed = await request.application.rateLimiter.allow(ip: ip)
        if !allowed {
            return Response(status: .tooManyRequests, body: .init(string: "Rate limit exceeded"))
        }

        return try await next.respond(to: request)
    }
}

extension Application {
    struct RateLimiterKey: StorageKey {
        typealias Value = RateLimiter
    }

    var rateLimiter: RateLimiter {
        get {
            if let existing = self.storage[RateLimiterKey.self] {
                return existing
            } else {
                let new = RateLimiter(requestsPerSecond: 10)
                self.storage[RateLimiterKey.self] = new
                return new
            }
        }
        set {
            self.storage[RateLimiterKey.self] = newValue
        }
    }
}
