# vaporPreview

💧 A project built with the Vapor web framework.

## Getting Started

To build the project using the Swift Package Manager, run the following command in the terminal from the root of the project:
```bash
swift build
```

To run the project and start the server, use the following command:
```bash
swift run
```

To execute tests, use the following command:
```bash
swift test
```

### 本地运行数据库
可以通过本地脚本 在本地的docker中运行一个PostgreSQL
```shell
./start-local-db.sh
```

### 当前的vapor和数据库的运行健康状态检查
```shell
for i in {1..20}; do
  curl -s -o /dev/null -w "%{http_code} " -H "X-API-Key: sinduke" http://localhost:8080/sinduke/health &
done
wait
echo ""
```

### See more

- [Vapor Website](https://vapor.codes)
- [Vapor Documentation](https://docs.vapor.codes)
- [Vapor GitHub](https://github.com/vapor)
- [Vapor Community](https://github.com/vapor-community)
