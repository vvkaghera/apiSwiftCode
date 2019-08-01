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
/// if no command is given, it will default to "serve"
//localhost DB

//clone

//setenv("DATABASE_URL", "postgres://agqeccbudcxxwq:8c26e4d257a4065cc534c90c3403e109e41c1de3e29cde3fd1d3508847f889c8@ec2-50-19-109-120.compute-1.amazonaws.com:5432/def3vb4rpj5e2i", 1)

//setenv("DATABASE_URL", "postgres://dtjvjcciwfvdyz:f60bed089e9ad62820e4fd3874db10eed1d4a575371909a8ffedab858dbe5721@ec2-50-19-109-120.compute-1.amazonaws.com:5432/d7plcfk7ft43pt", 1)

//last working
setenv("DATABASE_URL", "postgres://hygziviienbche:90c60426363db158e435caf81ef5748070a8654874cd18150b1b4f9aeca4c7b2@ec2-107-21-233-72.compute-1.amazonaws.com/d8sug7gqkae4om", 1)

//setenv("DATABASE_URL", "postgres://myuser:mypass@localhost/mydb", 1)
//setenv("DATABASE_URL", "postgres://tanfivdjxapkul:0008c580961e453c93c777c205b9e7b0158dce945096f1f985e287f7ead086a3@localhost/d2cj7i4r2u8nq6", 1)

//setenv("url":"psql://user:pass@hostname:5432/database")





//Heroku testing DB

//setenv("DATABASE_URL", "postgres://hygziviienbche:90c60426363db158e435caf81ef5748070a8654874cd18150b1b4f9aeca4c7b2@ec2-107-21-233-72.compute-1.amazonaws.com:5432/d8sug7gqkae4om", 1)

//Heroku Production DB

//setenv("DATABASE_URL","postgres://tanfivdjxapkul:0008c580961e453c93c777c205b9e7b0158dce945096f1f985e287f7ead086a3@ec2-54-235-80-137.compute-1.amazonaws.com:5432/d2cj7i4r2u8nq6", 1)

//mouldypnakotic1 - on testing AWS S3
//setenv("AWS_ACCESS_KEY_ID", "AKIAIENWEJQCLRECQHGA", 1)
//last working
//setenv("AWS_ACCESS_KEY_ID", "AKIAJJHNGWUXK6PMZKVA", 1)
//new key from 15 may 2019
setenv("AWS_ACCESS_KEY_ID", "AKIAUJOYMREXURFCVZ7M", 1)

//mouldypnakotic - on production

//setenv("AWS_ACCESS_KEY_ID", "AKIAIGPUVMOAB6XTGKFA", 1)
setenv("AWS_REGION", "us-west-1", 1)

//mouldypnakotic1 on testing AWS S3

//new key from 15 may 2019
setenv("AWS_SECRET_ACCESS_KEY", "lpKIgt2qOfrvZf9LlSAX1SoUFBxyISE94ILRJ71x", 1)

//last working
//setenv("AWS_SECRET_ACCESS_KEY", "GTNvsWKFz15MZjZNOOasN7HyEFroKrjElfj4rr7R", 1)

//comment but we have not worked on below key
//setenv("AWS_SECRET_ACCESS_KEY", "TJ02h1QW8C/niUjTSk+DWmrmgAhKtZ/OaKiLu2h1", 1)

setenv("SENDBIRD_TOKEN", "582dd7133f22f3f548566b666295ac9b72c1b069", 1)

//OLD
//setenv("TWILIO_FROM", "+12133220623", 1)
//setenv("TWILIO_SID", "AC40e82047b23537e9deeda88386a29185", 1)
//setenv("TWILIO_TOKEN", "926aa405e467d695138f670f5e278ee9", 1)

//NEW
setenv("TWILIO_FROM", "+17142661899", 1)
setenv("TWILIO_SID", "AC5c653caca83b9a7d89ca088a60a86928", 1)
setenv("TWILIO_TOKEN", "2216d6a05223132dee269ad05165935d", 1)



//old working
//setenv("TWILIO_FROM", "+12133220623", 1)
//setenv("TWILIO_SID", "AC40e82047b23537e9deeda88386a29185", 1)
//setenv("TWILIO_TOKEN", "ed9278dafdd7bbfa963b3071351260c2", 1)



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


