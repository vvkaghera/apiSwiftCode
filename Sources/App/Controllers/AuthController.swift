//
//  AuthController.swift
//  Created by Steven O'Toole on 9/1/17.
//
import Foundation
import Vapor
import VaporAPNS
import Stripe

final class AuthController: Controlling {
    fileprivate let client: ClientFactoryProtocol
    fileprivate let log: LogProtocol

    init(router: Router, log: LogProtocol, client: ClientFactoryProtocol) throws {
        self.client = client
        self.log = log
    }

    func addSpecificRoutes(router: Router) {
        // Assume we are ignoring the country code for now
        router.post("auth/verify") { req in
            guard let json = req.json else { throw Abort(.badRequest, reason: "Missing JSON") }
            
            print("request: \(req)")
            
            let phone: String = try json.get(User.DB.phone.ⓡ)
            let passcode: String = try json.get("passcode")
            let devieToken: String = try json.get("deviceToken")
            let devieType: String = try json.get("deviceType")
            
            guard let user = try User.makeQuery()
                .filter(User.DB.phone.ⓡ, phone)
                .first()
            else {
                throw Abort(.badRequest, reason: "User Phone: \(phone) does not exist")
            }
            guard let expireDate = user.passcodeExpire, expireDate > Date(), passcode == user.passcode
            else {
                throw Abort(.badRequest, reason: "FAIL: User Validation")
            }
            
            //Create Stripe User from here
            if user.stripeCustomer_id == nil || user.stripeCustomer_id == ""{
                let stripeClient = try StripeClient(apiKey: Constants.publishableKey)
                stripeClient.initializeRoutes()
                
                let createCustomer = try stripeClient.customer.create(email: user.phone)
                let customer = try createCustomer.serializedResponse()
                print(customer)
                user.stripeCustomer_id = customer.id
                try! user.save()
            }

            let token = try Token.generate(for: user, aDeviceToken: devieToken)
            try token.save()
            
            let objDeviceToken = try DeviceToken.generate(for: user, aDeviceToken: devieToken, aDeviceType: devieType)
            try objDeviceToken.save()

            var userJSON = JSON()
            try userJSON.set("user", user)
            try userJSON.set("token", token.token)
            return userJSON
        }

        // Posts to auth, will get sent an SMS.  If the phone number doesn't exist 
        // in the DB, a user record will be created.
        router.post("auth") { req in
            guard let json = req.json else { throw Abort(.badRequest, reason: "Missing JSON") }
            let phone: String = try json.get(User.DB.phone.ⓡ)
            if phone.count < 10 { throw Abort(.badRequest, reason: "Not a valid Phone Number") }
            if let user = try self.userFor(phone: phone) { return try self.smsSendFor(user: user) }
            
            
            return try self.postUser(req: req)
        }

        router.post("fbauth") { req in
            guard let json = req.json else { throw Abort(.badRequest, reason: "Missing JSON") }
            let facebookID: String = try json.get(User.DB.facebookID.ⓡ)
            let devieToken: String = try json.get("deviceToken")
            // I don't know what a valid length should be
            if facebookID.count < 4 { throw Abort(.badRequest, reason: "Not a valid FacebookID") }
            var user: User?
            user = try self.userFor(facebookID: facebookID)
            if user == nil {
                do { user = try User(json: json) }
                catch { throw Abort(.badRequest, reason: "Incorrect JSON") }
                try user?.save()
            }
            guard let validUser = user else {
                throw Abort(.badRequest, reason: "Unable to find or create User")
            }
            let token = try Token.generate(for: validUser, aDeviceToken: devieToken)
            try token.save()
            var userJSON = JSON()
            try userJSON.set("user", validUser)
            try userJSON.set("token", token.token)
            print("user json is ", userJSON)
            return userJSON
        }
    }
}

// MARK: - Utility
extension AuthController {
    fileprivate func userFor(phone: String) throws -> User? {
        guard let user = try User.makeQuery()
        .filter(User.DB.phone.ⓡ, phone)
        .first() else {
            return nil
        }
        return user
    }

    fileprivate func userFor(facebookID: String) throws -> User? {
        guard let user = try User.makeQuery()
        .filter(User.DB.facebookID.ⓡ, facebookID)
        .first() else {
            return nil
        }
        return user
    }

    fileprivate func smsSendFor(user: User) throws -> JSON {
        guard let phone = user.phone else { throw Abort(.badRequest, reason: "Cannot send SMS with nil phone") }
        let passcode = !user.isDebugUser ? generatePasscode() : "5555"
        user.passcode = passcode
        user.passcodeExpire = getExpires()
        try user.save()
        let message =  "Your YurParty passcode is \(passcode)"
        if !user.isDebugUser {
            try TwilioManager.shared?.sendSMSFromClient(client, toPhone: phone, message: message)
        }
        // we only get here if the phone begins with "555"
        var okJSON = JSON()
        try okJSON.set("status", "ok")
        try okJSON.set("passcode", passcode)
        return okJSON
    }

    fileprivate func postUser(req: Request) throws -> JSON {
        guard let json = req.json else { throw Abort(.badRequest, reason: "Missing JSON") }
        let user: User
        do { user = try User(json: json) }
        catch { throw Abort(.badRequest, reason: "Incorrect JSON") }
        
        //Create Stripe User from here
        let stripeClient = try StripeClient(apiKey: Constants.publishableKey)
        stripeClient.initializeRoutes()
        
        let createCustomer = try stripeClient.customer.create(email: user.phone)
        let customer = try createCustomer.serializedResponse()
        print(customer)
        user.stripeCustomer_id = customer.id

        
        return try smsSendFor(user: user)
    }

    fileprivate func generatePasscode() -> String {
        let passCodeInts = Array("1234567890")
        var passcode = ""
        for _ in 0..<4 {
            let rand = Int.random(min: 0, max: 9)
            passcode.append(passCodeInts[Int(rand)])
        }
        return passcode
    }
    
    fileprivate func getExpires(from date: Date = Date()) -> Date {
        var dc = Calendar.current.dateComponents([.minute, .hour, .day, .month, .year], from: date)
        guard let minute = dc.minute else { fatalError() }
        dc.minute = minute + 5
        guard let expirationDay = Calendar.current.date(from: dc) else { fatalError() }
        return expirationDay
    }
}
