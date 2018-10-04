//
//  UserController.swift
//
//  Created by Steven O'Toole on 8/30/17.
//

import Vapor

final class UserController: Controlling, ResourceRepresentable {
    fileprivate let log: LogProtocol

    init(log: LogProtocol) throws {
        self.log = log
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
