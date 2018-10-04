//
//  Service.swift
//  Created by Steven O'Toole on 9/21/17.
//

import Vapor
import AuthProvider
import FluentProvider

final class Service: Model, Timestampable {
    static let idType: IdentifierType = .uuid
    static let idKey = DB.id.ⓡ
    let storage = Storage()
    var log: LogProtocol?

    var title: String
    var description: String
    var costWithUnit: String
    var vendingId: Identifier

    public enum DB: String {
        case id = "service_id"
        case title
        case description
        case costWithUnit = "cost_with_unit"
        case vendingId = "vending_id"
    }

	init(id: String? = nil, title: String, description: String,
         costWithUnit: String, vending: Vending) throws  {
        self.title = title
        self.description = description
        self.costWithUnit = costWithUnit
        guard let vendingId = vending.id else { throw Abort(.badRequest, reason: "Vending id not found in service init") }
        self.vendingId = vendingId
        if let id = id { self.id = Identifier(id) }
    }

    init(row: Row) throws {
        title = try row.get(DB.title.ⓡ)
        description = try row.get(DB.description.ⓡ)
        costWithUnit = try row.get(DB.costWithUnit.ⓡ)
        vendingId = try row.get(DB.vendingId.ⓡ)
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set(DB.title.ⓡ, title)
        try row.set(DB.description.ⓡ, description)
        try row.set(DB.costWithUnit.ⓡ, costWithUnit)
        try row.set(DB.vendingId.ⓡ, vendingId)
        return row
    }
}

extension Service {
    var owner: Parent<Service, Vending> {
        return parent(id: vendingId)
    }
}
extension Service: ResponseRepresentable { }

extension Service: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(DB.title.ⓡ)
            builder.string(DB.description.ⓡ)
            builder.string(DB.costWithUnit.ⓡ)
            builder.foreignId(for: Vending.self)
        }
        try database.driver.raw("alter table services alter column \(DB.id.ⓡ) set default uuid_generate_v4();")
        try database.driver.raw("alter table services alter column created_at set default now();")
        try database.driver.raw("alter table services alter column updated_at set default now();")
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Service: JSONConvertible {

    convenience init(json: JSON) throws {
        let id: String?

        do { id = try json.get(DB.id.ⓡ) } catch { id = nil }
        let rawVendingId: String = try json.get(Service.DB.vendingId.ⓡ)
        guard let vending = try Vending.find(rawVendingId) else {
            throw Abort(.badRequest, reason: "Vending id \(rawVendingId) not found for service")
        }
        guard let title: String = try json.get(DB.title.ⓡ) else {
            throw Abort(.badRequest, reason: "Title not found for service")
        }
        guard let description: String = try json.get(DB.description.ⓡ) else {
            throw Abort(.badRequest, reason: "Description not found for service")
        }
        guard let costWithUnit: String = try json.get(DB.costWithUnit.ⓡ) else {
            throw Abort(.badRequest, reason: "CostWithUnit not found for service")
        }
        try self.init(
            id: id,
            title: title,
            description: description,
            costWithUnit: costWithUnit,
            vending: vending
        )
    }

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(DB.id.ⓡ, id)
        try json.set(DB.title.ⓡ, title)
        try json.set(DB.description.ⓡ, description)
        try json.set(DB.costWithUnit.ⓡ, costWithUnit)
        try json.set(DB.vendingId.ⓡ, vendingId)
        return json
    }
}

extension Service: Updateable {
    public static var updateableKeys: [UpdateableKey<Service>] {
        return [
            UpdateableKey(DB.title.ⓡ, String.self) { service, content in service.title = content },
            UpdateableKey(DB.description.ⓡ, String.self) { service, content in service.description = content },
            UpdateableKey(DB.costWithUnit.ⓡ, String.self) { service, content in service.costWithUnit = content }
        ]
    }
}

extension Service: TokenAuthenticatable {
    typealias TokenType = Token
}
