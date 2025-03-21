import Fluent
import PostgresNIO
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    // MARK: -- 健康检查路由
    
    app.get("sinduke", "health") { req async throws -> Response in
        
        let apiKey = req.headers["X-API-Key"].first
        
        guard apiKey == "sinduke" else {
            let errorBody = ["error": "Invalid API Key"]
            let body = try Response.Body(data: JSONEncoder().encode(errorBody))
            return Response(
                status: .unauthorized,
                headers: ["Content-Type": "application/json"],
                body: body
            )
        }
        
        if let cached = try await req.cache.get("health", as: [String: String].self) {
            let cachedBody = try JSONEncoder().encode(cached)
            return Response(
                status: cached["status"] == "healthy" ? .ok : .serviceUnavailable,
                headers: ["Content-Type": "application/json"],
                body: .init(data: cachedBody)
            )
        }
        
        var status: [String: String] = [:]
        var isHealthy = true
        
        status["app"] = "running"
        status["version"] = "1.0.0"
        
        if let postgres = app.db(.psql) as? (any PostgresDatabase) {
            do {
                let rows = try await postgres.simpleQuery("SELECT 1 AS alive").get()
                if let row = rows.first?.makeRandomAccess(), row[data: "alive"].int == 1 {
                    status["db"] = "true"
                } else {
                    status["db"] = "false"
                    isHealthy = false
                }
            } catch {
                status["db"] = "false"
                status["db_error"] = error.localizedDescription
                isHealthy = false
            }
        } else {
            status["db"] = "false"
            status["db_error"] = "not a postgres instance"
            isHealthy = false
        }
        
        let start = Date()
        _ = try await Task.sleep(nanoseconds: 1_000_000)
        let latency = Date().timeIntervalSince(start) * 1000
        status["latency_ms"] = String(format: "%.2f", latency)
        
        status["status"] = isHealthy ? "healthy" : "unhealthy"
        
        try await req.cache.set("health", to: status, expiresIn: .seconds(5))
        
        let responseBody = try JSONEncoder().encode(status)
        return Response(
            status: isHealthy ? .ok : .serviceUnavailable,
            headers: ["Content-Type": "application/json"],
            body: .init(data: responseBody)
        )
    }

    try app.register(collection: TodoController())
}
