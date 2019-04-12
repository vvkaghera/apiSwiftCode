//
//  Order.swift
//  App
//
//  Created by MAC001 on 05/04/19.
//
import Foundation
import AuthProvider
import FluentProvider

final class Order: Model, Timestampable {
    static let idType: IdentifierType = .uuid
    static let idKey = DB.id.ⓡ
    static var foreignIdKey = DB.id.ⓡ
    let storage = Storage()
    var log: LogProtocol?
    
    var status: String
    var additionalNotes: String
    var userId: Identifier
    var eventId: Identifier
    var vendingId: Identifier
    var serviceId: Identifier
    
    
    public enum DB: String {
        case id = "order_id"
        case userIdKey = "user_id"
        case eventIdKey = "event_id"
        case vendingIdKey = "vending_id"
        case serviceIdKey = "service_id"
        case status = "status"
        case additionalNotes = "additional_notes"
    
    }
    
    init(id: String? = nil, userId: Identifier, eventId: Identifier, vendingId: Identifier, serviceId: Identifier, status: String,
         additionalNotes: String/*,
         user: User*/) throws {
        self.userId = userId
        self.eventId = eventId
        self.vendingId = vendingId
        self.serviceId = serviceId
        self.status = status
        self.additionalNotes = additionalNotes
        
       /* guard let userId = user.id else { throw Abort(.badRequest, reason: "User id not found in vending init") }
        self.userId = userId*/
        if let id = id { self.id = Identifier(id) }
    }
    
    init(row: Row) throws {
        
        userId = try row.get(DB.userIdKey.ⓡ)
        eventId = try row.get(DB.eventIdKey.ⓡ)
        vendingId = try row.get(DB.vendingIdKey.ⓡ)
        serviceId =   try row.get(DB.serviceIdKey.ⓡ)
        status = try row.get(DB.status.ⓡ)
        additionalNotes = try row.get(DB.additionalNotes.ⓡ)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(DB.userIdKey.ⓡ, userId)
        try row.set(DB.eventIdKey.ⓡ, eventId)
        try row.set(DB.vendingIdKey.ⓡ, vendingId)
        try row.set(DB.serviceIdKey.ⓡ, serviceId)
        try row.set(DB.status.ⓡ, status)
        try row.set(DB.additionalNotes.ⓡ, additionalNotes)
        return row
    }
}

extension Order {
    var owner: Parent<Order, Event> {
        return parent(id: eventId)
    }
}
/*extension Order {
    var owner: Parent<Order, User> {
        return parent(id: userId)
    }
}
*/
extension Order: ResponseRepresentable { }
//extension Vending: JSONRepresentable {}

extension Order: Preparation {
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

extension Order: JSONConvertible {
    
    convenience init(json: JSON) throws {
        
        let id: String?
        let status : String?
        let additionalNotes: String?
        //let eventDate: Date?
        //let startTime: Date?
        //let endTime: Date?
        
        
        
        print("Order json=\(json)")
        do { id = try json.get(DB.id.ⓡ) } catch { id = nil }
       /* let rawUserId: String = try json.get(Order.DB.userIdKey.ⓡ)
        guard let auser = try User.find(rawUserId) else {
            throw Abort(.badRequest, reason: "User id \(rawUserId) not found for order")
        }*/

        guard let auserId: String = try json.get(DB.userIdKey.ⓡ) else {
            throw Abort(.badRequest, reason: "userid not found for event/order")
        }
        
        guard let aeventId: String = try json.get(DB.eventIdKey.ⓡ) else {
            throw Abort(.badRequest, reason: "eventid not found for event/order")
        }
        
        guard let avendingId: String = try json.get(DB.vendingIdKey.ⓡ) else {
            throw Abort(.badRequest, reason: "vendingid not found for event/order")
        }
        
        guard let aserviceId: String = try json.get(DB.serviceIdKey.ⓡ) else {
            throw Abort(.badRequest, reason: "serviceid not found for event/order")
        }
        
        
        do { status = try json.get(DB.status.ⓡ) } catch { status = nil }
        do { additionalNotes = try json.get(DB.additionalNotes.ⓡ) } catch { additionalNotes = nil }
        

        
        
        try self.init(
            id: id,
            userId: Identifier(auserId),
            eventId: Identifier(aeventId),
            vendingId: Identifier(avendingId),
            serviceId: Identifier(aserviceId),
            status: status ?? "",
            additionalNotes: additionalNotes ?? ""//,
//            user: auser
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(DB.id.ⓡ, id)
        
        
        try json.set(DB.userIdKey.ⓡ, userId)
        try json.set(DB.eventIdKey.ⓡ, eventId)
        try json.set(DB.vendingIdKey.ⓡ, vendingId)
        try json.set(DB.serviceIdKey.ⓡ, serviceId)
        try json.set(DB.status.ⓡ, status)
        try json.set(DB.additionalNotes.ⓡ, additionalNotes)
        print("json sent is", json)
        return json
    }
}
/*
extension Order: Updateable {
    static var updateableKeys: [UpdateableKey<Order>] {
        return [
            UpdateableKey(DB.userIdKey.ⓡ, String.self) { aabb, aaaaaaa in aabb.userId = aaaaaaa },
            UpdateableKey(DB.eventIdKey.ⓡ, String.self) { aabb, content in aabb.eventID = content},
            UpdateableKey(DB.vendingIdKey.ⓡ, String.self) { event, content in event.vendingId = content },
            UpdateableKey(DB.serviceIdKey.ⓡ, String.self) { event, content in event.serviceId = content },
            UpdateableKey(DB.status.ⓡ, String.self) { event, content in event.status = content },
            UpdateableKey(DB.additionalNotes.ⓡ, String.self) { event, content in event.additionalNotes = content }
            
        ]
    }
}*/



extension Order: TokenAuthenticatable {
    typealias TokenType = Token
}

