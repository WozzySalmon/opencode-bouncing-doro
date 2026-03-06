import type { Plugin } from "@opencode-ai/plugin"
import { spawn, type ChildProcess } from "child_process"
import path from "path"

let doroProcess: ChildProcess | null = null
const scriptPath = path.join(import.meta.dirname, "bouncing-doro.sh")

function startBouncing() {
  if (doroProcess) return

  const isWSL =
    require("fs").existsSync("/proc/version") &&
    require("fs")
      .readFileSync("/proc/version", "utf8")
      .toLowerCase()
      .includes("microsoft")

  if (isWSL) {
    // -w _ = brand new window (not a tab)
    doroProcess = spawn(
      "wt.exe",
      ["-w", "_", "--title", "🩷 Doro", "wsl.exe", "bash", scriptPath],
      { stdio: "ignore", detached: true },
    )
  } else {
    // Native Linux: open in a new terminal window
    // Try common terminal emulators in order
    const terminals = [
      { cmd: "kitty", args: ["--title", "🩷 Doro", "bash", scriptPath] },
      { cmd: "alacritty", args: ["--title", "🩷 Doro", "-e", "bash", scriptPath] },
      { cmd: "gnome-terminal", args: ["--title=🩷 Doro", "--", "bash", scriptPath] },
      { cmd: "xterm", args: ["-T", "🩷 Doro", "-e", "bash", scriptPath] },
    ]

    for (const term of terminals) {
      try {
        require("child_process").execSync(`which ${term.cmd}`, { stdio: "ignore" })
        doroProcess = spawn(term.cmd, term.args, {
          stdio: "ignore",
          detached: true,
        })
        break
      } catch {
        continue
      }
    }
  }

  if (doroProcess) {
    doroProcess.on("error", () => {
      doroProcess = null
    })
    doroProcess.on("exit", () => {
      doroProcess = null
    })
    doroProcess.unref()
  }
}

function stopBouncing() {
  if (doroProcess?.pid) {
    try {
      process.kill(-doroProcess.pid, "SIGTERM")
    } catch {
      try {
        process.kill(doroProcess.pid, "SIGTERM")
      } catch {}
    }
    doroProcess = null
  }
}

const BouncingDoroPlugin: Plugin = async ({ client }) => {
  await client.app.log({
    body: { service: "bouncing-doro", level: "info", message: "🩷 Bouncing Doro plugin loaded!" },
  })

  return {
    event: async ({ event }) => {
      // session.status fires when the session changes state
      if (event.type === "session.status") {
        const status = event.properties.status.type
        if (status === "busy") {
          startBouncing()
        } else if (status === "idle") {
          stopBouncing()
        }
      }

      // session.idle also fires when done
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
