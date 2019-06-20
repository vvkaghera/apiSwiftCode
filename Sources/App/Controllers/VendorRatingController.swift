//
//  VendorRatingController.swift
//  App
//
//  Created by MAC001 on 23/04/19.
//

import Foundation

final class VendorRatingController: Controlling {
    fileprivate let log: LogProtocol
    
    init(log: LogProtocol) throws {
        self.log = log
    }
    
    func addOpenRoutes(drop: Droplet) {
        drop.get("vendorRating") { req in return try self.get(req) }
    }
    
    func addGroupedRoutes(group: RouteBuilder) {
        group.post("vendorRating") { req in return try self.post(req) }
        group.patch("vendorRating") { req in return try self.patch(req) }
        group.delete("vendorRating") { req in return try self.delete(req) }
        
        group.get("vendorRating/lookup", String.parameter) { req in
            print("============\n\(req)")
            let lookupid = try req.parameters.next(String.self)
            guard let order = try VendorRating.makeQuery()
                .filter(VendorRating.DB.id.ⓡ, lookupid)
                .first()
                else {
                    throw Abort(.badRequest, reason: "VendorRating: \(lookupid) does not exist")
            }
            return order
        }
    }
    fileprivate func get(_ req: Request) throws -> JSON {
        
        let aVendorRatingQuery = try VendorRating.makeQuery()
        
        var json = JSON()
        try json.set("status", "ok")
        
        try json.set("VendorRatings", aVendorRatingQuery.all())
        return json
    }
    
    fileprivate func post(_ req: Request) throws -> JSON {
        //log.error("• in vendings.post()\n\(req)")
        guard let json = req.json else { throw Abort(.badRequest, reason: "No JSON in VendorRating post") }
        
        var aVendorRatingTry: VendorRating?
        do {
            aVendorRatingTry = try VendorRating(json: json)
        } catch let error as Debuggable {
            aVendorRatingTry = nil
            throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
        }
        guard let aVendorRating = aVendorRatingTry else {
            throw Abort(.badRequest, reason: "Could not construct VendorRating")
        }
        
        do {
            try aVendorRating.save()
        } catch let error as Debuggable {
            throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
        }
        var orderJSON = JSON()
        try orderJSON.set("status", "ok")
        try orderJSON.set("VendorRating", aVendorRating)
        return orderJSON
    }
    
    fileprivate func getVendorrating(from req: Request) throws -> VendorRating {
        guard let json = req.json else { throw Abort(.badRequest, reason: "Missing JSON") }
        let aVendorRatingID: String = try json.get(VendorRating.DB.id.ⓡ)
        guard let aVendorRating = try VendorRating.makeQuery()
            .filter(VendorRating.DB.id.ⓡ, aVendorRatingID)
            .first()
            else {
                throw Abort(.badRequest, reason: "VendorRating: \(aVendorRatingID) does not exist")
        }
        return aVendorRating
    }
    
    // PATCH one
    fileprivate func patch(_ req: Request) throws -> JSON {
        // See `extension Event: Updateable`
        let aVendorRating = try getVendorrating(from: req)
        /*try order.update(for: req)*/
        try aVendorRating.save()
        
        var aVendorRatingJSON = JSON()
        try aVendorRatingJSON.set("status", "ok")
        try aVendorRatingJSON.set("VendorRating", aVendorRating)
        return aVendorRatingJSON
    }
    
    // DELETE one
    fileprivate func delete(_ req: Request) throws -> JSON {
        let aVendorRating = try getVendorrating(from: req)
        try aVendorRating.delete()
        var okJSON = JSON()
        try okJSON.set("status", "ok")
        return okJSON
    }
}
