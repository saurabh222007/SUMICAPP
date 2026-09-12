import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const DEFAULT_API_KEY = process.env.EXPLABS_API_KEY || "xpl_e26ee92b4c2b974009bbe6a7975fa649ef4c8d65";
const DEFAULT_BASE_URL = process.env.EXPLABS_BASE_URL || "https://api.experientiallabs.ai";

const server = new Server(
  {
    name: "explabs-ai",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "explabs_chat_completion",
        description:
          "Query any AI model hosted on Experiential Labs AI (e.g., qwen3.8-flash, mistral-large, o3-mini, deepseek, etc.) and return its response directly.",
        inputSchema: {
          type: "object",
          properties: {
            model: {
              type: "string",
              description:
                "The model ID to invoke (e.g., 'qwen3.8-flash', 'mistral-large', 'qwen3-coder-plus', 'o3-mini', 'step-3.5-flash').",
            },
            prompt: {
              type: "string",
              description: "The user prompt / message to send to the model.",
            },
            system_prompt: {
              type: "string",
              description: "Optional system prompt / instructions for the model.",
            },
            temperature: {
              type: "number",
              description: "Sampling temperature (default: 0.7).",
            },
            max_tokens: {
              type: "integer",
              description: "Max tokens for completion.",
            },
          },
          required: ["model", "prompt"],
        },
      },
      {
        name: "explabs_list_models",
        description:
          "List available AI models from the Experiential Labs AI catalog, with optional keyword filtering.",
        inputSchema: {
          type: "object",
          properties: {
            filter: {
              type: "string",
              description:
                "Optional keyword to filter model IDs (e.g. 'qwen', 'mistral', 'free', 'code', 'o3').",
            },
          },
        },
      },
      {
        name: "explabs_whoami",
        description:
          "Verify the authentication status, organization ID, and details on Experiential Labs AI.",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const apiKey = process.env.EXPLABS_API_KEY || DEFAULT_API_KEY;
  const baseUrl = (process.env.EXPLABS_BASE_URL || DEFAULT_BASE_URL).replace(/\/+$/, "");

  try {
    if (name === "explabs_whoami") {
      const res = await fetch(`${baseUrl}/api/whoami`, {
        headers: {
          Authorization: `Bearer ${apiKey}`,
        },
      });

      if (!res.ok) {
        const errorText = await res.text();
        return {
          content: [
            {
              type: "text",
              text: `Error ${res.status}: ${errorText}`,
            },
          ],
          isError: true,
        };
      }

      const data = await res.json();
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(data, null, 2),
          },
        ],
      };
    }

    if (name === "explabs_list_models") {
      const res = await fetch(`${baseUrl}/v1/models`, {
        headers: {
          Authorization: `Bearer ${apiKey}`,
        },
      });

      if (!res.ok) {
        const errorText = await res.text();
        return {
          content: [
            {
              type: "text",
              text: `Error ${res.status}: ${errorText}`,
            },
          ],
          isError: true,
        };
      }

      const data = await res.json();
      let models = data.data || [];
      const filter = (args?.filter || "").toLowerCase().trim();

      if (filter) {
        models = models.filter((m) => m.id.toLowerCase().includes(filter));
      }

      const modelList = models.map((m) => m.id);
      return {
        content: [
          {
            type: "text",
            text: `Found ${modelList.length} model(s)${filter ? ` matching "${filter}"` : ""}:\n\n` + modelList.join("\n"),
          },
        ],
      };
    }

    if (name === "explabs_chat_completion") {
      const { model, prompt, system_prompt, temperature, max_tokens } = args;

      const messages = [];
      if (system_prompt) {
        messages.push({ role: "system", content: system_prompt });
      }
      messages.push({ role: "user", content: prompt });

      const payload = {
        model,
        messages,
      };

      if (typeof temperature === "number") {
        payload.temperature = temperature;
      }
      if (typeof max_tokens === "number") {
        payload.max_tokens = max_tokens;
      }

      const res = await fetch(`${baseUrl}/v1/chat/completions`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });

      if (!res.ok) {
        const errorText = await res.text();
        return {
          content: [
            {
              type: "text",
              text: `API Error ${res.status} from Experiential Labs (${model}):\n${errorText}`,
            },
          ],
          isError: true,
        };
      }

      const data = await res.json();
      const reply = data.choices?.[0]?.message?.content || "(No text content returned)";
      const usage = data.usage ? `\n\n---\n*Tokens used: prompt=${data.usage.prompt_tokens}, completion=${data.usage.completion_tokens}, total=${data.usage.total_tokens}*` : "";

      return {
        content: [
          {
            type: "text",
            text: reply + usage,
          },
        ],
      };
    }

    throw new Error(`Unknown tool: ${name}`);
  } catch (err) {
    return {
      content: [
        {
          type: "text",
          text: `Failed to execute ${name}: ${err.message}`,
        },
      ],
      isError: true,
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((error) => {
  console.error("Server error:", error);
  process.exit(1);
});
