import { Octokit } from "@octokit/rest"
import express from "express"
import fs from "fs"
import path from "path"
import payload from "payload"

type DumpFile = Record<"localPath" | "ghPath", string>

require("dotenv").config()
const app = express()

app.get("/", (_, res) => {
  res.redirect("/admin")
})

const start = async () => {
  await payload.init({
    secret: process.env.PAYLOAD_SECRET,
    express: app,
    onInit: async () => {
      payload.logger.info(`Payload Admin URL: ${payload.getAdminURL()}`)
    },
  })

  // Custom express routes

  app.get("/publish", async (req, res) => {
    if (process.env.NODE_ENV === "development") {
      res.status(404).send("not found")
      return
    }

    const headers = req.headers
    const userId = headers.userid
    if (userId === undefined || (userId as string)?.trim().length === 0) {
      res.status(401).send("unauthorized")
      return
    }

    const user = await payload.findByID<"users">({
      collection: "users",
      id: userId.toString(),
    })
    if (user === null || user === undefined || user.id === undefined) {
      res.status(401).send("unauthorized")
      return
    }

    try {
      await commitToGitHub({ userEmail: user.email as string })
      res.status(200).send("ok")
      deleteDumps(user.email as string)
    } catch (error) {
      console.error("commit error: ", error.message)
      res.status(404).send(`commit error: ${error.message}`)
    }
  })

  app.listen(8000)
}

start().catch(console.error)

function findDumpFiles(userEmail: string) {
  const foundFiles: DumpFile[] = []

  try {
    const pathName = `/tmp/${process.env.STAGE}`
    const files = fs.readdirSync(pathName)
    for (const file of files) {
      if (file.includes(userEmail)) {
        foundFiles.push({
          localPath: path.join(pathName, file),
          ghPath: `dump/${file.trim().replace(`-${userEmail}`, "")}`,
        })
      }
    }
  } catch (error) {
    console.error(error)
    return new Error(`Find Dump Files Error: ${error.message}`)
  }

  return foundFiles
}

function deleteDumps(userEmail: string) {
  try {
    const pathName = `/tmp/${process.env.STAGE}`
    const files = fs.readdirSync(pathName)
    for (const file of files) {
      if (file.includes(userEmail)) {
        fs.unlinkSync(file)
      }
    }
  } catch (error) {
    console.error(error)
    return new Error(`Delete Dump Error: ${error.message}`)
  }
}

function commitToGitHub({ userEmail }: { userEmail: string }) {
  const octokit = new Octokit({
    auth: process.env.GH_ToKEN,
  })

  const owner = "ab7z"
  const repo = "cms"
  const branch = process.env.STAGE
  const commitMessage = `Dumped data for ${userEmail}`

  const files = findDumpFiles(userEmail)
  if (files instanceof Error) return Promise.reject(files.message)
  if (files.length === 0) return Promise.resolve()

  async function getLatestCommit() {
    const { data: refData } = await octokit.git.getRef({
      owner,
      repo,
      ref: `heads/${branch}`,
    })

    const commitSha = refData.object.sha
    const { data: commitData } = await octokit.git.getCommit({
      owner,
      repo,
      commit_sha: commitSha,
    })

    return commitData
  }

  async function createBlob(content) {
    const { data } = await octokit.git.createBlob({
      owner,
      repo,
      content: Buffer.from(content).toString("base64"),
      encoding: "base64",
    })

    return data.sha
  }

  async function createTree(baseTreeSha: string, files: DumpFile[]) {
    const tree = await Promise.all(
      files.map(async (file) => {
        const content = fs.readFileSync(file.localPath, "utf8")
        const blobSha = await createBlob(content)
        return {
          path: file.ghPath,
          mode: "100644",
          type: "blob",
          sha: blobSha,
        }
      })
    )

    const { data } = await octokit.git.createTree({
      owner,
      repo,
      base_tree: baseTreeSha,
      // @ts-expect-error the types are wrong
      tree,
    })

    return data.sha
  }

  async function createCommit(parentSha: string, treeSha: string, message: string) {
    const { data } = await octokit.git.createCommit({
      owner,
      repo,
      message,
      tree: treeSha,
      parents: [parentSha],
    })

    return data.sha
  }

  async function updateRef(commitSha: string) {
    await octokit.git.updateRef({
      owner,
      repo,
      ref: `heads/${branch}`,
      sha: commitSha,
    })
  }

  async function commitFiles() {
    const latestCommit = await getLatestCommit()
    const treeSha = await createTree(latestCommit.tree.sha, files as DumpFile[])
    const newCommitSha = await createCommit(latestCommit.sha, treeSha, commitMessage)
    await updateRef(newCommitSha)
  }

  return commitFiles()
}
