// Migrations/CreateUser.swift
import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .id()
            .field("name", .string, .required)
            .field("username", .string, .required)
            .field("email", .string, .required)
            .field("address", .json, .required)
            .field("phone", .string, .required)
            .field("website", .string, .required)
            .field("company", .json, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("users").delete()
    }
}