//
//  UserController.swift
//
//  Created by Steven O'Toole on 8/30/17.
//

import Vapor
import Fluent
import Stripe

final class UserController: Controlling, ResourceRepresentable {
    fileprivate let log: LogProtocol

    init(log: LogProtocol) throws {
        self.log = log
    }

    
    func addRoutes(drop: Droplet) {
        let userGroup = drop.grouped("users", "favorites")
        print("create favorite hit")
        userGroup.post("create", handler: createFavorite)
        userGroup.post("delete", handler: deleteFavorite)

        /*
        categoryGroup.post("create", String.parameter) { req in
            print("============\n\(req)")
            let lookupid = try req.parameters.next(String.self)
            guard let user = try User.makeQuery()
                .filter(User.DB.id.ⓡ, lookupid)
                .first()
                else {
                    throw Abort(.badRequest, reason: "User: \(lookupid) does not exist")
            }
            return user
        }
        */
    }

    
    func createFavorite(request: Request) throws -> ResponseRepresentable {
    //func createCategory(String.parameter) throws -> ResponseRepresentable {
        print("create category hit")
        print("request is", request)
        let user_id = request.data["user_id"]?.string
        let vending_id = request.data["vending_id"]?.string
        //let lookupid = try req.parameters.next(String.self)
        guard let user = try User.makeQuery()
            .filter(User.DB.id.ⓡ, user_id)
            .first()
            else {
                throw Abort(.badRequest, reason: "User: \(String(describing: user_id)) does not exist")
        }
        
        guard let vendor = try Vending.makeQuery()
            .filter(Vending.DB.id.ⓡ, vending_id)
            .first()
            else {
                throw Abort(.badRequest, reason: "Vendor: \(String(describing: vending_id)) does not exist")
        }        
        
        let pivot = try Pivot<User, Vending>(user, vendor)
        try pivot.save()
        //return try user.makeJSON()
        
        var okJSON = JSON()
        try okJSON.set("status", "ok")
        try okJSON.set("user_id", user_id)
        try okJSON.set("vending_id", vending_id)
        
        return okJSON
        //return try Response(status: .ok, json: json)
    }

    func deleteFavorite(request: Request) throws -> ResponseRepresentable {
        //func createCategory(String.parameter) throws -> ResponseRepresentable {
        print("delete category hit")
        print("request is", request)
        let user_id = request.data["user_id"]?.string
        let vending_id = request.data["vending_id"]?.string
        //let lookupid = try req.parameters.next(String.self)
        guard let user = try User.makeQuery()
            .filter(User.DB.id.ⓡ, user_id)
            .first()
            else {
                throw Abort(.badRequest, reason: "User: \(String(describing: user_id)) does not exist")
        }
        
        guard let vendor = try Vending.makeQuery()
            .filter(Vending.DB.id.ⓡ, vending_id)
            .first()
            else {
                throw Abort(.badRequest, reason: "Vendor: \(String(describing: vending_id)) does not exist")
        }
        
        //try Pivot<User, Vending>.query().fiter("user_id", user_id).filter("vending_id", vending_id).delete()
        //try Pivot<User, Vending>.makeQuery().filters
        guard let pivot = try Pivot<User, Vending>.makeQuery()
            .filter(User.PivotDB.pivotUserId.ⓡ, user_id)
            .filter(User.PivotDB.pivotVendorId.ⓡ, vending_id)
            .first()
            else {
                throw Abort(.badRequest, reason: "User Id: \(String(describing: user_id)) does not exist")
            }
        try pivot.delete()
        var okJSON = JSON()
        try okJSON.set("status", "ok")
        try okJSON.set("user_id", user_id)
        try okJSON.set("vending_id", vending_id)
        
        return okJSON
        //return try Response(status: .ok, json: json)
    }
    
    /*
    private func teaches(request: Request) throws -> ResponseRepresentable {
        let teacher = try request.parameters.next(Teacher.self)
        let lesson = try request.parameters.next(Lesson.self)
        let pivot = try Pivot<Teacher, Lesson>(teacher, lesson)
        try pivot.save()
        return teacher
    }

    func addRoutes(drop: Droplet) {
        group.post("users/favorites", String.parameter) { req in
            print("============\n\(req)")
            let lookupid = try req.parameters.next(String.self)
            return nil
    }
*/
    
    func addCardRoutes(drop: Droplet){
        let userGroup = drop.grouped("users", "card")
        userGroup.post("addCard", handler: addCard)
    }
    
    func addCard(request : Request) throws -> ResponseRepresentable {
        print("Here I'm for adding a new card")
        print("request is", request)
        let user_id = request.data["user_id"]?.string
        let stripeCustomerId = request.data["stripeCustomer_id"]?.string
        let aStripeToken = request.data["stripe_token"]?.string
        
        let stripeClient = try StripeClient(apiKey: Constants.publishableKey)
        stripeClient.initializeRoutes()
        
        try! stripeClient.customer.addNewSource(forCustomer: stripeCustomerId!, source: aStripeToken!)
        
        var okJSON = JSON()
        try okJSON.set("status", "ok")
        try okJSON.set("message", "Your Card was added successful!")
        
        return okJSON
    }
    
    
    
    func addGroupedRoutes(group: RouteBuilder) {
        
        
        group.get("users/lookup", String.parameter) { req in
            let lookupid = try req.parameters.next(String.self)
            guard let user = try User.makeQuery()
                .filter(User.DB.id.ⓡ, lookupid)
                .first()
                else {
                    throw Abort(.badRequest, reason: "User: \(lookupid) does not exist")
            }
            return user
        }
    }

    // GET All
    func getAll(_ req: Request) throws -> ResponseRepresentable {
        return try User.all().makeJSON()
    }

    // GET One
//    func getOne(_ req: Request, user: User) throws -> ResponseRepresentable {
//        return user
//    }

    // PATCH one
    func patch(_ req: Request, user: User) throws -> ResponseRepresentable {
        // See `extension User: Updateable`
        try user.update(for: req)
        try user.save()
        return user
    }

    // DELETE one
    func delete(_ req: Request, user: User) throws -> ResponseRepresentable {
        try user.delete()
        return Response(status: .ok)
    }

    func makeResource() -> Resource<User> {
        return Resource(
            index: getAll,
            //store: post,
            //show: getOne,
            update: patch,
//            replace: replace,
            destroy: delete
//            clear: clear
        )
    }
    
    
}

//extension UserController: EmptyInitializable { }
