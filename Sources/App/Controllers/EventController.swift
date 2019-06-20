//
//  EventController.swift
//  App
//
//  Created by Rashmi Garg on 10/5/18.
//

import Foundation
import Stripe

final class EventController: Controlling {
    fileprivate let log: LogProtocol
    
    init(log: LogProtocol) throws {
        self.log = log
    }
    
    func addOpenRoutes(drop: Droplet) {
        drop.get("events") { req in return try self.get(req) }
        drop.get("eventsofuser") { req in return try self.getEventsOfUser(req) }
    }
    
    func addSpecificRoutes(router: Router) {
        
        router.get("events/list", String.parameter) { req in
            print("============\n\(req)")

            let lookupid = try req.parameters.next(String.self)
            guard let event : [Event] = try Event.makeQuery()
                .filter(Event.DB.userIdKey.ⓡ, lookupid)
                .all()
                else {
                    throw Abort(.badRequest, reason: "Event list: \(lookupid) does not exist")
            }
            var json = JSON()
            try json.set("status", "ok")
            try json.set("events", event)
            return json
        }
 
        //-------------------
        
        router.post("events/list") { req in
            guard let json = req.json else { throw Abort(.badRequest, reason: "Missing JSON") }
            let aUserID: String = try json.get(Event.DB.userIdKey.ⓡ)
            
            
            guard let events : [Event]  = try Event.makeQuery()
                .filter(Event.DB.userIdKey.ⓡ, aUserID)
                .all()
                else {
                    throw Abort(.badRequest, reason: "Event list: \(aUserID) does not exist")
            }
            
            guard let bids : [Bid]  = try Bid.makeQuery()
                .filter(Bid.DB.vendingIdKey.ⓡ, aUserID)
                .filter(Bid.DB.status.ⓡ, .equals, "Open")
                .all()
                else {
                    throw Abort(.badRequest, reason: "No Bids found")
            }
            
            let arrEventIds = bids.map{ $0.eventId }
            guard let myJobs : [Event]  = try Event.makeQuery()
                .filter(Event.self, "event_id", in: arrEventIds)
                .all()
                else {
                    throw Abort(.badRequest, reason: "No jobs for you")
            }
            
            var userJSON = JSON()
            try userJSON.set("EventList", events)
            try userJSON.set("myJobs", myJobs)
            return userJSON
        }
        
        router.post("events/jobComplete") { req in
            guard let json = req.json else { throw Abort(.badRequest, reason: "Missing JSON") }
            var userJSON = JSON()
            
            let aPreviousPaymentInfo = try self.doRemainaingPayment(req: req)
            
            if aPreviousPaymentInfo["status"] == "success"{
                guard let bid = try Bid.makeQuery()
                    .filter(Bid.DB.eventIdKey.ⓡ, req.data["event_id"])
                    .first()
                    else {
                        throw Abort(.badRequest, reason: "No Bids found")
                }
                bid.status = "Close"
                try bid.save()
                
                try userJSON.set("status", "ok")
                try userJSON.set("message", "You have marked this job as a completed")
                return userJSON
            }
            else{
                try userJSON.set("status", "fail")
                try userJSON.set("message", "Something went wrong")
            }
            return userJSON
        }
    }
    
    //Do Remaining Payment
    func doRemainaingPayment(req : Request) throws -> JSON {
        
        var orderJSON = JSON()
        
        guard let user = try User.makeQuery()
            .filter(User.DB.id.ⓡ, req.data["vending_id"])
            .first()
            else {
                throw Abort(.badRequest, reason: "User does not exist")
        }
        
        do {
            let stripeClient = try StripeClient(apiKey: Constants.publishableKey)
            stripeClient.initializeRoutes()
            
            guard let event = try Event.makeQuery()
                .filter(Event.DB.id.ⓡ, req.data["event_id"])
                .first()
                else {
                    throw Abort(.badRequest, reason: "User does not exist")
            }
            
            let hourDiff = Calendar.current.dateComponents([.hour], from: event.startTime, to: event.endTime).hour
            
            //Currently we have set static Id here
            guard let service = try Service.makeQuery()
                //.filter(Service.DB.id.ⓡ, req.data["service_id"])
                .filter(Service.DB.id.ⓡ, "f9cd53c7-461f-4a3d-9ad1-592f7c5350e1")
                .first()
                else {
                    throw Abort(.badRequest, reason: "User does not exist")
            }
            
            var aPriceStr : String = service.costWithUnit.components(separatedBy: CharacterSet(charactersIn: " " + "/")).first!
            _ = aPriceStr.remove(at: aPriceStr.startIndex)
            
            var aChargeAmount = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: aPriceStr)) ?
                Int(aPriceStr)! : 50
            
            aChargeAmount = (hourDiff! * (aChargeAmount * 100))/2

            let charge = try stripeClient.charge.create(amount: aChargeAmount, in: .usd, description : "Deposit of \(service.description)", customer: user.stripeCustomer_id!, statementDescriptor: "Second Purchase")
            let chargeResponse = try charge.serializedResponse()

            if chargeResponse.status == Stripe.StripeStatus.succeeded{
                try orderJSON.set("status", "success")
                try orderJSON.set("message", chargeResponse.failureMessage)
            }
            else{
                try orderJSON.set("status", "fail")
                try orderJSON.set("message", chargeResponse.failureMessage)
                return orderJSON
            }
        } catch {
            print("The file could not be loaded")
        }
        
        return orderJSON
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
        
        guard let token = try Token.makeQuery()
            .filter(Token.DB.token.ⓡ, req.headers["Authorization"]?.components(separatedBy: " ").last)
            .first()
            else {
                throw Abort(.badRequest, reason: "Token not found")
        }
        
        let eventsForParticularUser = try Event.makeQuery()
            .filter(Event.DB.userIdKey.ⓡ, .notEquals, token.userID)
            .all()
        
        var json = JSON()
        try json.set("status", "ok")
        try json.set("events", eventsForParticularUser)
        return json
    }
    
    fileprivate func getEventsOfUser(_ req: Request) throws -> JSON {
        print("getEventsOfUser ============\n\(req)")
//        let lookupid = try req.parameters.next(String.self)
        guard let eventQuery = try Event.makeQuery()
            .filter(Event.DB.userIdKey.ⓡ, "31134d69-8914-46e6-98c2-4edd53690e1b")
            .first()
            else {
                throw Abort(.badRequest, reason: " **** *** *** Event: a779bddb-5e14-4310-b0ca-cccbfab3d781 does not exist")
        }

        var json = JSON()
        try json.set("status", "ok")
        
        try json.set("events", eventQuery)
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
