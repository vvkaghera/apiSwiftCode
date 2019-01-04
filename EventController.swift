//
//  EventController.swift
//  App
//
//  Created by Rashmi Garg on 10/5/18.
//

import Foundation
final class EventController: Controlling {
    fileprivate let log: LogProtocol
    
    init(log: LogProtocol) throws {
        self.log = log
    }
    
    func addOpenRoutes(drop: Droplet) {
        drop.get("events") { req in return try self.get(req) }
    }
    
    
    
    func addGroupedRoutes(group: RouteBuilder) {
        group.post("events") { req in return try self.post(req) }
        group.patch("events") { req in return try self.patch(req) }
        group.delete("events") { req in return try self.delete(req) }
        
        group.get("events/lookup", String.parameter) { req in
            print("============\n\(req)")
            let lookupid = try req.parameters.next(String.self)
            guard let event = try Event.makeQuery()
                .filter(Event.DB.id.ⓡ, lookupid)
                .first()
                else {
                    throw Abort(.badRequest, reason: "Event: \(lookupid) does not exist")
            }
            return event
        }
    }
    fileprivate func get(_ req: Request) throws -> JSON {
        
        let eventQuery = try Event.makeQuery()
        
        var json = JSON()
        try json.set("status", "ok")
        
        try json.set("events", eventQuery.all())
        return json
    }
    
    /*
    fileprivate func get(_ req: Request) throws -> JSON {
        guard let offer = req.data["offer"]?.string else {
            throw Abort(.badRequest, reason: "VFAIL: Bad Parameters")
        }
        let eventQuery = try Event.makeQuery()
        switch offer.lowercased() {
        case "food": try vendingQuery.filter(Vending.DB.offersFood.ⓡ, true)
        case "entertainment": try vendingQuery.filter(Vending.DB.offersEntertainment.ⓡ, true)
        case "music": try vendingQuery.filter(Vending.DB.offersMusic.ⓡ, true)
        case "rentals": try vendingQuery.filter(Vending.DB.offersRentals.ⓡ, true)
        case "services": try vendingQuery.filter(Vending.DB.offersServices.ⓡ, true)
        case "partypacks": try vendingQuery.filter(Vending.DB.offersPartyPacks.ⓡ, true)
        case "venue": try vendingQuery.filter(Vending.DB.offersVenue.ⓡ, true)
        case "all": try vendingQuery
        default:
            throw Abort(.badRequest, reason: "VFAIL: Bad Parameter")
        }
        var json = JSON()
        try json.set("status", "ok")
        try json.set("offer", "\(offer)")
        try json.set("vendings", vendingQuery.all())
        return json
    }
    */
    fileprivate func post(_ req: Request) throws -> JSON {
        //log.error("• in vendings.post()\n\(req)")
        guard let json = req.json else { throw Abort(.badRequest, reason: "No JSON in event post") }
        
        var eventTry: Event?
        do {
            eventTry = try Event(json: json)
        } catch let error as Debuggable {
            eventTry = nil
            throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
        }
        guard let event = eventTry else {
            throw Abort(.badRequest, reason: "Could not construct event")
        }
        
        do {
            try event.save()
        } catch let error as Debuggable {
            throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
        }
        var eventJSON = JSON()
        try eventJSON.set("status", "ok")
        try eventJSON.set("event", event)
        return eventJSON
    }
    
    fileprivate func getEvent(from req: Request) throws -> Event {
        guard let json = req.json else { throw Abort(.badRequest, reason: "Missing JSON") }
        let eventID: String = try json.get(Event.DB.id.ⓡ)
        guard let event = try Event.makeQuery()
            .filter(Event.DB.id.ⓡ, eventID)
            .first()
            else {
                throw Abort(.badRequest, reason: "Event: \(eventID) does not exist")
        }
        return event
    }
    
    // PATCH one
    fileprivate func patch(_ req: Request) throws -> JSON {
        // See `extension Event: Updateable`
        let event = try getEvent(from: req)
        try event.update(for: req)
        try event.save()
        
        var eventJSON = JSON()
        try eventJSON.set("status", "ok")
        try eventJSON.set("event", event)
        return eventJSON
    }
    
    // DELETE one
    fileprivate func delete(_ req: Request) throws -> JSON {
        let event = try getEvent(from: req)
        try event.delete()
        var okJSON = JSON()
        try okJSON.set("status", "ok")
        return okJSON
    }
}
