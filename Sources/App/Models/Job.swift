//
//  Job.swift
//  App
//
//  Created by MAC001 on 22/04/19.
//

import Foundation
import AuthProvider
import FluentProvider

final class Job: Model, Timestampable {
    static let idType: IdentifierType = .uuid
    static let idKey = DB.id.ⓡ
    static var foreignIdKey = DB.id.ⓡ
    let storage = Storage()
    var log: LogProtocol?
    
    var status: String
    var additionalNotes: String
    var eventId: Identifier
    var categoryOrService: String
    var proposedCost: String
    var offersFood = false
    var offersEntertainment = false
    var offersMusic = false
    var offersRentals = false
    var offersServices = false
    var offersPartyPacks = false
    var offersVenue = false
    var userId: Identifier
    
    
    public enum DB: String {
        case id = "job_id"
        case eventIdKey = "event_id"
        case categoryOrService = "category_or_service"
        case status = "status"
        case additionalNotes = "additional_notes"
        case proposedCost = "proposed_cost"
        case offersFood = "offers_food"
        case offersEntertainment = "offers_entertainment"
        case offersMusic = "offers_music"
        case offersRentals = "offers_rentals"
        case offersServices = "offers_services"
        case offersPartyPacks = "offers_party_packs"
        case offersVenue = "offers_venue"
        case userIdKey = "user_id"
        case bids
    }
    
    init(id: String? = nil, eventId: Identifier, categoryOrService: String, status: String,
         additionalNotes: String, proposedCost: String,
         offersFood: Bool?, offersEntertainment: Bool?, offersMusic: Bool?,
         offersRentals: Bool?, offersServices: Bool?, offersPartyPacks: Bool?, offersVenue: Bool?, userId: Identifier) throws {
        self.eventId = eventId
        self.categoryOrService = categoryOrService
        self.status = status
        self.additionalNotes = additionalNotes
        self.proposedCost = proposedCost
        self.offersFood = offersFood ?? false
        self.offersEntertainment = offersEntertainment ?? false
        self.offersMusic = offersMusic ?? false
        self.offersRentals = offersRentals ?? false
        self.offersServices = offersServices ?? false
        self.offersVenue = offersVenue ?? false
        self.userId = userId
        /* guard let userId = user.id else { throw Abort(.badRequest, reason: "User id not found in vending init") }
         self.userId = userId*/
        if let id = id { self.id = Identifier(id) }
    }
    
    init(row: Row) throws {
        
        eventId = try row.get(DB.eventIdKey.ⓡ)
        categoryOrService = try row.get(DB.categoryOrService.ⓡ)
        status = try row.get(DB.status.ⓡ)
        additionalNotes = try row.get(DB.additionalNotes.ⓡ)
        proposedCost = try row.get(DB.proposedCost.ⓡ)
        offersFood = try row.get(DB.offersFood.ⓡ)
        offersEntertainment = try row.get(DB.offersEntertainment.ⓡ)
        offersMusic = try row.get(DB.offersMusic.ⓡ)
        offersRentals = try row.get(DB.offersRentals.ⓡ)
        offersServices = try row.get(DB.offersServices.ⓡ)
        offersPartyPacks = try row.get(DB.offersPartyPacks.ⓡ)
        offersVenue = try row.get(DB.offersVenue.ⓡ)
         userId = try row.get(DB.userIdKey.ⓡ)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(DB.eventIdKey.ⓡ, eventId)
        try row.set(DB.categoryOrService.ⓡ, categoryOrService)
        try row.set(DB.status.ⓡ, status)
        try row.set(DB.additionalNotes.ⓡ, additionalNotes)
        try row.set(DB.proposedCost.ⓡ, proposedCost)
        try row.set(DB.offersFood.ⓡ, offersFood)
        try row.set(DB.offersEntertainment.ⓡ, offersEntertainment)
        try row.set(DB.offersMusic.ⓡ, offersMusic)
        try row.set(DB.offersRentals.ⓡ, offersRentals)
        try row.set(DB.offersServices.ⓡ, offersServices)
        try row.set(DB.offersPartyPacks.ⓡ, offersPartyPacks)
        try row.set(DB.offersVenue.ⓡ, offersVenue)
         try row.set(DB.userIdKey.ⓡ, userId)
        return row
    }
}

