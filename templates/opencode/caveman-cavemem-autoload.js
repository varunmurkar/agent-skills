export const CavemanCavememAutoload = async ({ $ }) => {
  const cavememBin = "__CAVEMEM_BIN__"
  const cavememDir = cavememBin && cavememBin !== "cavemem" ? cavememBin.replace(/\/[^/]+$/, "") : ""

  const notify = async (title, message) => {
    try {
      if (process.platform === "darwin") {
        await $`osascript -e ${`display notification ${JSON.stringify(message)} with title ${JSON.stringify(title)}`}`
        return
      }

      if (process.platform === "linux") {
        await $`notify-send ${title} ${message}`
      }
    } catch {
      // Notification support is best-effort.
    }
  }

  return {
    config: async (config) => {
      config.mcp ||= {}

      if (!config.mcp.cavemem) {
        config.mcp.cavemem = {
          type: "local",
          command: [cavememBin || "cavemem", "mcp"],
          enabled: true,
        }
      }
    },

    "experimental.chat.system.transform": async (_input, output) => {
      const snippet = [
        "Terse like caveman. Technical substance exact. Only fluff die.",
        "Drop: articles, filler (just/really/basically), pleasantries, hedging.",
        "Fragments OK. Short synonyms. Code unchanged.",
        "Pattern: [thing] [action] [reason]. [next step].",
        "ACTIVE EVERY RESPONSE. No revert after many turns. No filler drift.",
        'Code/commits/PRs: normal. Off: "stop caveman" / "normal mode".',
      ].join("\n")

      if (!output.system.some((entry) => entry.includes("ACTIVE EVERY RESPONSE"))) {
        output.system.push(snippet)
      }
    },

    "shell.env": async (_input, output) => {
      if (!cavememDir) {
        return
      }

      const currentPath = output.env.PATH || process.env.PATH || ""
      const segments = currentPath.split(":").filter(Boolean)

      if (!segments.includes(cavememDir)) {
        output.env.PATH = [cavememDir, ...segments].join(":")
      }
    },

    event: async ({ event }) => {
      if (event.type === "session.idle") {
        await notify("OpenCode", "Session completed")
      }

      if (event.type === "session.error") {
        await notify("OpenCode", "Session errored")
      }
    },
  }
}
