//
//  Job.swift
//  App
//
//  Created by MAC001 on 22/04/19.
//

import Foundation
import VaporAPNS
import FluentProvider
import Fluent

final class JobController: Controlling {
    fileprivate let log: LogProtocol
    
    
    init(log: LogProtocol) throws {
        self.log = log
    }
    
    func addOpenRoutes(drop: Droplet) {
        drop.get("job") { req in return try self.get(req) }
    }
    
    
    func addGroupedRoutes(group: RouteBuilder) {
        group.post("job") { req in return try self.post(req) }
        group.patch("job") { req in return try self.patch(req) }
        group.delete("job") { req in return try self.delete(req) }
        
        group.get("job/lookup", String.parameter) { req in
            print("============\n\(req)")
            let lookupid = try req.parameters.next(String.self)
            guard let aJob = try Job.makeQuery()
                .filter(Job.DB.id.ⓡ, lookupid)
                .first()
                else {
                    throw Abort(.badRequest, reason: "Job: \(lookupid) does not exist")
            }
            return aJob
        }
    }
    fileprivate func get(_ req: Request) throws -> JSON {
        
        let jobQuery = try Job.makeQuery()
        
        var json = JSON()
        try json.set("status", "ok")
        
        try json.set("jobs", jobQuery.all())
        return json
    }
   
    fileprivate func post(_ req: Request) throws -> JSON {
        //log.error("• in vendings.post()\n\(req)")
        guard let json = req.json else { throw Abort(.badRequest, reason: "No JSON in job post") }
        
        var jobTry: Job?
        do {
            jobTry = try Job(json: json)
        } catch let error as Debuggable {
            jobTry = nil
            throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
        }
        guard let job = jobTry else {
            throw Abort(.badRequest, reason: "Could not construct job")
        }
        
        do {
            try job.save()
        } catch let error as Debuggable {
            throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
        }
        
        //Add notificatio entry to notification table
        var arrVendors = [Vending]()
        let dictServices : [String : Bool] = ["offers_food" : req.data["offers_food"]!.bool!,
                            "offers_entertainment": req.data["offers_entertainment"]!.bool!,
                            "offers_music" : req.data["offers_music"]!.bool!,
                            "offers_rentals" : req.data["offers_rentals"]!.bool!,
                            "offers_services" : req.data["offers_services"]!.bool!,
                            "offers_party_packs" : req.data["offers_party_packs"]!.bool!,
                            "offers_venue" : req.data["offers_venue"]!.bool!]
        
        let arrKeys = dictServices.keys
        
        for aKey in arrKeys{
            
            guard let vendors : [Vending] = try Vending.makeQuery()
                .filter(aKey, dictServices[aKey])
                .all()
                else {
                    throw Abort(.badRequest, reason: "No Vendor found :(")
            }
            
            arrVendors.append(contentsOf: vendors)
        }
        
        
        var unique = [Vending]()
        for aVendor in arrVendors {
            let aArrSeen = unique.filter({ $0.id == aVendor.id})
            if aArrSeen.count == 0{
                unique.append(aVendor)
            }
        }

        for aVendor in unique{
            let aNotification = try Notification(id: UUID().uuidString, jobId: job.id!, title: "Notification Test", descrption: job.additionalNotes, status: "1", fromUserId: job.userId, to: (aVendor.id?.string)!, type: "1")
            
            do {
                try aNotification.save()
            } catch let error as Debuggable {
                throw Abort(.badRequest, reason: error.reason, identifier: error.identifier)
            }
        }
        
        var jobJSON = JSON()
        try jobJSON.set("status", "ok")
        try jobJSON.set("job", job)
        
        try sendPushNotification(req, job)
        //----------------------

        return jobJSON
    }
    
    fileprivate func getJob(from req: Request) throws -> Job {
        guard let json = req.json else { throw Abort(.badRequest, reason: "Missing JSON") }
        let jobID: String = try json.get(Job.DB.id.ⓡ)
        guard let job = try Job.makeQuery()
            .filter(Job.DB.id.ⓡ, jobID)
            .first()
            else {
                throw Abort(.badRequest, reason: "Job: \(jobID) does not exist")
        }
        return job
    }
    
    // PATCH one
    fileprivate func patch(_ req: Request) throws -> JSON {
        // See `extension Event: Updateable`
        let job = try getJob(from: req)
        
        try job.save()
        
        var jobJSON = JSON()
        try jobJSON.set("status", "ok")
        try jobJSON.set("job", job)
        return jobJSON
    }
    
    // DELETE one
    fileprivate func delete(_ req: Request) throws -> JSON {
        let job = try getJob(from: req)
        try job.delete()
        var okJSON = JSON()
        try okJSON.set("status", "ok")
        return okJSON
    }
    
    
    fileprivate func sendPushNotification(_ req: Request, _ job: Job) throws{

        let folderPath = #file.components(separatedBy: "/").dropLast().joined(separator: "/")
        let filePath = "\(folderPath)/AuthKey_CNQ574ZKF6.p8"
        
        let options = try! Options(topic: Constants.AppBundleIdentifier, teamId: Constants.DeveloperAccount.TeamId, keyId: Constants.DeveloperAccount.APNS_Key_Id, keyPath: filePath)
        let vaporAPNS = try VaporAPNS(options: options)
        let payload = Payload(title: "Events near you!", body: "New event posted near you!")
        
        let pushMessage = ApplePushMessage(topic: nil, priority: .immediately, payload: payload, sandbox: true)

        guard let tokenQuery : [DeviceToken] = try DeviceToken.makeQuery()
            .join(kind: .inner, Vending.self, baseKey: "user_id", joinedKey: "user_id")
            .all()
            else {
                throw Abort(.badRequest, reason: "tokenQuery does not exist")
        }

        var array_tokens = [String]()
        for aData in tokenQuery {
            print("aTken >>>>> \(aData.dToken)")
            array_tokens.append(aData.dToken)

            
        }
        
        vaporAPNS.send(pushMessage, to: array_tokens) { result in
            print(result)
            if case let .success(messageId,deviceToken,serviceStatus) = result, case .success = serviceStatus {
                print ("Success!")
                print("messageId: \(messageId)  |||  deviceToken: \(deviceToken)  |||  serviceStatus:\(serviceStatus)")
                
                
                saveNotification(job, payload, deviceToken)
                
                
            }
        }
    }
    
    fileprivate func saveNotification(_ job: Job, _ payload: Payload, _ deviceToken: String )  {
        
        let objNtest = try? Ntest(id: UUID().uuidString, jobId: job.id!, title: payload.title!, descrption: payload.body!, status: "1", fromUserId: job.userId, to: deviceToken, type: "1")
        try? objNtest?.save()
        print(objNtest)
    }
    
}


//VaporAPNS
extension Job {
    
//
//
//    var options = try! Options(topic: Constants.AppBundleIdentifier, teamId: Constants.DeveloperAccount.TeamId, keyId: Constants.DeveloperAccount.APNS_Key_Id, keyPath: "../resources/AuthKey_CNQ574ZKF6.p8")
//    let vaporAPNS = try VaporAPNS(options: options)

    
    
//    let options = try! Options(topic: "<your bundle identifier>", certPath: "/path/to/your/certificate.crt.pem", keyPath: "/path/to/your/certificatekey.key.pem")
//    let vaporAPNS = try VaporAPNS(options: options)
    
}
