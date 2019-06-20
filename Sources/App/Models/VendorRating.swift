//
//  VendorRating.swift
//  App
//
//  Created by MAC001 on 23/04/19.
//
import Foundation
import AuthProvider
import FluentProvider

final class VendorRating: Model, Timestampable {
    static let idType: IdentifierType = .uuid
    static let idKey = DB.id.ⓡ
    static var foreignIdKey = DB.id.ⓡ
    let storage = Storage()
    var log: LogProtocol?
    
    var review: String?
    var rating: String
    var userId: Identifier
    var vendingId: Identifier
    
    
    public enum DB: String {
        case id = "userrate_id"
        case vendingIdKey = "vending_id"
        case userIdKey = "user_id"
        case ratingKey = "rating"
        case reviewKey = "review"
    
    }
    
    init(id: String? = nil, userId: Identifier, vendingId: Identifier, rating: String,
         review: String?/*,
         user: User*/) throws {
        self.userId = userId
        self.vendingId = vendingId
        self.rating = rating
        self.review = review
        
       /* guard let userId = user.id else { throw Abort(.badRequest, reason: "User id not found in vending init") }
        self.userId = userId*/
        if let id = id { self.id = Identifier(id) }
    }
    
    init(row: Row) throws {
        
        userId = try row.get(DB.userIdKey.ⓡ)
        vendingId = try row.get(DB.vendingIdKey.ⓡ)
        rating = try row.get(DB.ratingKey.ⓡ)
        review = try row.get(DB.reviewKey.ⓡ)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(DB.userIdKey.ⓡ, userId)
        try row.set(DB.vendingIdKey.ⓡ, vendingId)
        try row.set(DB.ratingKey.ⓡ, rating)
        try row.set(DB.reviewKey.ⓡ, review)
        return row
    }
}


/*extension Order {
    var owner: Parent<Order, User> {
        return parent(id: userId)
    }
}
*/
extension VendorRating: ResponseRepresentable { }
//extension Vending: JSONRepresentable {}

extension VendorRating: Preparation {
    static func prepare(_ database: Database) throws {
        /*
         try database.create(self) { builder in
         builder.id()
         builder.string(DB.eventName.ⓡ)
         //builder.string(DB.eventDate.ⓡ)
         //builder.string(DB.startTime.ⓡ)
         //builder.string(DB.endTime.ⓡ)
         builder.string(DB.location.ⓡ)
         builder.string(DB.longDescription.ⓡ, optional: true)
         builder.string(DB.noOfGuests.ⓡ)
         
         builder.foreignId(for: User.self)
         }
         
         try database.driver.raw("alter table events alter column \(DB.id.ⓡ) set default uuid_generate_v4();")
         try database.driver.raw("alter table events alter column created_at set default now();")
         try database.driver.raw("alter table events alter column updated_at set default now();")
         
         
         
         let s = "insert into events (" +
         "\(DB.userIdKey.ⓡ),  \(DB.eventName.ⓡ), \(DB.location.ⓡ), \(DB.noOfGuests.ⓡ) " +
         " ) values(" +
         "'a779bddb-5e14-4310-b0ca-cccbfab3d781', 'My Birthday', 'Irvine', '0-10 guests' " +
         " ) ;"
         try database.driver.raw(s)
         */
    }
    
    // "there’s no need to manually create indexes on unique columns; doing so
    // would just duplicate the automatically-created index."
    // https://www.postgresql.org/docs/9.4/static/ddl-constraints.html
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension VendorRating: JSONConvertible {
    
    convenience init(json: JSON) throws {
        
        let id: String?
        let rating : String?
        let review: String?
      
        print("Rating_vendor json=\(json)")
        do { id = try json.get(DB.id.ⓡ) } catch { id = nil }

        guard let auserId: String = try json.get(DB.userIdKey.ⓡ) else {
            throw Abort(.badRequest, reason: "userid not found for rate")
        }
        
        guard let avendingId: String = try json.get(DB.vendingIdKey.ⓡ) else {
            throw Abort(.badRequest, reason: "vendingid not found for rate")
        }
        
        do { rating = try json.get(DB.ratingKey.ⓡ) } catch { rating = nil }
        do { review = try json.get(DB.reviewKey.ⓡ) } catch { review = nil }
        
        
        try self.init(
            id: id,
            userId: Identifier(auserId),
            vendingId: Identifier(avendingId),
            rating: rating ?? "",
            review: review ?? ""//,
//            user: auser
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(DB.id.ⓡ, id)
        
        
        try json.set(DB.userIdKey.ⓡ, userId)
        try json.set(DB.vendingIdKey.ⓡ, vendingId)
        try json.set(DB.ratingKey.ⓡ, rating)
        try json.set(DB.reviewKey.ⓡ, review)
        print("json sent is", json)
        return json
    }
}

extension VendorRating: TokenAuthenticatable {
    typealias TokenType = Token
}

