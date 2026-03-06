import type { Plugin } from "@opencode-ai/plugin"
import { spawn, execSync } from "child_process"
import path from "path"

let doroRunning = false
const scriptPath = path.join(import.meta.dirname, "bouncing-doro.sh")

const isWSL =
  require("fs").existsSync("/proc/version") &&
  require("fs")
    .readFileSync("/proc/version", "utf8")
    .toLowerCase()
    .includes("microsoft")

function startBouncing() {
  if (doroRunning) return
  doroRunning = true

  if (isWSL) {
    // wt.exe launches and exits immediately — we track by bash process instead
    spawn(
      "wt.exe",
      ["-w", "_", "--title", "🩷 Doro", "wsl.exe", "bash", scriptPath],
      { stdio: "ignore", detached: true },
    ).unref()
  } else {
    const terminals = [
      { cmd: "kitty", args: ["--title", "🩷 Doro", "bash", scriptPath] },
      { cmd: "alacritty", args: ["--title", "🩷 Doro", "-e", "bash", scriptPath] },
      { cmd: "gnome-terminal", args: ["--title=🩷 Doro", "--", "bash", scriptPath] },
      { cmd: "xterm", args: ["-T", "🩷 Doro", "-e", "bash", scriptPath] },
    ]

    for (const term of terminals) {
      try {
        execSync(`which ${term.cmd}`, { stdio: "ignore" })
        spawn(term.cmd, term.args, { stdio: "ignore", detached: true }).unref()
        break
      } catch {
        continue
      }
    }
  }
}

function stopBouncing() {
  if (!doroRunning) return
  doroRunning = false

  try {
    if (isWSL) {
      // Kill all bash instances running bouncing-doro.sh
      execSync(`pkill -f "bash.*bouncing-doro\\.sh"`, { stdio: "ignore" })
    } else {
      execSync(`pkill -f "bash.*bouncing-doro\\.sh"`, { stdio: "ignore" })
    }
  } catch {
    // Process may have already exited
  }
}

const BouncingDoroPlugin: Plugin = async ({ client }) => {
  await client.app.log({
    body: { service: "bouncing-doro", level: "info", message: "🩷 Bouncing Doro plugin loaded!" },
  })

  return {
    event: async ({ event }) => {
      if (event.type === "session.status") {
        const status = event.properties.status.type
        if (status === "busy") {
          startBouncing()
        } else if (status === "idle") {
          stopBouncing()
        }
      }

      if (event.type === "session.idle") {
        stopBouncing()
      }
    },

    "tool.execute.before": async (_input, _output) => {
      startBouncing()
    },
  }
}

export default BouncingDoroPlugin
