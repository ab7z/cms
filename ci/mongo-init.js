db = db.getSiblingDB(process.env.MONGO_DB_NAME)
db.createUser({
  user: process.env.MONGO_DB_USER,
  pwd: process.env.MONGO_DB_PASS,
  roles: [
    {
      role: "dbAdmin",
      db: process.env.MONGO_DB_NAME,
    },
  ],
})

db.grantRolesToUser(process.env.MONGO_DB_USER, ["readWrite"])
db.createCollection("init")
db.init.insertOne({name: "initial creation"})
