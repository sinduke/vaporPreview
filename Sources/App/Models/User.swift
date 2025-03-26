// Models/User.swift
import Vapor
import struct Foundation.UUID
import Fluent

final class UserModel: Model, Content, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "address")
    var address: Address
    
    @Field(key: "phone")
    var phone: String
    
    @Field(key: "website")
    var website: String
    
    @Field(key: "company")
    var company: Company
    
    init() { }
    
    init(id: UUID? = nil, name: String, username: String, email: String, 
         address: Address, phone: String, website: String, company: Company) {
        self.id = id
        self.name = name
        self.username = username
        self.email = email
        self.address = address
        self.phone = phone
        self.website = website
        self.company = company
    }

    init(name: String, username: String, email: String, 
         address: Address, phone: String, website: String, company: Company) {
        self.name = name
        self.username = username
        self.email = email
        self.address = address
        self.phone = phone
        self.website = website
        self.company = company
    }

}

struct Address: Codable, Content {
    let street: String
    let suite: String
    let city: String
    let zipcode: String
    let geo: Geo
}

struct Geo: Codable, Content {
    let lat: String
    let lng: String
}

struct Company: Codable, Content {
    let name: String
    let catchPhrase: String
    let bs: String
}