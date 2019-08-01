//
//  Vending.swift
//  Created by Steven O'Toole on 8/29/17.
//

import Vapor
import AuthProvider
import FluentProvider

final class Vending: Model, Timestampable {
    static let idType: IdentifierType = .uuid
    static let idKey = DB.id.ⓡ
    static var foreignIdKey = DB.id.ⓡ
    let storage = Storage()
    var log: LogProtocol?

    var companyName: String
    var uniqueUserName: String
    var zipCode: String
    var description: String?
    var priceRange: Int
    var offersFood = false
    var offersEntertainment = false
    var offersMusic = false
    var offersRentals = false
    var offersServices = false
    var offersPartyPacks = false
    var offersVenue = false
    var userId: Identifier
    var email: String?
    var facebookURL: String?
    var instaURL: String?

    public enum DB: String {
        case id = "vending_id"
        case companyName = "company_name"
        case uniqueUserName = "unique_user_name"
        case zipCode = "zip_code"
        case description
        case priceRange = "price_range"
        case offersFood = "offers_food"
        case offersEntertainment = "offers_entertainment"
        case offersMusic = "offers_music"
        case offersRentals = "offers_rentals"
        case offersServices = "offers_services"
        case offersPartyPacks = "offers_party_packs"
        case offersVenue = "offers_venue"
        case userIdKey = "user_id"
        case email = "email"
        case facebookURL = "facebook_url"
        case instaURL = "insta_url"
        case services
    }

    init(id: String? = nil, companyName: String, uniqueUserName: String, zipCode: String,
    description: String?, priceRange: Int?,
    offersFood: Bool?, offersEntertainment: Bool?, offersMusic: Bool?,
    offersRentals: Bool?, offersServices: Bool?, offersPartyPacks: Bool?, offersVenue: Bool?, email: String? = nil, facebookURL: String? = nil, instaURL: String? = nil,
    user: User) throws {
        self.companyName = companyName
        self.uniqueUserName = uniqueUserName
        self.zipCode = zipCode
        self.description = description
        self.priceRange = priceRange ?? 1
        self.offersFood = offersFood ?? false
        self.offersEntertainment = offersEntertainment ?? false
        self.offersMusic = offersMusic ?? false
        self.offersRentals = offersRentals ?? false
        self.offersServices = offersServices ?? false
        self.offersVenue = offersVenue ?? false
        self.email = email
        self.facebookURL = facebookURL
        self.instaURL = instaURL
        
        guard let userId = user.id else { throw Abort(.badRequest, reason: "User id not found in vending init") }
        self.userId = userId
        if let id = id { self.id = Identifier(id) }
    }

    init(row: Row) throws {
        companyName = try row.get(DB.companyName.ⓡ)
        uniqueUserName = try row.get(DB.uniqueUserName.ⓡ)
        zipCode = try row.get(DB.zipCode.ⓡ)
        description = try row.get(DB.description.ⓡ)
        priceRange = try row.get(DB.priceRange.ⓡ)
        offersFood = try row.get(DB.offersFood.ⓡ)
        offersEntertainment = try row.get(DB.offersEntertainment.ⓡ)
        offersMusic = try row.get(DB.offersMusic.ⓡ)
        offersRentals = try row.get(DB.offersRentals.ⓡ)
        offersServices = try row.get(DB.offersServices.ⓡ)
        offersPartyPacks = try row.get(DB.offersPartyPacks.ⓡ)
        offersVenue = try row.get(DB.offersVenue.ⓡ)
        email = try row.get(DB.email.ⓡ)
        facebookURL = try row.get(DB.facebookURL.ⓡ)
        instaURL = try row.get(DB.instaURL.ⓡ)
        userId = try row.get(DB.userIdKey.ⓡ)
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set(DB.companyName.ⓡ, companyName)
        try row.set(DB.uniqueUserName.ⓡ, uniqueUserName)
        try row.set(DB.zipCode.ⓡ, zipCode)
        try row.set(DB.description.ⓡ, description)
        try row.set(DB.priceRange.ⓡ, priceRange)
        try row.set(DB.offersFood.ⓡ, offersFood)
        try row.set(DB.offersEntertainment.ⓡ, offersEntertainment)
        try row.set(DB.offersMusic.ⓡ, offersMusic)
        try row.set(DB.offersRentals.ⓡ, offersRentals)
        try row.set(DB.offersServices.ⓡ, offersServices)
        try row.set(DB.offersPartyPacks.ⓡ, offersPartyPacks)
        try row.set(DB.offersVenue.ⓡ, offersVenue)
        try row.set(DB.email.ⓡ, email)
         try row.set(DB.facebookURL.ⓡ, facebookURL)
         try row.set(DB.instaURL.ⓡ, instaURL)
        try row.set(DB.userIdKey.ⓡ, userId)
        return row
    }
}

