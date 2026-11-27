public struct ChatCompletionChunk: Decodable, Hashable, Sendable {
    public var choices: [Choice]?

    public init(choices: [Choice]? = nil) {
        self.choices = choices
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        choices = container.lenient([Choice].self, .choices)
    }

    private enum CodingKeys: String, CodingKey {
        case choices
    }
}

extension ChatCompletionChunk {
    public struct Choice: Decodable, Hashable, Sendable {
        public var delta: Delta?
        public var finishReason: String?

        public init(delta: Delta? = nil, finishReason: String? = nil) {
            self.delta = delta
            self.finishReason = finishReason
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            delta = container.lenient(Delta.self, .delta)
            finishReason = container.lenient(String.self, .finishReason)
        }

        private enum CodingKeys: String, CodingKey {
            case delta
            case finishReason = "finish_reason"
        }
    }

    public struct Delta: Decodable, Hashable, Sendable {
        public var content: String?
        public var reasoning: String?
        public var reasoningContent: String?
        public var toolCalls: [ToolCall]?

        public init(
            content: String? = nil,
            reasoning: String? = nil,
            reasoningContent: String? = nil,
            toolCalls: [ToolCall]? = nil
        ) {
            self.content = content
            self.reasoning = reasoning
            self.reasoningContent = reasoningContent
            self.toolCalls = toolCalls
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            content = container.lenient(String.self, .content)
            reasoning = container.lenient(String.self, .reasoning)
            reasoningContent = container.lenient(String.self, .reasoningContent)
            toolCalls = container.lenient([ToolCall].self, .toolCalls)
        }

        private enum CodingKeys: String, CodingKey {
            case content
            case reasoning
            case reasoningContent = "reasoning_content"
            case toolCalls = "tool_calls"
        }
    }

    public struct ToolCall: Decodable, Hashable, Sendable {
        public var index: Int?
        public var id: String?
        public var function: Function?

        public init(index: Int? = nil, id: String? = nil, function: Function? = nil) {
            self.index = index
            self.id = id
            self.function = function
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            index = container.lenient(Int.self, .index)
            id = container.lenient(String.self, .id)
            function = container.lenient(Function.self, .function)
        }

        private enum CodingKeys: String, CodingKey {
            case index
            case id
            case function
        }
    }

    public struct Function: Decodable, Hashable, Sendable {
        public var name: String?
        public var arguments: String?

        public init(name: String? = nil, arguments: String? = nil) {
            self.name = name
            self.arguments = arguments
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = container.lenient(String.self, .name)
            arguments = container.lenient(String.self, .arguments)
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case arguments
        }
    }
}
