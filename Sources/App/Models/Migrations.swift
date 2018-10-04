//
//  Migrations.swift
//  Created by Steven O'Toole on 9/21/17.
//
// https://medium.com/@xGoPox/vapors-fluent-migrations-830e95f4d990

import Fluent


final class PostalCodeMigration: Preparation {
    static func prepare(_ database: Database) throws {
        try database.driver.raw("ALTER TABLE users Add COLUMN postalcode CHARACTER VARYING(32); ")
    }
    static func revert(_ database: Database) throws {}
}


final class TextFieldsMigration: Preparation {
    static func prepare(_ database: Database) throws {
        try database.driver.raw("ALTER TABLE services ALTER COLUMN description TYPE varchar(512); ")
        try database.driver.raw("ALTER TABLE vendings ALTER COLUMN description TYPE varchar(512); ")
    }
    static func revert(_ database: Database) throws {}
}

final class PlusOneMigration: Preparation {
    static func prepare(_ database: Database) throws {
        try database.driver.raw("alter table users alter column \(User.DB.countryCode.ⓡ) set default '+1';")
    }
    static func revert(_ database: Database) throws {}
}

final class PhoneNullAndFBMigration: Preparation {
    static func prepare(_ database: Database) throws {
        try database.driver.raw("ALTER TABLE users ALTER COLUMN \(User.DB.phone.ⓡ) DROP NOT NULL;")
        try database.driver.raw("ALTER TABLE users ADD COLUMN \(User.DB.facebookID.ⓡ) CHARACTER VARYING(50);")
        try database.driver.raw("CREATE INDEX users_\(User.DB.facebookID.ⓡ)_key ON users (\(User.DB.facebookID.ⓡ));")
    }
    static func revert(_ database: Database) throws {}
}

/*
SELECT r.relname, r.relkind, n.nspname
FROM pg_class r INNER JOIN pg_namespace n ON r.relnamespace = n.oid
WHERE r.relname = 'users_phone_key';
 */
// ALTER TABLE mytable ALTER COLUMN mycolumn DROP NOT NULL;

final class CascadeMigration: Preparation {

    static func prepare(_ database: Database) throws {
        let dropServiceSQL = "alter table services " +
            "drop constraint \"_fluent_fk_services.vending_id-vendings.vending_id\"; "
        let addServiceSQL = "alter table services " +
             "add constraint \"_fluent_fk_services.vending_id-vendings.vending_id\" " +
                "foreign key (vending_id) " +
                "references vendings(vending_id) " +
                " on delete cascade; "
        let dropVendingSQL = "alter table vendings " +
            "drop constraint \"_fluent_fk_vendings.user_id-users.user_id\"; "
        let addVendingSQL = "alter table vendings " +
             "add constraint \"_fluent_fk_vendings.user_id-users.user_id\" " +
                "foreign key (user_id) " +
                "references users(user_id) " +
                " on delete cascade; "
        let dropTokenSQL = "alter table tokens " +
            "drop constraint \"_fluent_fk_tokens.user_id-users.user_id\"; "
        let addTokenSQL = "alter table tokens " +
             "add constraint \"_fluent_fk_tokens.user_id-users.user_id\" " +
                "foreign key (user_id) " +
                "references users(user_id) " +
                " on delete cascade; "

        try database.driver.raw(dropServiceSQL)
        try database.driver.raw(addServiceSQL)
        try database.driver.raw(dropVendingSQL)
        try database.driver.raw(addVendingSQL)
        try database.driver.raw(dropTokenSQL)
        try database.driver.raw(addTokenSQL)
    }

    static func revert(_ database: Database) throws {}
}