extension Vending {
    var owner: Parent<Vending, User> {
        return parent(id: userId)
    }
}

extension Vending {
    var bids: Children<Vending, Bid> {
        return children()
    }
}

//extension Vending {
//    var ownerAAA: Parent<Vending, Bid> {
//        return parent(id: id)
//    }
//}

extension Vending: ResponseRepresentable { }
//extension Vending: JSONRepresentable {}

extension Vending: Preparation {
    static func prepare(_ database: Database) throws {
        let boolFieldNameArray = [
            DB.offersFood.ⓡ, DB.offersEntertainment.ⓡ, DB.offersMusic.ⓡ,
            DB.offersRentals.ⓡ, DB.offersServices.ⓡ, DB.offersPartyPacks.ⓡ, DB.offersVenue.ⓡ
        ]
        try database.create(self) { builder in
            builder.id()
            builder.string(DB.companyName.ⓡ)
            builder.string(DB.uniqueUserName.ⓡ, unique: true)
            builder.string(DB.zipCode.ⓡ)
            builder.string(DB.description.ⓡ, optional: true)
            builder.int(DB.priceRange.ⓡ)
            builder.string(DB.email.ⓡ, optional: true)
            builder.string(DB.facebookURL.ⓡ, optional: true)
            builder.string(DB.instaURL.ⓡ, optional: true)
            for fieldName in boolFieldNameArray {
                builder.bool(fieldName)
            }
            builder.foreignId(for: User.self)
        }
        try database.driver.raw("alter table vendings alter column \(DB.id.ⓡ) set default uuid_generate_v4();")
        try database.driver.raw("alter table vendings alter column created_at set default now();")
        try database.driver.raw("alter table vendings alter column updated_at set default now();")
        try database.driver.raw("alter table vendings alter column \(DB.priceRange.ⓡ) set default 1;")
        for fieldName in boolFieldNameArray {
            try database.driver.raw("alter table vendings alter column \(fieldName) set default false;")
        }
        // Create Partial Indexes on the booleans: https://www.postgresql.org/docs/8.4/static/indexes-partial.html
        for fieldName in boolFieldNameArray {
            let command = "CREATE INDEX vendings_\(fieldName)_index " +
             "ON vendings (\(fieldName)) WHERE \(fieldName) is not true;"
            try database.driver.raw(command)
        }
        
        let s = "insert into vendings (" +
            "\(DB.userIdKey.ⓡ),  \(DB.companyName.ⓡ), \(DB.uniqueUserName.ⓡ), \(DB.zipCode.ⓡ), \(DB.offersFood.ⓡ) " +
            " ) values(" +
            "'\(User.defaultID)', 'Turtle Soup', 'turtlesoup', '92606', true " +
            " ) ;"
        try database.driver.raw(s)
    }

