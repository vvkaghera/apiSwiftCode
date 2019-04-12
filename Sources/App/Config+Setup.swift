import FluentProvider
import PostgreSQLProvider
import AuthProvider
import VaporS3Signer

extension Config {
    public func setup() throws {
        // allow fuzzy conversions for these types
        // (add your own types here)
        // 0xtim: it’s basically a stop gap for Swift 3 to try and get around the immaturity of
        // its generics. It tries to help with converting models to `Node` objects
        Node.fuzzy = [Row.self, JSON.self, Node.self]

        try setupProviders()
        try setupPreparations()
    }

    /// Configure providers
    private func setupProviders() throws {
        try addProvider(FluentProvider.Provider.self)
        try addProvider(PostgreSQLProvider.Provider.self)
        try addProvider(AuthProvider.Provider.self)
        try addProvider(VaporS3Signer.Provider.self)
    }

    /// Add all models that should have their
    /// schemas prepared before the app boots
    private func setupPreparations() throws {
        // preparations are [Preparation.Type] declared in 
        // Dependencies/FluentProvider 1.1.1/FluentProvider/Droplet/Config+Preparation.swift

        // Preparation is a protocol in Dependencies/Fluent 2.1.0/Fluent/Preparation

        // preparations run from Dependencies/FluentProvider 1.1.1/FluentProvider/Droplet/Droplet+Prepare.swift

        //
        // MIGRATIONS
        // https://medium.com/@xGoPox/vapors-fluent-migrations-830e95f4d990

        preparations.append(User.self)
        preparations.append(Vending.self)
        preparations.append(Token.self)
        preparations.append(Service.self)
        preparations.append(Event.self)
        preparations.append(Order.self)
        preparations.append(Pivot<User, Vending>.self)
        preparations.append(CascadeMigration.self)
        preparations.append(PlusOneMigration.self)
        preparations.append(PhoneNullAndFBMigration.self)
        preparations.append(TextFieldsMigration.self)
        preparations.append(PostalCodeMigration.self)
    }
}
