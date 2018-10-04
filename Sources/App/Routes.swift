import Foundation
import Vapor
import AuthProvider
import S3SignerAWS

extension Droplet {

    func setupRoutes() throws {
        // MARK: - Debug
        get("info") { req in
            let debugInfo = try Utility.info(droplet: self)
            return "\(req.description)\n\n\(debugInfo)"
        }
        chatRoutes()

        // MARK: - Auth flow
        let auth = try AuthController(router: self.router, log: self.log, client: self.client)
        auth.addSpecificRoutes(router: self.router)

        // MARK: - Protected Routes
        let tokenOnUsers = grouped([ TokenAuthenticationMiddleware(User.self) ])

        let users = try UserController(log: self.log)
        tokenOnUsers.resource("users", users)
        users.addGroupedRoutes(group: tokenOnUsers)
        let vendings = try VendingController(log: self.log)
        vendings.addOpenRoutes(drop: self)
        vendings.addGroupedRoutes(group: tokenOnUsers)
        let services = try ServiceController(log: self.log)
        services.addGroupedRoutes(group: tokenOnUsers)
        let images = try ImageController(log: log, client: client, s3Signer: s3Signer)
        images.addOpenRoutes(drop: self)
        images.addGroupedRoutes(group: tokenOnUsers)
        images.s3TestRoutes(drop: self)
    }

    // https://docs.sendbird.com/platform#user
    fileprivate func chatRoutes() {
        let noResult = "{\"status\": \"no result\"}"

        // if you try to post a user who already exists, you get a 400
        post("chat") { req in
            guard let result = try SendBirdManager.shared?.createUser(client: self.client, request: req)
            else { return noResult }
            return result
        }

        post("msgsend") { req in
            guard let result = try SendBirdManager.shared?.createMessage(client: self.client, request: req)
            else { return noResult }
            return result
        }

        get("msglist") { req in
            guard let result = try SendBirdManager.shared?.messageList(client: self.client, request: req)
            else { return noResult }
            return result
        }

        // Get an access token. If the user doesn't exist, call createUser
        put("chat") { req in
            guard let result = try SendBirdManager.shared?.updateUser(client: self.client, request: req)
            else { return noResult }
            return result
        }

        post("chat", "channel") { req in
            guard let result = try SendBirdManager.shared?.createChannelTest(client: self.client)
            else { return noResult }
            return result
        }

        get("chat", "list") { req in
            guard let result = try SendBirdManager.shared?.userList(client: self.client)
            else { return noResult }
            return result
        }

        delete("chat", String.parameter) { req in
            let userId = try req.parameters.next(String.self)
            guard let result = try SendBirdManager.shared?.deleteUser(client: self.client, id: userId)
            else { return noResult }
            return result
        }

        get("chat", "group") { req in
            guard let result = try SendBirdManager.shared?.groupChannelList(client: self.client)
            else { return noResult }
            return result
        }

    }
}

