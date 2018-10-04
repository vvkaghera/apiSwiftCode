//
//  User.swift
//  Created by Steven O'Toole on 8/28/17.
//
// https://docs.vapor.codes/2.0/

import Vapor
import FluentProvider
import AuthProvider
import PostgreSQL
import PostgreSQLDriver

final class User: Model, Timestampable {
    // https://docs.vapor.codes/2.0/fluent/model/
    static let idType: IdentifierType = .uuid
    static let idKey = DB.id.ⓡ
    static var foreignIdKey = DB.id.ⓡ
    static let defaultID = "f098ca44-2894-49ab-af92-6f1dccec629a"
    let storage = Storage()
    var firstName: String?
    var lastName: String?
    var email: String?
    var countryCode: String?
    var phone: String?
    var facebookID: String?
    var passcode: String?
    var passcodeExpire: Date?
    var cityState: String?
    var postalcode: String?
    var deviceID: String?

    var isDebugUser: Bool {
        guard let phone = phone else { return false }
        return String(phone.prefix(3)) == "555"
    }

    public enum DB: String {
        case id = "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case countryCode = "country_code"
        case phone
        case facebookID = "facebook_id"
        case passcode
        case vendings
        case passcodeExpire = "passcode_expire"
        case cityState = "city_state"
        case postalcode
        case deviceID = "device_id"
    }

    init(id: String? = nil, firstName: String?, lastName: String?, email: String?, countryCode: String?,
         phone: String?, facebookID: String? = nil, passcode: String? = nil, passcodeExpire: Date? = nil,
         postalcode: String?, cityState: String?, deviceID: String?) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.countryCode = countryCode
        self.phone = phone
        self.facebookID = facebookID
        self.passcode = passcode
        self.passcodeExpire = passcodeExpire
        self.postalcode = postalcode
        self.cityState = cityState
        self.deviceID = deviceID
        if let id = id { self.id = Identifier(id) }
    }

    init(row: Row) throws {
        firstName = try row.get(DB.firstName.ⓡ)
        lastName = try row.get(DB.lastName.ⓡ)
        email = try row.get(DB.email.ⓡ)
        countryCode = try row.get(DB.countryCode.ⓡ)
        phone = try row.get(DB.phone.ⓡ)
        facebookID = try row.get(DB.facebookID.ⓡ)
        passcode = try row.get(DB.passcode.ⓡ)
        passcodeExpire = try row.get(DB.passcodeExpire.ⓡ)
        postalcode = try row.get(DB.postalcode.ⓡ)
        cityState = try row.get(DB.cityState.ⓡ)
        deviceID = try row.get(DB.deviceID.ⓡ)
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set(DB.firstName.ⓡ, firstName)
        try row.set(DB.lastName.ⓡ, lastName)
        try row.set(DB.email.ⓡ, email)
        try row.set(DB.countryCode.ⓡ, countryCode)
        try row.set(DB.phone.ⓡ, phone)
        try row.set(DB.facebookID.ⓡ, facebookID)
        try row.set(DB.passcode.ⓡ, passcode)
        try row.set(DB.passcodeExpire.ⓡ, passcodeExpire)
        try row.set(DB.postalcode.ⓡ, postalcode)
        try row.set(DB.cityState.ⓡ, cityState)
        try row.set(DB.deviceID.ⓡ, deviceID)
        return row
    }
}

extension User {
    var vendings: Children<User, Vending> {
        return children()
    }
}

// https://github.com/brokenhandsio/SteamPress/blob/master/Sources/SteamPress/Models/Preparations.swift#L54
extension User: Preparation {
    static func prepare(_ database: Fluent.Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(DB.firstName.ⓡ, optional: true)
            builder.string(DB.lastName.ⓡ, optional: true)
            builder.string(DB.email.ⓡ, optional: true)
            builder.string(DB.countryCode.ⓡ, optional: true)
            builder.string(DB.phone.ⓡ, unique: true)
            builder.string(DB.passcode.ⓡ, optional: true)
            builder.date(DB.passcodeExpire.ⓡ, optional: true)
            builder.string(DB.cityState.ⓡ, optional: true)
            builder.string(DB.postalcode.ⓡ, optional: true)
            builder.string(DB.deviceID.ⓡ, optional: true)
        }
        // "there’s no need to manually create indexes on unique columns; doing so
        // would just duplicate the automatically-created index."
        // https://www.postgresql.org/docs/9.4/static/ddl-constraints.html

