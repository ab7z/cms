import path from "path"

import { webpackBundler } from "@payloadcms/bundler-webpack"
import { mongooseAdapter } from "@payloadcms/db-mongodb"
import { lexicalEditor } from "@payloadcms/richtext-lexical"
import { buildConfig } from "payload/config"

import Pages from "./collections/Pages"
import Users from "./collections/Users"
import CustomToaster from "./components/CustomToaster"
import Publish from "./components/Publish"
import { Hello } from "./globals/Hello"

let mongoURL = `mongodb://${process.env.MONGO_DB_USER}:${process.env.MONGO_DB_PASS}`
mongoURL += `@${
  process.env.NODE_ENV === "development" ? process.env.MONGO_DEV_URL : process.env.MONGO_PROD_URL
}`
mongoURL += `/${process.env.MONGO_DB_NAME}`

export default buildConfig({
  admin: {
    user: Users.slug,
    bundler: webpackBundler(),
    components: {
      actions: [CustomToaster, Publish],
    },
  },
  editor: lexicalEditor({}),
  collections: [Users, Pages],
  globals: [Hello],
  typescript: {
    outputFile: path.resolve(__dirname, "payload-types.ts"),
  },
  localization: {
    defaultLocale: "en",
    locales: [{ label: "English", code: "en", rtl: false }],
    fallback: true,
  },
  graphQL: {
    disable: true,
  },
  db: mongooseAdapter({
    url: mongoURL,
  }),
  debug: true,
  telemetry: false,
  upload: {
    limits: {
      fileSize: 10000000,
    },
  },
  rateLimit: {
    skip: () => true,
  },
})
