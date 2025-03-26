import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users: any RoutesBuilder = routes.grouped("users")
        users.get(use: index)
        users.post(use: create)
        users.group(":id") { user in
            user.get(use: show)
            user.put(use: update)
            user.delete(use: delete)
        }
        
        users.get("import", use: importUsers)
        users.delete("all", use: deleteAll)
    }

    // 获取所有用户
    @Sendable
    func index(req: Request) async throws -> [UserModel] {
        try await UserModel.query(on: req.db).all()
    }

    // 创建单个用户
    @Sendable
    func create(req: Request) async throws -> UserModel {
        let user = try req.content.decode(UserModel.self)
        try await user.save(on: req.db)
        return user
    }
    
    // 获取单个用户
    @Sendable
    func show(req: Request) async throws -> UserModel {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let user = try await UserModel.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        return user
    }

    // 更新用户
    @Sendable
    func update(req: Request) async throws -> UserModel {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        let updatedUser = try req.content.decode(UserModel.self)
        
        guard let user = try await UserModel.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        user.name = updatedUser.name
        user.username = updatedUser.username
        user.email = updatedUser.email
        user.address = updatedUser.address
        user.phone = updatedUser.phone
        user.website = updatedUser.website
        user.company = updatedUser.company
        
        try await user.save(on: req.db)
        return user
    }

    // 删除单个用户
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let id: UUID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let user: UserModel = try await UserModel.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        try await user.delete(on: req.db)
        return .ok
    }

    // 导入用户数据
    @Sendable
    func importUsers(req: Request) async throws -> HTTPStatus {
        let response: ClientResponse = try await req.client.get("https://jsonplaceholder.typicode.com/users")
        let userDTOs: [UserDTO] = try response.content.decode([UserDTO].self)
        
        for dto: UserDTO in userDTOs {
            let user: UserModel = dto.toModel()
            try await user.save(on: req.db)
        }
        
        return .ok
    }

    // 删除所有用户
    @Sendable
    func deleteAll(req: Request) async throws -> HTTPStatus {
        try await UserModel.query(on: req.db).delete()
        return .ok
    }
}

// DTO to match JSONPlaceholder API response
struct UserDTO: Content {
    let id: Int
    let name: String
    let username: String
    let email: String
    let address: Address
    let phone: String
    let website: String
    let company: Company
}

extension UserDTO {
    func toModel() -> UserModel {
        UserModel(
            name: self.name,
            username: self.username,
            email: self.email,
            address: self.address,
            phone: self.phone,
            website: self.website,
            company: self.company
        )
    }
}
