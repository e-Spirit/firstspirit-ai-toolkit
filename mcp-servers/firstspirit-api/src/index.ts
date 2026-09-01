#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const FS_URL = process.env.FS_URL ?? "";
const FS_API_KEY = process.env.FS_API_KEY ?? "";

const server = new Server(
  { name: "firstspirit-api", version: "0.1.0" },
  { capabilities: { tools: {} } }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    // TODO: Register FirstSpirit API tools here.
    // Example shape:
    // {
    //   name: "get_project",
    //   description: "Retrieve a FirstSpirit project by ID",
    //   inputSchema: {
    //     type: "object",
    //     properties: { projectId: { type: "string" } },
    //     required: ["projectId"],
    //   },
    // },
  ],
}));

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name } = request.params;
  throw new Error(`Unknown tool: ${name}`);
});

const transport = new StdioServerTransport();
await server.connect(transport);
