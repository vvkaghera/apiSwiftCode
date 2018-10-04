import App

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

//setenv("DATABASE_URL", "postgres://tanfivdjxapkul:0008c580961e453c93c777c205b9e7b0158dce945096f1f985e287f7ead086a3@localhost/d2cj7i4r2u8nq6", 1)
setenv("DATABASE_URL", "postgres://hygziviienbche:90c60426363db158e435caf81ef5748070a8654874cd18150b1b4f9aeca4c7b2@ec2-107-21-233-72.compute-1.amazonaws.com:5432/d8sug7gqkae4om", 1)
//setenv("DATABASE_URL","postgres://tanfivdjxapkul:0008c580961e453c93c777c205b9e7b0158dce945096f1f985e287f7ead086a3@ec2-54-235-80-137.compute-1.amazonaws.com:5432/d2cj7i4r2u8nq6", 1)
setenv("AWS_ACCESS_KEY_ID", "AKIAIENWEJQCLRECQHGA", 1)
//setenv("AWS_ACCESS_KEY_ID", "AKIAIGPUVMOAB6XTGKFA", 1)
setenv("AWS_REGION", "us-west-1", 1)

setenv("AWS_SECRET_ACCESS_KEY", "TJ02h1QW8C/niUjTSk+DWmrmgAhKtZ/OaKiLu2h1", 1)
//setenv("AWS_SECRET_ACCESS_KEY", "/XLiz1TwOK6CFjEo+UHqVA7xKl/4MCMl6esE4YFL", 1)
setenv("SENDBIRD_TOKEN", "582dd7133f22f3f548566b666295ac9b72c1b069", 1)
setenv("TWILIO_FROM", "+12133220623", 1)
setenv("TWILIO_SID", "AC40e82047b23537e9deeda88386a29185", 1)
setenv("TWILIO_TOKEN", "ed9278dafdd7bbfa963b3071351260c2", 1)

let config = try Config()
try config.setup()

let drop = try Droplet(config)
try drop.setup()

try drop.run()