        var r = try database.driver.raw("SELECT version(), now()")
        report(r)
        try database.driver.raw("alter table users alter column \(DB.id.ⓡ) set default uuid_generate_v4();")
        try database.driver.raw("alter table users alter column created_at set default now();")
        try database.driver.raw("alter table users alter column updated_at set default now();")

        let s = "insert into users (\(DB.id.ⓡ), phone) values('\(User.defaultID)', '5557018329');"
        try database.driver.raw(s)
        r = try database.driver.raw("select * from users;")
        report(r)
    }


    // How to run additional preparations:
    // https://github.com/brokenhandsio/SteamPress/blob/master/Sources/SteamPress/Models/Preparations.swift#L54
    static func report(_ node: Node) {
        if let wrapper = node.wrapped.array, let inner = wrapper.first, let array = inner.pathIndexableObject {
            print("=======\n\(array)")
            for (k, v) in array {
                print("...\(k)->\(v)")
            }
            return
        }
        print(node.wrapped)
    }

    static func revert(_ database: Fluent.Database) throws {
        try database.delete(self)
    }
}


extension User: JSONConvertible {
    convenience init(json: JSON) throws {
        let id: String?
        let firstName: String?
        let lastName: String?
        let email: String?
        let countryCode: String?
        let phone: String?
        let facebookID: String?
        let cityState: String?
        let postalcode: String?
        let deviceID: String?
        do { id = try json.get(DB.id.ⓡ) } catch { id = UUID().uuidString }
        do { firstName = try json.get(DB.firstName.ⓡ) } catch { firstName = nil }
        do { lastName = try json.get(DB.lastName.ⓡ) } catch { lastName = nil }
        do { email = try json.get(DB.email.ⓡ) } catch { email = nil }
        do { countryCode = try json.get(DB.countryCode.ⓡ) } catch { countryCode = nil }
        do { phone = try json.get(DB.phone.ⓡ) } catch { phone = nil }
        do { facebookID = try json.get(DB.facebookID.ⓡ) } catch { facebookID = nil }
        do { cityState = try json.get(DB.cityState.ⓡ) } catch { cityState = nil }
        do { postalcode = try json.get(DB.postalcode.ⓡ) } catch { postalcode = nil }
        do { deviceID = try json.get(DB.deviceID.ⓡ) } catch { deviceID = nil }

        self.init(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            countryCode: countryCode,
            phone: phone,
            facebookID: facebookID,
            postalcode: postalcode,
            cityState: cityState,
            deviceID: deviceID
        )
    }

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(User.idKey, id)
        try json.set(DB.firstName.ⓡ, firstName)
        try json.set(DB.lastName.ⓡ, lastName)
//        try json.set(DB.email.ⓡ, email)
//        try json.set(DB.countryCode.ⓡ, countryCode)
//        try json.set(DB.phone.ⓡ, phone)
//        try json.set(DB.facebookID.ⓡ, facebookID)
        try json.set(DB.cityState.ⓡ, cityState)
        try json.set(DB.postalcode.ⓡ, postalcode)
        try json.set(DB.deviceID.ⓡ, deviceID)
        try json.set(DB.vendings.ⓡ, vendings.all())
        return json
    }
}

// User can be returned directly in route closures
extension User: ResponseRepresentable { }

// User can handle PATCH
extension User: Updateable {
    // Updateable keys are called when `post.update(for: req)` is called.
    // Add as many updateable keys as you like here.
    public static var updateableKeys: [UpdateableKey<User>] {
        return [
            // If the request contains a String at key "content" the setter callback will be called.
            UpdateableKey(DB.firstName.ⓡ, String.self) { user, content in user.firstName = content },
            UpdateableKey(DB.lastName.ⓡ, String.self) { user, content in user.lastName = content },
            UpdateableKey(DB.email.ⓡ, String.self) { user, content in user.email = content },
            UpdateableKey(DB.countryCode.ⓡ, String.self) { user, content in user.countryCode = content },
            UpdateableKey(DB.cityState.ⓡ, String.self) { user, content in user.cityState = content },
            UpdateableKey(DB.deviceID.ⓡ, String.self) { user, content in user.deviceID = content },
            UpdateableKey(DB.postalcode.ⓡ, String.self) { user, content in user.postalcode = content }
      ]
    }
}

// MARK: Request
extension Request {
    /// Convenience on request for accessing this user type.
    /// Simply call `let user = try req.user()`.
    func user() throws -> User {
        return try auth.assertAuthenticated()
    }
}

// MARK: Token

// This allows the User to be authenticated with an access token.
extension User: TokenAuthenticatable {
    typealias TokenType = Token
}

