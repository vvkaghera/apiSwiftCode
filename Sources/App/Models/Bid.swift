//
//  Bid.swift
//  App
//
//  Created by MAC001 on 07/05/19.
//

import Foundation
import AuthProvider
import FluentProvider

final class Bid: Model, Timestampable {
    static let idType: IdentifierType = .uuid
    static let idKey = DB.id.ⓡ
    static var foreignIdKey = DB.id.ⓡ
    let storage = Storage()
    var log: LogProtocol?
    
    var status: String
    var jobId: Identifier
    var vendingId: Identifier
    var eventId: Identifier
    var cost: String
    
    
    public enum DB: String {
        case id = "bid_id"
        case eventIdKey = "event_id"
        case status = "status"
        case cost = "cost"
        case jobIdKey = "job_id"
        case vendingIdKey = "vending_id"
        case vending
    }
    
    init(id: String? = nil, jobId: Identifier, vendingId: Identifier, eventId: Identifier, cost: String, status: String) throws {
       
        self.jobId = jobId
        self.vendingId = vendingId
        self.eventId = eventId
        self.status = status
        self.cost = cost
        
        
        /* guard let userId = user.id else { throw Abort(.badRequest, reason: "User id not found in vending init") }
         self.userId = userId*/
        if let id = id { self.id = Identifier(id) }
    }
    
    init(row: Row) throws {
        
        jobId = try row.get(DB.jobIdKey.ⓡ)
        vendingId = try row.get(DB.vendingIdKey.ⓡ)
        eventId = try row.get(DB.eventIdKey.ⓡ)
        cost = try row.get(DB.cost.ⓡ)
        status = try row.get(DB.status.ⓡ)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(DB.jobIdKey.ⓡ, jobId)
        try row.set(DB.vendingIdKey.ⓡ, vendingId)
        try row.set(DB.eventIdKey.ⓡ, eventId)
        try row.set(DB.cost.ⓡ, cost)
        try row.set(DB.status.ⓡ, status)
        return row
    }
}

extension Bid {
    var owner: Parent<Bid, Job> {
        return parent(id: jobId)
    }
}

extension Bid {
    var vending: Parent<Bid, Vending> {
        return parent(id: vendingId)
    }
}

//extension Bid {
//    var vending: Children<Bid, Vending> {
//        return children()
//    }
//}

extension Bid: ResponseRepresentable { }
//extension Vending: JSONRepresentable {}

extension Bid: Preparation {
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

extension Bid: JSONConvertible {
    
    convenience init(json: JSON) throws {
        
        let id: String?
        let status : String?
        let cost: String?
        
        print("Bid json=\(json)")
        do { id = try json.get(DB.id.ⓡ) } catch { id = nil }
     
        guard let ajobId: String = try json.get(DB.jobIdKey.ⓡ) else {
            throw Abort(.badRequest, reason: "jobid not found for bid")
        }
        
        guard let avendingId: String = try json.get(DB.vendingIdKey.ⓡ) else {
            throw Abort(.badRequest, reason: "vendingid not found for bid")
        }
        
        guard let aeventId: String = try json.get(DB.eventIdKey.ⓡ) else {
            throw Abort(.badRequest, reason: "eventid not found for bid")
        }
        
        do { status = try json.get(DB.status.ⓡ) } catch { status = nil }
        do { cost = try json.get(DB.cost.ⓡ) } catch { cost = nil }
        
        
        try self.init(
            id: id,
            jobId: Identifier(ajobId),
            vendingId: Identifier(avendingId),
            eventId: Identifier(aeventId),
            cost: cost ?? "", status: status ?? ""
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(DB.id.ⓡ, id)
       
        try json.set(DB.jobIdKey.ⓡ, jobId)
        try json.set(DB.vendingIdKey.ⓡ, vendingId)
        try json.set(DB.eventIdKey.ⓡ, eventId)
        try json.set(DB.status.ⓡ, status)
        try json.set(DB.cost.ⓡ, cost)
        try json.set(DB.vending.ⓡ, vending.all())
        print("bid sent is", json)
        return json
    }
}

/*extension Job: Updateable {
    public static var updateableKeys: [UpdateableKey<Job>] {
        return [
            UpdateableKey(DB.eventIdKey.ⓡ, Identifier.self) { job, content in job.eventId = content },
            UpdateableKey(DB.categoryOrService.ⓡ, String.self) { job, content in job.categoryOrService = content },
            UpdateableKey(DB.status.ⓡ, String.self) { job, content in job.status = content },
            UpdateableKey(DB.additionalNotes.ⓡ, String.self) { job, content in job.additionalNotes = content },
            UpdateableKey(DB.proposedCost.ⓡ, String.self) { job, content in job.proposedCost = content },
            UpdateableKey(DB.offersFood.ⓡ, Bool.self) { job, content in job.offersFood = content },
            UpdateableKey(DB.offersEntertainment.ⓡ, Bool.self) { job, content in job.offersEntertainment = content },
            UpdateableKey(DB.offersMusic.ⓡ, Bool.self) { job, content in job.offersMusic = content },
            UpdateableKey(DB.offersRentals.ⓡ, Bool.self) { job, content in job.offersRentals = content },
            UpdateableKey(DB.offersServices.ⓡ, Bool.self) { job, content in job.offersServices = content },
            UpdateableKey(DB.offersPartyPacks.ⓡ, Bool.self) { job, content in job.offersPartyPacks = content },
            UpdateableKey(DB.offersVenue.ⓡ, Bool.self) { job, content in job.offersVenue = content },
            UpdateableKey(DB.userIdKey.ⓡ, Identifier.self) { job, content in job.userId = content }
        ]
    }
}
*/

extension Bid: TokenAuthenticatable {
    typealias TokenType = Token
}

