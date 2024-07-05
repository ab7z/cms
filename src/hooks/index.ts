import fs from "fs"
import path from "path"
import payload from "payload"
import type { CollectionAfterChangeHook, GlobalAfterChangeHook } from "payload/types"

export function checkDBConnection() {
  const dbState = payload.db.connection.readyState
  if (dbState !== 1) throw new Error("Connection to MongoDB has failed")
}

function ensureDirectoryExists(directory: string) {
  if (!fs.existsSync(directory)) fs.mkdirSync(directory, { recursive: true })
}

export const dumpCollection: CollectionAfterChangeHook = async ({ operation, collection, req }) => {
  const isLogin = collection.slug === "users" && operation === "update" && req.user === undefined
  if (isLogin) return

  const DEV_PATH = path.resolve(require.main.path, "../dump")
  const PROD_PATH = `/tmp/${process.env.STAGE}`
  ensureDirectoryExists(PROD_PATH)

  const collectionName = collection.slug
  const userEmail = req.user.email

  const fileName =
    process.env.NODE_ENV === "development"
      ? `${collectionName}.json`
      : `${collectionName}-${userEmail}.json`
  const persistingPath = process.env.NODE_ENV === "development" ? DEV_PATH : PROD_PATH

  const filePath = `${persistingPath}/${fileName}`
  if (fs.existsSync(filePath)) fs.unlinkSync(filePath)

  const cursor = payload.db.connection.db.collection(collectionName).find({}).sort({ _id: 1 })
  for await (const doc of cursor) {
    // @ts-expect-error the mongoexport format is expected
    doc._id = { $oid: doc._id.toString() }
    doc.createdAt = { $date: doc.createdAt?.toISOString() ?? new Date().toISOString() }
    doc.updatedAt = { $date: doc.updatedAt?.toISOString() ?? new Date().toISOString() }
    fs.writeFileSync(filePath, `${JSON.stringify(doc, null, 2)}\n`, {
      encoding: "utf8",
      flag: "a+",
    })
  }
}

//TODO: improve the global dump logic
// dump every global via global.slug and import them all in glob document
export const dumpGlobals: GlobalAfterChangeHook = async ({ req }) => {
  const collectionName = "globals"
  const userEmail = req.user.email

  const DEV_PATH = path.resolve(require.main.path, "../dump")
  const PROD_PATH = `/tmp/${process.env.STAGE}`
  ensureDirectoryExists(PROD_PATH)

  const fileName =
    process.env.NODE_ENV === "development"
      ? `${collectionName}.json`
      : `${collectionName}-${userEmail}.json`
  const persistingPath = process.env.NODE_ENV === "development" ? DEV_PATH : PROD_PATH

  const filePath = `${persistingPath}/${fileName}`
  if (fs.existsSync(filePath)) fs.unlinkSync(filePath)

  const cursor = payload.db.connection.db.collection(collectionName).find({}).sort({ _id: 1 })
  for await (const doc of cursor) {
    // @ts-expect-error the mongoexport format is expected
    doc._id = { $oid: doc._id.toString() }
    doc.createdAt = { $date: doc.createdAt?.toISOString() ?? new Date().toISOString() }
    doc.updatedAt = { $date: doc.updatedAt?.toISOString() ?? new Date().toISOString() }
    fs.writeFileSync(filePath, `${JSON.stringify(doc, null, 2)}\n`, {
      encoding: "utf8",
      flag: "a+",
    })
  }
}
