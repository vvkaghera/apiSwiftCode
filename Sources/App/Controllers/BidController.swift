//
//  Bid.swift
//  App
//
//  Created by MAC001 on 07/05/19.
//

import Foundation

final class BidController: Controlling {
    fileprivate let log: LogProtocol
    
    init(log: LogProtocol) throws {
        self.log = log
    }
    
    func addOpenRoutes(drop: Droplet) {
        drop.get("bid") { req in return try self.get(req) }
    }
    
    
    func addGroupedRoutes(group: RouteBuilder) {
        group.post("bid") { req in return try self.post(req) }
        group.patch("bid") { req in return try self.patch(req) }
        group.delete("bid") { req in return try self.delete(req) }
        
        group.get("bid/lookup", String.parameter) { req in
            print("============\n\(req)")
            let lookupid = try req.parameters.next(String.self)
            guard let aBid = try Bid.makeQuery()
                .filter(Bid.DB.id.ⓡ, lookupid)
                .first()
                else {
                    throw Abort(.badRequest, reason: "Bid: \(lookupid) does not exist")
            }
            return aBid
        }
    }
    fileprivate func get(_ req: Request) throws -> JSON {
        
        let bidQuery = try Bid.makeQuery()
        
        var json = JSON()
        try json.set("status", "ok")
        
        try json.set("Bids", bidQuery.all())
        return json
    }
   
    fileprivate func getVendorsOfBid(_ req: Request) throws -> JSON {
        
        let bidQuery = try Bid.makeQuery()
        
        var json = JSON()
        try json.set("status", "ok")
        
        try json.set("Bids", bidQuery.all())
        return json
    }
    
    fileprivate func post(_ req: Request) throws -> JSON {
        //log.error("• in vendings.post()\n\(req)")
        guard let json = req.json else { throw Abort(.badRequest, reason: "No JSON in bid post") }
        
        var bidTry: Bid?
        do {
            bidTry = try Bid(json: json)
        } catch let error as Debuggable {
            bidTry = nil
            throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
        }
        guard let bid = bidTry else {
            throw Abort(.badRequest, reason: "Could not construct bid")
        }
        
        do {
            try bid.save()
        } catch let error as Debuggable {
            throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
        }
        var bidJSON = JSON()
        try bidJSON.set("status", "ok")
        try bidJSON.set("bid", bid)
        return bidJSON
    }
    
    fileprivate func getBid(from req: Request) throws -> Bid {
        guard let json = req.json else { throw Abort(.badRequest, reason: "Missing JSON") }
        let bidID: String = try json.get(Bid.DB.id.ⓡ)
        guard let bid = try Bid.makeQuery()
            .filter(Bid.DB.id.ⓡ, bidID)
            .first()
            else {
                throw Abort(.badRequest, reason: "Bid: \(bidID) does not exist")
        }
        return bid
    }
    
    // PATCH one
    fileprivate func patch(_ req: Request) throws -> JSON {
        // See `extension Event: Updateable`
        let bid = try getBid(from: req)
        
        try bid.save()
        
        var bidJSON = JSON()
        try bidJSON.set("status", "ok")
        try bidJSON.set("bid", bid)
        return bidJSON
    }
    
    // DELETE one
    fileprivate func delete(_ req: Request) throws -> JSON {
        let bid = try getBid(from: req)
        try bid.delete()
        var okJSON = JSON()
        try okJSON.set("status", "ok")
        return okJSON
    }
}
