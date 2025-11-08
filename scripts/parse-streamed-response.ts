// To read a streamed message from Anthropic, you can use this script with
// pbpaste | yarn tsx ./scripts/parse-streamed-response.ts

interface StreamDelta {
	type: string
	text?: string
	partial_json?: string
}

interface InputJsonDelta {
	type: "input_json_delta"
	partial_json: string
}

interface StreamData {
	type: string
	delta: StreamDelta
	index?: number
}

interface ContentBlock {
	type: string
	id?: string
	name?: string
	input?: unknown
}

interface ContentBlockStart {
	type: string
	index: number
	content_block: ContentBlock
}

interface AnthropicToolCall {
	name?: string
	parameters?: unknown
	raw?: string
}

function extractTextFromStream(inputText: string): { text: string; tools: AnthropicToolCall[] } {
	// Split the input into lines
	const lines = inputText.trim().split("\n")

	// Initialize variables
	let currentText = ""
	const tools: AnthropicToolCall[] = []
	const toolDataByIndex: Map<number, { name: string; json: string }> = new Map()

	// Process each line
	for (let i = 0; i < lines.length; i++) {
		const line = lines[i]

		// Handle content_block_start events for tool_use
		if (line.startsWith("event: content_block_start")) {
			const dataLine = lines[i + 1]
			if (dataLine && dataLine.startsWith("data:")) {
				try {
					const jsonStr = dataLine.slice(5).trim()
					const data = JSON.parse(jsonStr) as ContentBlockStart

					if (data.content_block?.type === "tool_use") {
						const toolName = data.content_block.name || ""
						const index = data.index
						if (toolName && index !== undefined) {
							toolDataByIndex.set(index, { name: toolName, json: "" })
						}
					}
				} catch {
					// Skip invalid JSON
					continue
				}
			}
		}

		// Handle content_block_delta events
		else if (line.startsWith("event: content_block_delta")) {
			const dataLine = lines[i + 1]
			if (dataLine && dataLine.startsWith("data:")) {
				try {
					const jsonStr = dataLine.slice(5).trim()
					const data = JSON.parse(jsonStr) as StreamData

					// Extract text from text_delta
					if (data.delta?.text) {
						currentText += data.delta.text
					}
					// Extract tool parameters from partial_json (old format) or input_json_delta (new format)
					else if (
						data.delta?.partial_json ||
						(data.delta && "partial_json" in data.delta && data.delta.type === "input_json_delta")
					) {
						const partialJson = data.delta.partial_json || (data.delta as InputJsonDelta).partial_json
						const index = data.index

						if (index !== undefined) {
							const toolData = toolDataByIndex.get(index)
							if (toolData) {
								// New format: we have tool name from content_block_start, or old format continuation
								toolData.json += partialJson
							} else {
								// Old format: create new entry for this index
								const existingData = { name: "", json: partialJson }
								toolDataByIndex.set(index, existingData)
							}
						}
					}
				} catch {
					// Skip invalid JSON
					continue
				}
			}
		}

		// Handle content_block_stop events to finalize tools
		else if (line.startsWith("event: content_block_stop")) {
			const dataLine = lines[i + 1]
			if (dataLine && dataLine.startsWith("data:")) {
				try {
					const jsonStr = dataLine.slice(5).trim()
					const data = JSON.parse(jsonStr)
					const index = data.index

					if (index !== undefined) {
						const toolData = toolDataByIndex.get(index)
						if (toolData && (toolData.name || toolData.json.trim())) {
							try {
								if (toolData.name && toolData.json.trim()) {
									// New format: we have tool name from content_block_start and parameters from input_json_delta
									const parsedParameters = JSON.parse(toolData.json)
									tools.push({
										name: toolData.name,
										parameters: parsedParameters,
									})
								} else if (toolData.json.trim()) {
									// Old format: everything is in partial_json
									const parsedTool = JSON.parse(toolData.json)
									tools.push({
										name: parsedTool.name,
										parameters: parsedTool.parameters,
									})
								}
							} catch {
								// If tool JSON is malformed, return the raw string
								tools.push({
									raw: toolData.json,
								})
							}
							// Remove processed tool data
							toolDataByIndex.delete(index)
						}
					}
				} catch {
					// Skip invalid JSON
					continue
				}
			}
		}
	}

	// Handle any remaining tools that didn't have content_block_stop events
	for (const [, toolData] of toolDataByIndex) {
		if (toolData.name || toolData.json.trim()) {
			try {
				if (toolData.name && toolData.json.trim()) {
					// New format: we have tool name from content_block_start and parameters from input_json_delta
					const parsedParameters = JSON.parse(toolData.json)
					tools.push({
						name: toolData.name,
						parameters: parsedParameters,
					})
				} else if (toolData.json.trim()) {
					// Old format: everything is in partial_json
					const parsedTool = JSON.parse(toolData.json)
					tools.push({
						name: parsedTool.name,
						parameters: parsedTool.parameters,
					})
				}
			} catch {
				// If tool JSON is malformed, return the raw string
				tools.push({
					raw: toolData.json,
				})
			}
		}
	}

	return { text: currentText, tools }
}

// Export the function for testing
export { extractTextFromStream }

// Read from stdin if no file is provided
async function main() {
	let inputText: string

	if (process.argv.length > 2) {
		// Read from file
		const fs = await import("fs/promises")
		inputText = await fs.readFile(process.argv[2], "utf-8")
	} else {
		// Read from stdin
		inputText = await new Promise<string>((resolve) => {
			let data = ""
			process.stdin.on("data", (chunk) => {
				data += chunk
			})
			process.stdin.on("end", () => {
				resolve(data)
			})
		})
	}

	// Extract and print the text
	const extractedText = extractTextFromStream(inputText)
	console.log(JSON.stringify(extractedText, null, 2))
}

main().catch(console.error)
