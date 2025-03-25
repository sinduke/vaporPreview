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

    app.get("sinduke", "status") { req async throws -> Response in
        var info: [String: String] = [:]
        
        info["app"] = "Vapor Empire"
        info["version"] = "1.2.0"
        info["env"] = app.environment.name
        info["timestamp"] = ISO8601DateFormatter().string(from: Date())
        info["message"] = "👑 帝国引擎运转良好，万众臣服！"
        
        // 系统平台判断
        let isMac = ProcessInfo.processInfo.operatingSystemVersionString.contains("Darwin")
        
        // host info
        info["host"] = try? shell("uname -a").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // CPU 使用率
        if isMac {
            if let cpu = try? shell("ps -A -o %cpu | awk '{s+=$1} END {print s}'") {
                info["cpuUsage"] = String(format: "%.1f%%", Float(cpu.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0)
            }
        } else {
            if let cpu = try? shell("top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'") {
                info["cpuUsage"] = "\(cpu.trimmingCharacters(in: .whitespacesAndNewlines))%"
            }
        }
        
        // 内存使用
        if isMac {
            if let mem = try? shell("vm_stat | awk '/Pages active/ {print $3 * 4096 / 1048576 \" MB\"}'") {
                info["memoryUsage"] = mem.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ".", with: "")
            }
        } else {
            if let mem = try? shell("free -m | awk '/Mem:/ {print $3\" MB\"}'") {
                info["memoryUsage"] = mem.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Uptime
        if isMac {
            if let bootTime = try? shell("sysctl -n kern.boottime | awk -F'[{},]' '{print $2}'"),
               let bootSeconds = Int(bootTime) {
                let uptime = Int(Date().timeIntervalSince1970) - bootSeconds
                info["uptime"] = formatSeconds(uptime)
            }
        } else {
            if let uptime = try? shell("uptime -p") {
                info["uptime"] = uptime.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // IP
        if let ip = try? shell(isMac ? "ipconfig getifaddr en0" : "hostname -I | awk '{print $1}'") {
            info["ipAddress"] = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Git commit
        if let commit = try? shell("git rev-parse --short HEAD") {
            info["gitCommit"] = commit.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let res = Response()
        try res.content.encode(info, as: .json)
        return res
    }

    try app.register(collection: TodoController())
}
