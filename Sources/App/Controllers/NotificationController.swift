//
//  NotificationController.swift
//  App
//
//  Created by MAC001 on 24/06/19.
//

import Foundation
import VaporAPNS
import FluentProvider
import Fluent

final class NotificationController: Controlling {
    
    fileprivate let log: LogProtocol
    
    init(log: LogProtocol) throws {
        self.log = log
    }
    
    func addSpecificRoutes(router: Router) {
        router.post("notifications/list") { req in
            guard let json = req.json else { throw Abort(.badRequest, reason: "Missing JSON") }
            var userJSON = JSON()
            let vendorId: String = try json.get(Notification.DB.to.ⓡ)
            guard let notifications = try Notification.makeQuery()
//                .filter(Notification.DB.to.ⓡ, vendorId)
                .filter(Notification.DB.id.ⓡ, "659621B5-37C2-43B5-AF70-DCD0E5065935")
                .first()
                else {
                    throw Abort(.badRequest, reason: "Notification: \(vendorId) does not exist")
            }
            try userJSON.set("status", "ok")
            try userJSON.set("notification", notifications)
            return userJSON
        }
    }
}