    // "there’s no need to manually create indexes on unique columns; doing so 
    // would just duplicate the automatically-created index."
    // https://www.postgresql.org/docs/9.4/static/ddl-constraints.html

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Vending: JSONConvertible {

    convenience init(json: JSON) throws {
        let id: String?
        let description: String?
        let priceRange: Int?
        let offersFood: Bool?
        let offersEntertainment: Bool?
        let offersMusic: Bool?
        let offersRentals: Bool?
        let offersServices: Bool?
        let offersPartyPacks: Bool?
        let offersVenue: Bool?
        let email: String?
        let facebookURL: String?
        let instaURL: String?

        do { id = try json.get(DB.id.ⓡ) } catch { id = nil }
        let rawUserId: String = try json.get(Vending.DB.userIdKey.ⓡ)
        guard let user = try User.find(rawUserId) else {
            throw Abort(.badRequest, reason: "User id \(rawUserId) not found for vending")
        }
        guard let companyName: String = try json.get(DB.companyName.ⓡ) else {
            throw Abort(.badRequest, reason: "Company Name not found for vending")
        }
        guard let uniqueUserName: String = try json.get(DB.uniqueUserName.ⓡ) else {
            throw Abort(.badRequest, reason: "Unique User Name not found for vending")
        }
        guard let zipCode: String = try json.get(DB.zipCode.ⓡ) else {
            throw Abort(.badRequest, reason: "Zipcode not found for vending")
        }
        do { description = try json.get(DB.description.ⓡ) } catch { description = nil }
        //  Set a default value for email, to be empty
//        do { email = try json.get(DB.email.ⓡ) } catch { email = ""}
        do { priceRange = try json.get(DB.priceRange.ⓡ) } catch { priceRange = 1 }
        do { offersFood = try json.get(DB.offersFood.ⓡ) } catch { offersFood = false }
        do { offersEntertainment = try json.get(DB.offersEntertainment.ⓡ) } catch { offersEntertainment = false }
        do { offersMusic = try json.get(DB.offersMusic.ⓡ) } catch { offersMusic = false }
        do { offersRentals = try json.get(DB.offersRentals.ⓡ) } catch { offersRentals = false }
        do { offersServices = try json.get(DB.offersServices.ⓡ) } catch { offersServices = false }
        do { offersPartyPacks = try json.get(DB.offersPartyPacks.ⓡ) } catch { offersPartyPacks = false }
        do { offersVenue = try json.get(DB.offersVenue.ⓡ ) } catch { offersVenue = false }
        do { email = try json.get(DB.email.ⓡ) } catch { email = "No Email found" }
         do { facebookURL = try json.get(DB.facebookURL.ⓡ) } catch { facebookURL = "No facebook URL found" }
         do { instaURL = try json.get(DB.instaURL.ⓡ) } catch { instaURL = "No Instagram URL found" }

        try self.init(
            id: id,
            companyName: companyName,
            uniqueUserName: uniqueUserName,
            zipCode: zipCode,
            description: description,
            priceRange: priceRange,
            offersFood: offersFood, offersEntertainment: offersEntertainment,
            offersMusic: offersMusic,
            offersRentals: offersRentals, offersServices: offersServices,
            offersPartyPacks: offersPartyPacks,
            offersVenue: offersVenue,
            email: email,
            facebookURL: facebookURL,
            instaURL: instaURL,
            user: user
        )
    }

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(DB.id.ⓡ, id)
        try json.set(DB.companyName.ⓡ, companyName)
        try json.set(DB.uniqueUserName.ⓡ, uniqueUserName)
        try json.set(DB.zipCode.ⓡ, zipCode)
        try json.set(DB.description.ⓡ, description)
        try json.set(DB.priceRange.ⓡ, priceRange)
        try json.set(DB.offersFood.ⓡ, offersFood)
        try json.set(DB.offersEntertainment.ⓡ, offersEntertainment)
        try json.set(DB.offersMusic.ⓡ, offersMusic)
        try json.set(DB.offersRentals.ⓡ, offersRentals)
        try json.set(DB.offersServices.ⓡ, offersServices)
        try json.set(DB.offersPartyPacks.ⓡ, offersPartyPacks)
        try json.set(DB.offersVenue.ⓡ, offersVenue)
        try json.set(DB.email.ⓡ, email)
        try json.set(DB.facebookURL.ⓡ, facebookURL)
        try json.set(DB.instaURL.ⓡ, instaURL)
        try json.set(DB.userIdKey.ⓡ, userId)
        try json.set(DB.services.ⓡ, services.all())
        return json
    }
}

extension Vending: Updateable {
    public static var updateableKeys: [UpdateableKey<Vending>] {
        return [
            UpdateableKey(DB.companyName.ⓡ, String.self) { vending, content in vending.companyName = content },
            UpdateableKey(DB.uniqueUserName.ⓡ, String.self) { vending, content in vending.uniqueUserName = content },
            UpdateableKey(DB.zipCode.ⓡ, String.self) { vending, content in vending.zipCode = content },
            UpdateableKey(DB.description.ⓡ, String.self) { vending, content in vending.description = content },
            UpdateableKey(DB.priceRange.ⓡ, Int.self) { vending, content in vending.priceRange = content },
            UpdateableKey(DB.offersFood.ⓡ, Bool.self) { vending, content in vending.offersFood = content },
            UpdateableKey(DB.offersEntertainment.ⓡ, Bool.self) { vending, content in vending.offersEntertainment = content },
            UpdateableKey(DB.offersMusic.ⓡ, Bool.self) { vending, content in vending.offersMusic = content },
            UpdateableKey(DB.offersRentals.ⓡ, Bool.self) { vending, content in vending.offersRentals = content },
            UpdateableKey(DB.offersServices.ⓡ, Bool.self) { vending, content in vending.offersServices = content },
            UpdateableKey(DB.offersPartyPacks.ⓡ, Bool.self) { vending, content in vending.offersPartyPacks = content },
            UpdateableKey(DB.offersVenue.ⓡ, Bool.self) { vending, content in vending.offersVenue = content },
            UpdateableKey(DB.email.ⓡ, String.self) { vending, content in vending.email = content },
             UpdateableKey(DB.facebookURL.ⓡ, String.self) { vending, content in vending.facebookURL = content },
             UpdateableKey(DB.instaURL.ⓡ, String.self) { vending, content in vending.instaURL = content }
      ]
    }
}

extension Vending {
    var services: Children<Vending, Service> {
        return children()
    }
}

extension Vending: TokenAuthenticatable {
    typealias TokenType = Token
}
