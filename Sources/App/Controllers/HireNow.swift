//
//  HireNow.swift
//  App
//
//  Created by MAC001 on 05/04/19.
//

import Foundation
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
        var orderJSON = JSON()
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
