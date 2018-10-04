//
//  Token.swift
//  Created by Steven O'Toole on 8/31/17.
//

import Foundation
import Vapor
import FluentProvider
import Crypto

final class Token: Model {
    public enum DB: String {
        case token
        case expires
        case userID = "user_id"
    }

    let storage = Storage()

    let token: String
    let userID: Identifier
    let expires: Date

    /// Creates a new Token
    init(string: String, user: User, expires: Date? = nil) throws {
        token = string
        self.expires = expires ?? Token.getExpires()
        userID = try user.assertExists()
    }

    // MARK: Row

    init(row: Row) throws {
        token = try row.get(DB.token.ⓡ)
        expires = try row.get(DB.expires.ⓡ)
        userID = try row.get(User.foreignIdKey)
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set(DB.token.ⓡ, token)
        try row.set(DB.expires.ⓡ, expires)
        try row.set(User.foreignIdKey, userID)
        return row
    }
}

// MARK: Convenience

extension Token {
    /// Generates a new token for the supplied User.
    static func generate(for user: User) throws -> Token {
        try Token.delete(for: user)
        // generate random bits using OpenSSL
        let random = try Crypto.Random.bytes(count: 64)
        // 0xtim: "That’s how I generate OAuth tokens?  try Random.bytes(count: 32).hexString

        return try Token(string: random.base64Encoded.makeString(), user: user)
    }

    static func getExpires(from date: Date = Date()) -> Date {
        var dc = Calendar.current.dateComponents([.day, .month, .year], from: date)
        guard let year = dc.year else { fatalError() }
        dc.year = year + 1
        guard let expirationDay = Calendar.current.date(from: dc) else { fatalError() }
        return expirationDay
    }

    static func delete(for user: User) throws {
        try makeQuery()
            .filter(Token.DB.userID.ⓡ, user.id)
            .delete()

    }

}

// MARK: Relations

extension Token {
    /// Fluent relation for accessing the user
    var user: Parent<Token, User> {
        return parent(id: userID)
    }
}

// MARK: Preparation

extension Token: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(Token.self) { builder in
            builder.id()
            builder.string(DB.token.ⓡ)
            builder.date("expires")
            builder.foreignId(for: User.self)
        }
    }

    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(Token.self)
    }
}

// MARK: JSON

/// Allows the token to convert to JSON.
extension Token: JSONRepresentable {
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(DB.token.ⓡ, token)
        try json.set(DB.expires.ⓡ, expires)
        return json
    }
}

// MARK: HTTP

/// Allows the Token to be returned directly in route closures.
extension Token: ResponseRepresentable { }
