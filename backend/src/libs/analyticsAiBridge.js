import { spawn } from "child_process";
import path from "path";

const SCRIPT_PATH = path.resolve(process.cwd(), "src/ai_engine/suggest_plan.py");
const PYTHON_BIN = process.env.PYTHON_BIN || "python3";
const TIMEOUT_MS = 1500;

export const generateAnalyticsAIPlan = (payload) =>
  new Promise((resolve, reject) => {
    const child = spawn(PYTHON_BIN, [SCRIPT_PATH], {
      cwd: process.cwd(),
      stdio: ["pipe", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";
    let finished = false;

    const timer = setTimeout(() => {
      if (finished) return;
      finished = true;
      child.kill("SIGKILL");
      reject(new Error("AI timeout"));
    }, TIMEOUT_MS);

    child.stdout.on("data", (chunk) => {
      stdout += chunk.toString();
    });

    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });

    child.on("error", (error) => {
      if (finished) return;
      finished = true;
      clearTimeout(timer);
      reject(error);
    });

    child.on("close", (code) => {
      if (finished) return;
      finished = true;
      clearTimeout(timer);

      if (code !== 0) {
        reject(new Error(stderr.trim() || `AI process exited with code ${code}`));
        return;
      }

      try {
        resolve(JSON.parse(stdout));
      } catch (error) {
        reject(new Error(`Invalid AI response: ${error.message}`));
      }
    });

    child.stdin.write(JSON.stringify(payload));
    child.stdin.end();
  });
