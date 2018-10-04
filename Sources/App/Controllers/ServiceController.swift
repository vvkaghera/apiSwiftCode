//
//  ServiceController.swift
//  Created by Steven O'Toole on 9/21/17.
//

import Vapor

final class ServiceController: Controlling {
    fileprivate let log: LogProtocol

    init(log: LogProtocol) throws {
        self.log = log
    }

    func addGroupedRoutes(group: RouteBuilder) {
        group.post("services") { req in return try self.post(req) }
        group.patch("services") { req in return try self.patch(req) }
        group.delete("services") { req in return try self.delete(req) }
    }

    fileprivate func post(_ req: Request) throws -> JSON {
        guard let json = req.json else { throw Abort(.badRequest, reason: "No JSON in service post") }

        var serviceTry: Service?
        do {
            serviceTry = try Service(json: json)
        } catch let error as Debuggable {
            serviceTry = nil
            throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
        }
        guard let service = serviceTry else {
            throw Abort(.badRequest, reason: "Could not construct service")
        }

        do {
            try service.save()
        } catch let error as Debuggable {
            throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
        }
        var serviceJSON = JSON()
        try serviceJSON.set("status", "ok")
        try serviceJSON.set("stage", "new")
        try serviceJSON.set("service", service)
        return serviceJSON
    }

    fileprivate func getService(from req: Request) throws -> Service {
        guard let json = req.json else { throw Abort(.badRequest, reason: "Missing JSON") }
        let serviceID: String = try json.get(Service.DB.id.ⓡ)
        guard let service = try Service.makeQuery()
            .filter(Service.DB.id.ⓡ, serviceID)
            .first()
            else {
                throw Abort(.badRequest, reason: "Service: \(serviceID) does not exist")
        }
        return service
    }

        // PATCH one
    fileprivate func patch(_ req: Request) throws -> JSON {
        // See `extension Vending: Updateable`
        let service = try getService(from: req)
        try service.update(for: req)
        try service.save()

        var serviceJSON = JSON()
        try serviceJSON.set("status", "ok")
        try serviceJSON.set("stage", "update")
        try serviceJSON.set("service", service)
        return serviceJSON
    }

   // DELETE one
    fileprivate func delete(_ req: Request) throws -> JSON {
        let service = try getService(from: req)
        try service.delete()
        var okJSON = JSON()
        try okJSON.set("status", "ok")
        return okJSON
    }
}

