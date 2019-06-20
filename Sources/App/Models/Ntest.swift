//
//  Order.swift
//  App
//
//  Created by MAC001 on 05/04/19.
//
import Foundation
import AuthProvider
import FluentProvider

final class Ntest: Model, Timestampable {
    static let idType: IdentifierType = .uuid
    static let idKey = DB.id.ⓡ
    static var foreignIdKey = DB.id.ⓡ
    let storage = Storage()
    var log: LogProtocol?
    
   
    var jobId: Identifier
    var title: String
    var description: String
    var status: String
    var fromUserId: Identifier
    var to: String
    var type: String
    
    
    public enum DB: String {
        case id = "n_id"
        case jobIdKey = "job_id"
        case title = "title"
        case description = "description"
        case status = "status"
        case fromUserId = "from_user_id"
        case to = "to"
        case type = "type"
    }
    
    init(id: String? = nil, jobId: Identifier, title: String, descrption: String, status: String,
         fromUserId: Identifier, to: String, type: String/*,
         user: User*/) throws {
        self.jobId = jobId
        self.title = title
        self.description = descrption
        self.status = status
        self.fromUserId = fromUserId
        self.to = to
        self.type = type
        
       /* guard let userId = user.id else { throw Abort(.badRequest, reason: "User id not found in vending init") }
        self.userId = userId*/
        if let id = id { self.id = Identifier(id) }
    }
    
    init(row: Row) throws {
        
        jobId = try row.get(DB.jobIdKey.ⓡ)
        title = try row.get(DB.title.ⓡ)
        description = try row.get(DB.description.ⓡ)
        fromUserId =   try row.get(DB.fromUserId.ⓡ)
        status = try row.get(DB.status.ⓡ)
        to = try row.get(DB.to.ⓡ)
        type = try row.get(DB.type.ⓡ)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(DB.jobIdKey.ⓡ, jobId)
        try row.set(DB.title.ⓡ, title)
        try row.set(DB.description.ⓡ, description)
        try row.set(DB.fromUserId.ⓡ, fromUserId)
        try row.set(DB.status.ⓡ, status)
        try row.set(DB.to.ⓡ, to)
        try row.set(DB.type.ⓡ, type)
        return row
    }
}

/*
extension Ntest {
    var owner: Parent<Order, Event> {
        return parent(id: eventId)
    }
}
*/


/*extension Order {
    var owner: Parent<Order, User> {
        return parent(id: userId)
    }
}
*/
extension Ntest: ResponseRepresentable { }
//extension Vending: JSONRepresentable {}

extension Ntest: Preparation {
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

extension Ntest: JSONConvertible {
    
    convenience init(json: JSON) throws {
        
        let id: String?
        let status : String?
        let type: String?
        let to: String?
        let title: String?
        let description: String?
        
        print("Order json=\(json)")
        do { id = try json.get(DB.id.ⓡ) } catch { id = nil }
       /* let rawUserId: String = try json.get(Order.DB.userIdKey.ⓡ)
        guard let auser = try User.find(rawUserId) else {
            throw Abort(.badRequest, reason: "User id \(rawUserId) not found for order")
        }*/

        guard let jobId: String = try json.get(DB.jobIdKey.ⓡ) else {
            throw Abort(.badRequest, reason: "jobid not found for notificatiobn")
        }
        
        guard let fromUserId: String = try json.get(DB.fromUserId.ⓡ) else {
            throw Abort(.badRequest, reason: "fromuserid not found for notification")
        }
        
        do { status = try json.get(DB.status.ⓡ) } catch { status = nil }
        do { type = try json.get(DB.type.ⓡ) } catch { type = nil }
        do { to = try json.get(DB.to.ⓡ) } catch { to = nil }
        do { title = try json.get(DB.title.ⓡ) } catch { title = nil }
         do { description = try json.get(DB.description.ⓡ) } catch { description = nil }

        
        
        try self.init(
            id: id,
            jobId: Identifier(jobId),
            title: title ?? "",
            descrption: description ?? "",
            status: status ?? "", fromUserId: Identifier(fromUserId),
            to: to ?? "",//,
            type: type ?? ""//,
//            user: auser
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(DB.id.ⓡ, id)
        
        
        try json.set(DB.jobIdKey.ⓡ, jobId)
        try json.set(DB.title.ⓡ, title)
        try json.set(DB.description.ⓡ, description)
        try json.set(DB.fromUserId.ⓡ, fromUserId)
        try json.set(DB.status.ⓡ, status)
        try json.set(DB.to.ⓡ, to)
        try json.set(DB.type.ⓡ, type)
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



extension Ntest: TokenAuthenticatable {
    typealias TokenType = Token
}

