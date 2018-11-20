//
//  Event.swift
//  App
//
//  Created by Rashmi Garg on 10/5/18.
//

import Foundation
import AuthProvider
import FluentProvider

final class Event: Model, Timestampable {
    static let idType: IdentifierType = .uuid
    static let idKey = DB.id.ⓡ
    static var foreignIdKey = DB.id.ⓡ
    let storage = Storage()
    var log: LogProtocol?
    
    var eventName: String
    var eventDate: Date
    var startTime: Date
    var endTime: Date
    var location: String
    var longDescription: String?
    var noOfGuests: String?
    var userId: Identifier
    
    
    public enum DB: String {
        case id = "event_id"
        case eventName = "event_name"
        case eventDate = "event_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case location = "location"
        case longDescription = "long_description"
        case noOfGuests = "no_of_guests"
        case userIdKey = "user_id"
        
    }
    
    init(id: String? = nil, eventName: String, eventDate: Date, startTime: Date, endTime: Date, location: String,
         longDescription: String?, noOfGuests: String?,
         user: User) throws {
        self.eventName = eventName
        self.eventDate = eventDate
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.longDescription = longDescription
        self.noOfGuests = noOfGuests
        guard let userId = user.id else { throw Abort(.badRequest, reason: "User id not found in vending init") }
        self.userId = userId
        if let id = id { self.id = Identifier(id) }
    }
    
    init(row: Row) throws {
        let dateFormatter = DateFormatter()
        //let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        //dateFormatter.locale = enUSPosixLocale
        //dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.timeZone = TimeZone.init(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        //dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        eventName = try row.get(DB.eventName.ⓡ)
        
        eventDate = try row.get(DB.eventDate.ⓡ)
        startTime = try row.get(DB.startTime.ⓡ)
        endTime =   try row.get(DB.endTime.ⓡ)
        location = try row.get(DB.location.ⓡ)
        longDescription = try row.get(DB.longDescription.ⓡ)
        noOfGuests = try row.get(DB.noOfGuests.ⓡ)
        userId = try row.get(DB.userIdKey.ⓡ)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(DB.eventName.ⓡ, eventName)
        try row.set(DB.eventDate.ⓡ, eventDate)
        try row.set(DB.startTime.ⓡ, startTime)
        try row.set(DB.endTime.ⓡ, endTime)
        try row.set(DB.location.ⓡ, location)
        try row.set(DB.longDescription.ⓡ, longDescription)
        try row.set(DB.noOfGuests.ⓡ, noOfGuests)
        try row.set(DB.userIdKey.ⓡ, userId)
        return row
    }
}

extension Event {
    var owner: Parent<Event, User> {
        return parent(id: userId)
    }
}
extension Event: ResponseRepresentable { }
//extension Vending: JSONRepresentable {}

extension Event: Preparation {
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

extension Event: JSONConvertible {
    
    convenience init(json: JSON) throws {
        
        let id: String?
        let longDescription : String?
        let noOfGuests: String?
        //let eventDate: Date?
        //let startTime: Date?
        //let endTime: Date?
        
        
        
        print("Event json=\(json)")
        do { id = try json.get(DB.id.ⓡ) } catch { id = nil }
        let rawUserId: String = try json.get(Vending.DB.userIdKey.ⓡ)
        guard let user = try User.find(rawUserId) else {
            throw Abort(.badRequest, reason: "User id \(rawUserId) not found for event")
        }
        guard let eventName: String = try json.get(DB.eventName.ⓡ) else {
            throw Abort(.badRequest, reason: "Event Name not found for event")
        }
        

        let dateFormatter = DateFormatter()
        //let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        //dateFormatter.locale = enUSPosixLocale
        //dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.timeZone = TimeZone.init(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        
        guard let eventDate: Date = try dateFormatter.date(from: json.get(DB.eventDate.ⓡ )) else {
            throw Abort(.badRequest, reason: "Event Date not found for event")
        }
        
        guard let startTime: Date = try dateFormatter.date(from: json.get(DB.startTime.ⓡ)) else {
            throw Abort(.badRequest, reason: "Start Time not found for event")
        }
        guard let endTime: Date = try dateFormatter.date(from: json.get(DB.endTime.ⓡ)) else {
            throw Abort(.badRequest, reason: "End Time not found for event")
        }
        
        guard let location: String = try json.get(DB.location.ⓡ) else {
            throw Abort(.badRequest, reason: "Location not found for event")
        }
        
        
        do { longDescription = try json.get(DB.longDescription.ⓡ) } catch { longDescription = nil }
        do { noOfGuests = try json.get(DB.noOfGuests.ⓡ) } catch { noOfGuests = nil }
        
        
        
        try self.init(
            id: id,
            eventName: eventName,
            eventDate: eventDate,
            startTime: startTime,
            endTime: endTime,
            location: location,
            longDescription: longDescription,
            noOfGuests: noOfGuests,
            user: user
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(DB.id.ⓡ, id)
        
        
        try json.set(DB.eventName.ⓡ, eventName)
        try json.set(DB.eventDate.ⓡ, eventDate)
        try json.set(DB.startTime.ⓡ, startTime)
        try json.set(DB.endTime.ⓡ, endTime)
        try json.set(DB.location.ⓡ, location)
        try json.set(DB.longDescription.ⓡ, longDescription)
        try json.set(DB.noOfGuests.ⓡ, noOfGuests)
        try json.set(DB.userIdKey.ⓡ, userId)
        print("json sent is", json)
        return json
    }
}

extension Event: Updateable {
    
    
    public static var updateableKeys: [UpdateableKey<Event>] {
        return [
            UpdateableKey(DB.eventName.ⓡ, String.self) { event, content in event.eventName = content },
            UpdateableKey(DB.eventDate.ⓡ, Date.self) {event, content in event.eventDate = content},
            UpdateableKey(DB.startTime.ⓡ, Date.self) { event, content in event.startTime = content },
            UpdateableKey(DB.endTime.ⓡ, Date.self) { event, content in event.endTime = content },
            //UpdateableKey(DB.eventDate.ⓡ, String.self) {event, content in event.eventDate = content},
            //UpdateableKey(DB.startTime.ⓡ, String.self) { event, content in event.startTime = content },
            //UpdateableKey(DB.endTime.ⓡ, String.self) { event, content in event.endTime = content },
            UpdateableKey(DB.location.ⓡ, String.self) { event, content in event.location = content },
            UpdateableKey(DB.longDescription.ⓡ, String.self) { event, content in event.longDescription = content },
            UpdateableKey(DB.noOfGuests.ⓡ, String.self) { event, content in event.noOfGuests = content }
            
        ]
    }
}



extension Event: TokenAuthenticatable {
    typealias TokenType = Token
}
extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    func toDate( stringFormat format: String) -> Date
    {
        let dateFormatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter.date(from: format)!
    }
}
