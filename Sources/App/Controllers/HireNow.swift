//
//  HireNow.swift
//  App
//
//  Created by MAC001 on 05/04/19.
//

import Foundation
import Stripe

final class HireNow: Controlling {
    fileprivate let log: LogProtocol
    
    init(log: LogProtocol) throws {
        self.log = log
    }
    
    func addOpenRoutes(drop: Droplet) {
        drop.get("orders") { req in return try self.get(req) }
    }
    
    func addGroupedRoutes(group: RouteBuilder) {
        group.post("orders") { req in return try self.post(req) }
        group.patch("orders") { req in return try self.patch(req) }
        group.delete("orders") { req in return try self.delete(req) }
        
        group.get("orders/lookup", String.parameter) { req in
            print("============\n\(req)")
            let lookupid = try req.parameters.next(String.self)
            guard let order = try Order.makeQuery()
                .filter(Order.DB.id.ⓡ, lookupid)
                .first()
                else {
                    throw Abort(.badRequest, reason: "Order/event: \(lookupid) does not exist")
            }
            return order
        }
    }
    fileprivate func get(_ req: Request) throws -> JSON {
        
        let orderQuery = try Order.makeQuery()
        
        var json = JSON()
        try json.set("status", "ok")
        
        try json.set("orders", orderQuery.all())
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
        guard let json = req.json else { throw Abort(.badRequest, reason: "No JSON in order/event post") }
        
        //CheckCardIs Added or not
        var orderJSON = JSON()
        
        guard let user = try User.makeQuery()
            .filter(User.DB.id.ⓡ, req.data["user_id"])
            .first()
            else {
                throw Abort(.badRequest, reason: "User does not exist")
        }
        
        do {
            let stripeClient = try StripeClient(apiKey: Constants.publishableKey)
            stripeClient.initializeRoutes()
            
            let aUserQuery = try stripeClient.customer.retrieve(customer: user.stripeCustomer_id!)
            let aUserResponse = try aUserQuery.serializedResponse()
            
            guard (aUserResponse.sources?.cardSources.count)! > 0 else {
                try orderJSON.set("status", "fail")
                try orderJSON.set("message", "Please add card to finalize this order!")
                return orderJSON
            }
            
            guard let event = try Event.makeQuery()
                .filter(Event.DB.id.ⓡ, req.data["event_id"])
                .first()
                else {
                    throw Abort(.badRequest, reason: "User does not exist")
            }
            
            let hourDiff = Calendar.current.dateComponents([.hour], from: event.startTime, to: event.endTime).hour
            
            guard let service = try Service.makeQuery()
                .filter(Service.DB.id.ⓡ, req.data["service_id"])
                .first()
                else {
                    throw Abort(.badRequest, reason: "User does not exist")
            }
            
            var aPriceStr : String = service.costWithUnit.components(separatedBy: CharacterSet(charactersIn: " " + "/")).first!
            _ = aPriceStr.remove(at: aPriceStr.startIndex)
            
            var aChargeAmount = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: aPriceStr)) ?
                Int(aPriceStr)! : 50
            
            aChargeAmount = (hourDiff! * (aChargeAmount * 100))/2
            
            /*
             if service.costWithUnit.contains("Per Person"){
             
             }
             else if service.costWithUnit.contains("Per Hour"){
             
             }
             else if service.costWithUnit.contains("Per Day"){
             
             }
             else if service.costWithUnit.contains("Each"){
             
             }
             else if service.costWithUnit.contains("Per Person, Per Hour"){
             
             }
             else if service.costWithUnit.contains("Per Person, Per Day"){
             
             }
             else {
             
             }
             */
            
            
            let charge = try stripeClient.charge.create(amount: aChargeAmount, in: .usd, description : "Deposit of \(service.description)", customer: user.stripeCustomer_id!, statementDescriptor: "First Purchase")
            let chargeResponse = try charge.serializedResponse()
            
            print(chargeResponse)
            if chargeResponse.status == Stripe.StripeStatus.succeeded{
                
            }
            else{
                try orderJSON.set("status", "fail")
                try orderJSON.set("message", chargeResponse.failureMessage)
                return orderJSON
            }
        } catch {
            print("The file could not be loaded")
        }
        
        var orderTry: Order?
        do {
            orderTry = try Order(json: json)
        } catch let error as Debuggable {
            orderTry = nil
            throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
        }
        guard let order = orderTry else {
            throw Abort(.badRequest, reason: "Could not construct order")
        }
        
        do {
            try order.save()
        } catch let error as Debuggable {
            throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
        }
        
        
        try orderJSON.set("status", "ok")
        try orderJSON.set("order", order)
        
        return orderJSON
    }
    
    fileprivate func getOrder(from req: Request) throws -> Order {
        guard let json = req.json else { throw Abort(.badRequest, reason: "Missing JSON") }
        let orderID: String = try json.get(Order.DB.id.ⓡ)
        guard let order = try Order.makeQuery()
            .filter(Order.DB.id.ⓡ, orderID)
            .first()
            else {
                throw Abort(.badRequest, reason: "Order/Event: \(orderID) does not exist")
        }
        return order
    }
    
    // PATCH one
    fileprivate func patch(_ req: Request) throws -> JSON {
        // See `extension Event: Updateable`
        let order = try getOrder(from: req)
        /*try order.update(for: req)*/
        try order.save()
        
        var orderJSON = JSON()
        try orderJSON.set("status", "ok")
        try orderJSON.set("order", order)
        return orderJSON
    }
    
    // DELETE one
    fileprivate func delete(_ req: Request) throws -> JSON {
        let order = try getOrder(from: req)
        try order.delete()
        var okJSON = JSON()
        try okJSON.set("status", "ok")
        return okJSON
    }
}
