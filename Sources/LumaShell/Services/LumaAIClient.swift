import Foundation

struct LumaAssistantReply {
    let text: String
    let usedAI: Bool
}

enum LumaAIError: LocalizedError {
    case missingKey
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "AI is offline. Set OPENAI_API_KEY in your environment for this development build."
        case .invalidResponse:
            return "Luma received an unreadable response."
        case .api(let message):
            return message
        }
    }
}

@MainActor
final class LumaAIClient {
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!
    private let model = "gpt-5.6-luna"

    func send(_ prompt: String, controller: ShellController) async throws -> LumaAssistantReply {
        guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty else {
            throw LumaAIError.missingKey
        }

        var response = try await createResponse(
            apiKey: key,
            body: [
                "model": model,
                "instructions": """
                You are Luma, the concise built-in assistant for LumaShell on macOS.
                Help with the desktop and use the provided tools when the user asks for an action.
                Never claim an action happened unless a tool result confirms it.
                Keep normal replies short.
                """,
                "input": prompt,
                "tools": toolSchemas
            ]
        )

        for _ in 0..<3 {
            let calls = functionCalls(from: response)
            if calls.isEmpty {
                let text = outputText(from: response)
                guard !text.isEmpty else { throw LumaAIError.invalidResponse }
                return LumaAssistantReply(text: text, usedAI: true)
            }

            var outputs: [[String: Any]] = []
            for call in calls {
                let result = await ShellToolRouter.execute(
                    name: call.name,
                    arguments: call.arguments,
                    controller: controller
                )
                outputs.append([
                    "type": "function_call_output",
                    "call_id": call.callID,
                    "output": result
                ])
            }

            guard let responseID = response["id"] as? String else {
                throw LumaAIError.invalidResponse
            }

            response = try await createResponse(
                apiKey: key,
                body: [
                    "model": model,
                    "previous_response_id": responseID,
                    "input": outputs,
                    "tools": toolSchemas
                ]
            )
        }

        let fallback = outputText(from: response)
        return LumaAssistantReply(
            text: fallback.isEmpty ? "I hit the action limit for that request." : fallback,
            usedAI: true
        )
    }

    private func createResponse(apiKey: String, body: [String: Any]) async throws -> [String: Any] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, rawResponse) = try await URLSession.shared.data(for: request)
        guard let http = rawResponse as? HTTPURLResponse else {
            throw LumaAIError.invalidResponse
        }

        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]

        guard (200..<300).contains(http.statusCode) else {
            let message =
                ((json?["error"] as? [String: Any])?["message"] as? String) ??
                "OpenAI request failed with status \(http.statusCode)."
            throw LumaAIError.api(message)
        }

        guard let json else { throw LumaAIError.invalidResponse }
        return json
    }

    private struct FunctionCall {
        let callID: String
        let name: String
        let arguments: [String: Any]
    }

    private func functionCalls(from response: [String: Any]) -> [FunctionCall] {
        guard let output = response["output"] as? [[String: Any]] else { return [] }

        return output.compactMap { item in
            guard
                item["type"] as? String == "function_call",
                let callID = item["call_id"] as? String,
                let name = item["name"] as? String,
                let rawArguments = item["arguments"] as? String,
                let data = rawArguments.data(using: .utf8),
                let arguments = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            else {
                return nil
            }

            return FunctionCall(callID: callID, name: name, arguments: arguments)
        }
    }

    private func outputText(from response: [String: Any]) -> String {
        guard let output = response["output"] as? [[String: Any]] else { return "" }

        var chunks: [String] = []
        for item in output where item["type"] as? String == "message" {
            guard let content = item["content"] as? [[String: Any]] else { continue }
            for part in content where part["type"] as? String == "output_text" {
                if let text = part["text"] as? String {
                    chunks.append(text)
                }
            }
        }
        return chunks.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var toolSchemas: [[String: Any]] {
        [
            [
                "type": "function",
                "name": "list_apps",
                "description": "List installed Mac applications when you need to identify an app before launching it.",
                "strict": true,
                "parameters": [
                    "type": "object",
                    "properties": [:],
                    "required": [],
                    "additionalProperties": false
                ]
            ],
            [
                "type": "function",
                "name": "launch_app",
                "description": "Launch an installed Mac application by name.",
                "strict": true,
                "parameters": [
                    "type": "object",
                    "properties": [
                        "app": ["type": "string", "description": "Installed application name."]
                    ],
                    "required": ["app"],
                    "additionalProperties": false
                ]
            ],
            [
                "type": "function",
                "name": "set_theme",
                "description": "Change the active LumaShell theme.",
                "strict": true,
                "parameters": [
                    "type": "object",
                    "properties": [
                        "theme": [
                            "type": "string",
                            "enum": ["macOS9", "windowsXP", "cyberpunk"]
                        ]
                    ],
                    "required": ["theme"],
                    "additionalProperties": false
                ]
            ],
            [
                "type": "function",
                "name": "set_widget",
                "description": "Show or hide a LumaShell desktop widget.",
                "strict": true,
                "parameters": [
                    "type": "object",
                    "properties": [
                        "widget": [
                            "type": "string",
                            "enum": ["clock", "system", "memory", "quickLaunch", "assistant"]
                        ],
                        "visible": ["type": "boolean"]
                    ],
                    "required": ["widget", "visible"],
                    "additionalProperties": false
                ]
            ],
            [
                "type": "function",
                "name": "open_folder",
                "description": "Open a safe common folder in the LumaShell file browser.",
                "strict": true,
                "parameters": [
                    "type": "object",
                    "properties": [
                        "location": [
                            "type": "string",
                            "enum": ["Home", "Desktop", "Documents", "Downloads", "Applications"]
                        ]
                    ],
                    "required": ["location"],
                    "additionalProperties": false
                ]
            ],
            [
                "type": "function",
                "name": "hide_shell",
                "description": "Hide LumaShell and return to the normal macOS desktop.",
                "strict": true,
                "parameters": [
                    "type": "object",
                    "properties": [:],
                    "required": [],
                    "additionalProperties": false
                ]
            ]
        ]
    }
}
