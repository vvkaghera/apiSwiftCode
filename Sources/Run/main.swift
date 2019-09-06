import App

import Vapor
import PostgreSQLProvider
import AuthProvider
import VaporS3Signer
import VaporAPNS

/// We have isolated all of our App's logic into
/// the App module because it makes our app
/// more testable.
///
/// In general, the executable portion of our App
/// shouldn't include much more code than is presented
/// here.
///
/// We simply initialize our Droplet, optionally
/// passing in values if necessary
/// Then, we pass it to our App's setup function
/// this should setup all the routes and special
/// features of our app
///
/// .run() runs the Droplet's commands,
/// if no command is given, it will default to "serve"//localhost DB




let config = try Config()
try config.setup()
let drop = try Droplet(config)
try drop.setup()

drop.get { req in
    return try drop.view.make("Welcome",[
        "message": "Welcome"])
}
try drop.run()

/*
 var options = try! Options(topic: "<your topic>", teamId: "<your teamId>", keyId: "<your keyId>", keyPath: "<your path to key>")
 options.forceCurlInstall = true
 
 */