/*extension Order {
    var owner: Parent<Order, Event> {
        return parent(id: eventId)
    }
}*/
extension Job {
    var owner: Parent<Job, Event> {
        return parent(id: eventId)
    }
}

extension Job {
    var bids: Children<Job, Bid> {
        return children()
    }
}

//extension Job {
//    var notification: Children<Job, Notification> {
//        return children()
//    }
//}

extension Job: ResponseRepresentable { }
//extension Vending: JSONRepresentable {}

extension Job: Preparation {
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

extension Job: JSONConvertible {
    
    convenience init(json: JSON) throws {
        
        let id: String?
        let status : String?
        let additionalNotes: String?
        let proposedCost: String?
        let offersFood: Bool?
        let offersEntertainment: Bool?
        let offersMusic: Bool?
        let offersRentals: Bool?
        let offersServices: Bool?
        let offersPartyPacks: Bool?
        let offersVenue: Bool?
        
        print("Job json=\(json)")
        do { id = try json.get(DB.id.ⓡ) } catch { id = nil }
     
        guard let aeventId: String = try json.get(DB.eventIdKey.ⓡ) else {
            throw Abort(.badRequest, reason: "eventid not found for job")
        }
        
        guard let acategotyOrService: String = try json.get(DB.categoryOrService.ⓡ) else {
            throw Abort(.badRequest, reason: "categoryOrService not found for job")
        }
        
        do { status = try json.get(DB.status.ⓡ) } catch { status = nil }
        do { additionalNotes = try json.get(DB.additionalNotes.ⓡ) } catch { additionalNotes = nil }
        do { proposedCost = try json.get(DB.proposedCost.ⓡ) } catch { proposedCost = nil }
        
        do { offersFood = try json.get(DB.offersFood.ⓡ) } catch { offersFood = false }
        do { offersEntertainment = try json.get(DB.offersEntertainment.ⓡ) } catch { offersEntertainment = false }
        do { offersMusic = try json.get(DB.offersMusic.ⓡ) } catch { offersMusic = false }
        do { offersRentals = try json.get(DB.offersRentals.ⓡ) } catch { offersRentals = false }
        do { offersServices = try json.get(DB.offersServices.ⓡ) } catch { offersServices = false }
        do { offersPartyPacks = try json.get(DB.offersPartyPacks.ⓡ) } catch { offersPartyPacks = false }
        do { offersVenue = try json.get(DB.offersVenue.ⓡ ) } catch { offersVenue = false }
        guard let auserId: String = try json.get(DB.userIdKey.ⓡ) else {
            throw Abort(.badRequest, reason: "userid not found for job")
        }
        
        
        try self.init(
            id: id,
            eventId: Identifier(aeventId),
            categoryOrService: acategotyOrService,
            status: status ?? "",
            additionalNotes: additionalNotes ?? "",
            proposedCost: proposedCost ?? "",
            offersFood: offersFood, offersEntertainment: offersEntertainment,
            offersMusic: offersMusic,
            offersRentals: offersRentals, offersServices: offersServices,
            offersPartyPacks: offersPartyPacks,
            offersVenue: offersVenue,
            userId: Identifier(auserId)
           
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(DB.id.ⓡ, id)
        
        
        try json.set(DB.eventIdKey.ⓡ, eventId)
        try json.set(DB.categoryOrService.ⓡ, categoryOrService)
        try json.set(DB.status.ⓡ, status)
        try json.set(DB.additionalNotes.ⓡ, additionalNotes)
        try json.set(DB.proposedCost.ⓡ, proposedCost)
        try json.set(DB.offersFood.ⓡ, offersFood)
        try json.set(DB.offersEntertainment.ⓡ, offersEntertainment)
        try json.set(DB.offersMusic.ⓡ, offersMusic)
        try json.set(DB.offersRentals.ⓡ, offersRentals)
        try json.set(DB.offersServices.ⓡ, offersServices)
        try json.set(DB.offersPartyPacks.ⓡ, offersPartyPacks)
        try json.set(DB.offersVenue.ⓡ, offersVenue)
        try json.set(DB.userIdKey.ⓡ, userId)
        try json.set(DB.bids.ⓡ, bids.all())
        print("json sent is", json)
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

extension Job: TokenAuthenticatable {
    typealias TokenType = Token
}

