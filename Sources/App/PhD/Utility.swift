//
//  Utility.swift
//
//  Created by Steven O'Toole on 8/28/17.
//
//

import Foundation
import PostgreSQLProvider  // debug
import HTTP

struct Utility {

    static func info(droplet: Droplet) throws -> String {
        if droplet.config.environment != .development { return "" }

        let configEnv = "configEnv: \(droplet.config.environment)"
        let configArgs = "configArgs: \(droplet.config.arguments)"
        let workDir = "workDir: \(droplet.config.workDir)\n\(Date())"

        let gooberVar = "GOOBER: \(ProcessInfo.processInfo.environment["GOOBER"] ?? "")"
        let dbURL = "dbURL: \(ProcessInfo.processInfo.environment["DATABASE_URL"] ?? "")"
        let fooEnv = "fooEnv: \(ProcessInfo.processInfo.environment["foo"] ?? "")"

        let hostName = "hostName: \(ProcessInfo.processInfo.hostName)"
        let opSysVersion = "opSysVersion: \(ProcessInfo.processInfo.operatingSystemVersionString)"
        let processName = "process: \(ProcessInfo.processInfo.processName) [\(ProcessInfo.processInfo.processIdentifier)]"
        let arguments = "arguments: \(ProcessInfo.processInfo.arguments)"
        let environment = "environment: \(ProcessInfo.processInfo.environment)"

        let postgresqlDriver = try droplet.postgresql()
        let dbVersion = try postgresqlDriver.raw("SELECT version()")

        return "\(configEnv)\n\(configArgs)\n\(workDir)\n\n\(gooberVar)\n\(dbURL)\n\(fooEnv)" +
            "\n\(hostName)\n\(opSysVersion)\n\(processName)" +
            "\ndatabase: \(dbVersion)" +
            "\n\n\(arguments)\n\n\(environment)"
    }


    // bytes is an array of UInt8 (Bits/Aliases.swift)
    // I could use makeString() on bytes from Bits/ByteSequence+Conversions.swift
    static func stringFromBody(response: Response) throws -> String {
        return try String(bytes: response.body.bytes?.makeString() ?? "")
    }

    static func jsonFromBody(response: Response) throws -> JSON {
        guard let bytes = response.body.bytes else { return try Utility.noBody() }
        let json = try JSON(bytes: bytes)
        return json
    }

    static func noBody() throws -> JSON {
        var json = JSON()
        try json.set("status", "no body")
        return json
    }

    static func statusAsJSON(status: Status) throws -> JSON {
        var json = JSON()
        try json.set("status", "\(status.statusCode)")
        return json
    }
}

protocol Controlling {}

extension RawRepresentable where RawValue == String {
    var ⓡ: String { return self.rawValue }
}

extension RawRepresentable where RawValue == Int {
    var ⓡ: Int { return self.rawValue }
}
