import type { Plugin } from "@opencode-ai/plugin";
import { ChildProcess, spawn } from "child_process";
import path from "path";

export default class BouncingDoroPlugin implements Plugin {
  name = "opencode-bouncing-doro";
  private childProcess: ChildProcess | null = null;
  private scriptPath: string;

  constructor(context: any) {
    // Locate the script relative to the plugin directory
    this.scriptPath = path.join(__dirname, "bouncing-doro.sh");
  }

  async onSessionStatus(status: string) {
    if (status === "thinking" || status === "generating" || status === "busy") {
      this.startBouncing();
    } else if (status === "idle") {
      this.stopBouncing();
    }
  }

  async onSessionIdle() {
    this.stopBouncing();
  }

  private startBouncing() {
    if (this.childProcess) return;

    this.childProcess = spawn(this.scriptPath, [], {
      stdio: "ignore",
      detached: true,
    });

    this.childProcess.on("err", (err) => {
      console.error("Bouncing Doro error:", err);
      this.childProcess = null;
    });

    this.childProcess.unref();
  }

  private stopBouncing() {
    if (this.childProcess) {
      // Send SIGTERM to the process group if detached, or just the process
      if (this.childProcess.pid) {
        try {
          process.kill(this.childProcess.pid, "SIGTERM");
        } catch (e) {
          // Process might already be dead
        }
      }
      this.childProcess = null;
    }
  }

  async onShutdown() {
    this.stopBouncing();
  }
}
