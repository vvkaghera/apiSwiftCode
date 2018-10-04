//
//  SendBirdManager.swift
//  Created by Steven O'Toole on 9/28/17.
//

import Foundation
import HTTP

struct SendBirdManager {
    static let shared = SendBirdManager()
    fileprivate let urlPrefix = "https://api.sendbird.com/v3/"
    fileprivate let appToken: String // = "582dd7133f22f3f548566b666295ac9b72c1b069"

    fileprivate init?() {
        guard let
            appToken = ProcessInfo.processInfo.environment["SENDBIRD_TOKEN"]
        else { TwilioManager.log?.error("SB FAIL: Missing SBTOKEN"); return nil }
        self.appToken = appToken
    }
    static var log: LogProtocol?

    fileprivate func standardHeaders() -> [HeaderKey: String] {
        return [
            "Content-Type": "application/json, charset=utf8",
            "Api-Token": appToken
        ]
    }
}

// MARK: - Messages
// https://docs.sendbird.com/platform#messages
extension SendBirdManager {
    func createMessage(client: ClientFactoryProtocol, request: Request) throws -> JSON {
        guard let json = request.json else { throw Abort(.badRequest, reason: "Missing JSON") }
        let message: String = try json.get("message")
        let userID: String = try json.get("user_id")
        let channelURL: String = try json.get("channel_url")
        let channelType = "group_channels"
        let urlString = "\(urlPrefix)\(channelType)/\(channelURL)/messages"
        let req = Request(method: .post, uri: urlString, headers: standardHeaders())
        let bodyArray: [String: Any] = [
            "message_type": "MESG",
            "user_id": userID,
            "message": message
         ]
        req.body = try Body(JSON(node: bodyArray))

        let response = try client.respond(to: req)
        TwilioManager.log?.error("response=\(response.status)\n \(response)")
        return try Utility.jsonFromBody(response: response)
    }

    // This action is a premium feature. Contact sales@sendbird.com if you wish to implement this feature.
    // 400920: Not accessible. This API is not allowed for the user.
    func messageList(client: ClientFactoryProtocol, request: Request) throws -> JSON {
        let channelType = "group_channels"
        let channelURL = "sendbird_group_channel_48996141_8273b201a43866cfc6a6f111885709cae7b7eadf"
        let timeAnchor = Date().timeIntervalSince1970 * 1000
        let prevLimit = 200
        let query = "?message_ts=\(timeAnchor)&prev_limit=\(prevLimit)"
        let urlString = "\(urlPrefix)\(channelType)/\(channelURL)/messages\(query)"
        let req = Request(method: .get, uri: urlString, headers: standardHeaders())

        let response = try client.respond(to: req)
        TwilioManager.log?.error("response=\(response.status)\n \(response)")
        return try Utility.jsonFromBody(response: response)
    }

}

// MARK: - Channels
extension SendBirdManager {
    // just returns the first page
    func groupChannelList(client: ClientFactoryProtocol) throws -> JSON {
        let urlString = "\(urlPrefix)group_channels"
        let req = Request(method: .get, uri: urlString, headers: standardHeaders())
        let response = try client.respond(to: req)
//        TwilioManager.log?.error("===========================")
//        TwilioManager.log?.error("response=\(response.status)\n \(response)")
        return try Utility.jsonFromBody(response: response)
    }

    func createChannelTest(client: ClientFactoryProtocol) throws -> JSON {
        let urlString = "\(urlPrefix)group_channels"
        let req = Request(method: .post, uri: urlString, headers: standardHeaders())
        let users = ["panda", "downtown"]
        let bodyArray: [String: Any] = [
            "name": "Downtown Panda Chat",
            "user_ids": users,
            "is_distinct": true
         ]
        req.body = try Body(JSON(node: bodyArray))
        let response = try client.respond(to: req)
        return try Utility.jsonFromBody(response: response)
    }
}


// MARK: - Users
extension SendBirdManager {

    // just returns the first page
    func userList(client: ClientFactoryProtocol) throws -> JSON {
        let urlString = "\(urlPrefix)users"
        let req = Request(method: .get, uri: urlString, headers: standardHeaders())
        let response = try client.respond(to: req)
//        TwilioManager.log?.error("===========================")
//        TwilioManager.log?.error("response=\(response.status)\n \(response)")
        return try Utility.jsonFromBody(response: response)
    }

    func deleteUser(client: ClientFactoryProtocol, id: String) throws -> JSON {
        let urlString = "\(urlPrefix)users/\(id)"
        let req = Request(method: .delete, uri: urlString, headers: standardHeaders())
        let response = try client.respond(to: req)
        if response.status.statusCode == 200 {
            return try Utility.jsonFromBody(response: response)
        } else {
            return try Utility.statusAsJSON(status: response.status)
        }
    }

    func updateUser(client: ClientFactoryProtocol, request: Request) throws -> JSON {
        let (userID, nickname) = try chatParamsFrom(request: request)
        let urlString = "\(urlPrefix)users/\(userID)"
        let req = Request(method: .put, uri: urlString, headers: standardHeaders())
        let bodyArray = [ "issue_access_token": true ]
        req.body = try Body(JSON(node: bodyArray))

        let response = try client.respond(to: req)
        TwilioManager.log?.error("response=\(response.status)\n \(response)")

        switch response.status.statusCode {
        case 200: return try Utility.jsonFromBody(response: response)
        case 400: return try createUser(client: client, userID: userID, nickname: nickname)
        default: return try Utility.statusAsJSON(status: response.status)
        }
    }

    private func chatParamsFrom(request: Request) throws -> (String, String) {
        guard let json = request.json else { throw Abort(.badRequest, reason: "Missing JSON") }
        let userID: String = try json.get(User.DB.id.ⓡ)
        let nickname: String
        do {
            nickname = try json.get("nickname")
        } catch { nickname = userID}
        return (userID, nickname)
    }

    func createUser(client: ClientFactoryProtocol, request: Request) throws -> JSON {
        let (userID, nickname) = try chatParamsFrom(request: request)
        return try createUser(client: client, userID: userID, nickname: nickname)
    }

    func createUser(client: ClientFactoryProtocol, userID: String, nickname: String) throws -> JSON {
        let urlString = "\(urlPrefix)users"

        let req = Request(method: .post, uri: urlString, headers: standardHeaders())
        let bodyArray: [String: Any] = [
            "user_id": userID,
            "nickname": nickname,
            "profile_url": "",
            "issue_access_token": true
        ]
        req.body = try Body(JSON(node: bodyArray))
        let response = try client.respond(to: req)
        if response.status.statusCode == 200 {
            return try Utility.jsonFromBody(response: response)
        } else {
            return try Utility.statusAsJSON(status: response.status)
        }
    }
}

// MARK: - Debug
extension SendBirdManager {
    fileprivate func logRequest(_ req: URLRequest) {
        SendBirdManager.log?.error("===========================")
        SendBirdManager.log?.error("\(req.httpMethod ?? "") \(req)")

        let bodyString: String
        if let data = req.httpBody {
            bodyString = String(data: data, encoding: .utf8) ?? ""
        } else {
            bodyString = ""
        }
        SendBirdManager.log?.error("BODY \n \(bodyString)")
        SendBirdManager.log?.error("HEADERS \n \(String(describing: req.allHTTPHeaderFields))")
    }
}
