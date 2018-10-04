//
//  VendingController.swift
//  Created by Steven O'Toole on 9/15/17.
//
import Vapor

final class VendingController: Controlling {
    fileprivate let log: LogProtocol

    init(log: LogProtocol) throws {
        self.log = log
    }

    func addOpenRoutes(drop: Droplet) {
        drop.get("vendings") { req in return try self.get(req) }
    }

    func addGroupedRoutes(group: RouteBuilder) {
        group.post("vendings") { req in return try self.post(req) }
        group.patch("vendings") { req in return try self.patch(req) }
        group.delete("vendings") { req in return try self.delete(req) }

        group.get("vendings/lookup", String.parameter) { req in
            print("============\n\(req)")
            let lookupid = try req.parameters.next(String.self)
            guard let vending = try Vending.makeQuery()
                .filter(Vending.DB.id.ⓡ, lookupid)
                .first()
                else {
                    throw Abort(.badRequest, reason: "Vending: \(lookupid) does not exist")
            }
            return vending
        }
    }

    fileprivate func get(_ req: Request) throws -> JSON {
        guard let offer = req.data["offer"]?.string else {
            throw Abort(.badRequest, reason: "VFAIL: Bad Parameters")
        }
        let vendingQuery = try Vending.makeQuery()
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

    fileprivate func post(_ req: Request) throws -> JSON {
        //log.error("• in vendings.post()\n\(req)")
        guard let json = req.json else { throw Abort(.badRequest, reason: "No JSON in vending post") }

        var vendingTry: Vending?
        do {
            vendingTry = try Vending(json: json)
        } catch let error as Debuggable {
            vendingTry = nil
            throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
        }
        guard let vending = vendingTry else {
            throw Abort(.badRequest, reason: "Could not construct vending")
        }

        do {
            try vending.save()
        } catch let error as Debuggable {
            throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
        }
        var vendingJSON = JSON()
        try vendingJSON.set("status", "ok")
        try vendingJSON.set("vending", vending)
        return vendingJSON
    }

    fileprivate func getVending(from req: Request) throws -> Vending {
        guard let json = req.json else { throw Abort(.badRequest, reason: "Missing JSON") }
        let vendingID: String = try json.get(Vending.DB.id.ⓡ)
        guard let vending = try Vending.makeQuery()
            .filter(Vending.DB.id.ⓡ, vendingID)
            .first()
            else {
                throw Abort(.badRequest, reason: "Vending: \(vendingID) does not exist")
        }
        return vending
    }

    // PATCH one
    fileprivate func patch(_ req: Request) throws -> JSON {
        // See `extension Vending: Updateable`
        let vending = try getVending(from: req)
        try vending.update(for: req)
        try vending.save()

        var vendingJSON = JSON()
        try vendingJSON.set("status", "ok")
        try vendingJSON.set("vending", vending)
        return vendingJSON
    }

   // DELETE one
    fileprivate func delete(_ req: Request) throws -> JSON {
        let vending = try getVending(from: req)
        try vending.delete()
        var okJSON = JSON()
        try okJSON.set("status", "ok")
        return okJSON
    }
}
