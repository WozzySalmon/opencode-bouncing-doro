import type { Plugin } from "@opencode-ai/plugin"
import { spawn, type ChildProcess } from "child_process"
import path from "path"

let doroProcess: ChildProcess | null = null
const scriptPath = path.join(__dirname, "bouncing-doro.sh")

function startBouncing() {
  if (doroProcess) return
  doroProcess = spawn(scriptPath, [], {
    stdio: "inherit",
    detached: true,
  })
  doroProcess.on("error", (err) => {
    console.error("Bouncing Doro error:", err)
    doroProcess = null
  })
  doroProcess.on("exit", () => {
    doroProcess = null
  })
}

function stopBouncing() {
  if (doroProcess?.pid) {
    try {
      process.kill(-doroProcess.pid, "SIGTERM")
    } catch (_) {}
    doroProcess = null
  }
}

export const BouncingDoroPlugin: Plugin = async ({ project, client, $, directory, worktree }) => {
  await client.app.log({
    body: { service: "bouncing-doro", level: "info", message: "🩷 Bouncing Doro plugin loaded!" },
  })

  return {
    event: async ({ event }) => {
      if (event.type === "session.updated" && event.properties?.status) {
        const status = event.properties.status
        if (status === "thinking" || status === "generating" || status === "busy" || status === "running") {
          startBouncing()
        } else if (status === "idle" || status === "waiting") {
          stopBouncing()
        }
      }

      if (event.type === "session.idle") {
        stopBouncing()
      }
    },

    "tool.execute.before": async () => {
      startBouncing()
    },

    "tool.execute.after": async () => {
      // Don't stop here — more tools might follow
    },
  }
}
