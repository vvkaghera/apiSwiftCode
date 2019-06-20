//
//  Order.swift
//  App
//
//  Created by MAC001 on 05/04/19.
//
import Foundation
import AuthProvider
import FluentProvider

final class DeviceToken: Model, Timestampable {
    static func randomKey() -> Int { return UUID().hashValue }

    static let idType: IdentifierType = .uuid
    static let idKey = DB.id.ⓡ
    static var foreignIdKey = DB.id.ⓡ
    let storage = Storage()
    var log: LogProtocol?
    var dToken: String
    var dType: String
    var userId: Identifier
    
    public enum DB: String {
        case id = "dtoken_id"
        case dTokenKey = "dtoken"
        case dTypeKey = "dtype"
        case userIdKey = "user_id"
    }
    
    init(id: String? = nil, dToken: String, dType: String, userId: Identifier) throws {
        self.userId = userId
       
        self.dToken = dToken
        self.dType = dType
        
       /* guard let userId = user.id else { throw Abort(.badRequest, reason: "User id not found in vending init") }
        self.userId = userId*/
        if let id = id { self.id = Identifier(id) }
    }
    
    init(row: Row) throws {

        userId = try row.get(DB.userIdKey.ⓡ)
        dToken = try row.get(DB.dTokenKey.ⓡ)
        dType = try row.get(DB.dTypeKey.ⓡ)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(DB.userIdKey.ⓡ, userId)
        try row.set(DB.dTokenKey.ⓡ, dToken)
        try row.set(DB.dTypeKey.ⓡ, dType)
        return row
    }
}

// MARK: Convenience

extension DeviceToken {
    /// Generates a new token for the supplied User.
    
    static func generate(for user: User, aDeviceToken: String, aDeviceType: String) throws -> DeviceToken {
        try DeviceToken.delete(for: user)
        
        return try DeviceToken(id: UUID().uuidString, dToken: aDeviceToken, dType: aDeviceType, userId: Identifier(user.id!))
    }
    
    static func delete(for user: User) throws {
        try makeQuery()
            .filter(DeviceToken.DB.userIdKey.ⓡ, user.id)
            .delete()
    }
}


extension DeviceToken {
    /// Fluent relation for accessing the user
    var user: Parent<DeviceToken, User> {
        return parent(id: userId)
    }
}


extension DeviceToken: ResponseRepresentable { }
//extension Vending: JSONRepresentable {}

extension DeviceToken: Preparation {
    static func prepare(_ database: Database) throws {
        
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension DeviceToken: JSONConvertible {
    
    convenience init(json: JSON) throws {
        
        let id: String?
        let dToken : String?
        let dType: String?
        
        print("DToken json=\(json)")
        do { id = try json.get(DB.id.ⓡ) } catch { id = nil }
       /* let rawUserId: String = try json.get(Order.DB.userIdKey.ⓡ)
        guard let auser = try User.find(rawUserId) else {
            throw Abort(.badRequest, reason: "User id \(rawUserId) not found for order")
        }*/

        guard let auserId: String = try json.get(DB.userIdKey.ⓡ) else {
            throw Abort(.badRequest, reason: "userid not found for event/order")
        }
        
        do { dToken = try json.get(DB.dTokenKey.ⓡ) } catch { dToken = nil }
        do { dType = try json.get(DB.dTypeKey.ⓡ) } catch { dType = nil }
        
        try self.init(
            id: id,
            dToken: dToken ?? "", dType: dType ?? "", userId: Identifier(auserId)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(DB.id.ⓡ, id)
        try json.set(DB.userIdKey.ⓡ, userId)
        try json.set(DB.dTokenKey.ⓡ, dToken)
        try json.set(DB.dTypeKey.ⓡ, dType)
        print("json sent is", json)
        return json
    }
}

//extension temp: TokenAuthenticatable {
//    typealias TokenType = Token
//}

