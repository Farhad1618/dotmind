public struct AnthropicStreamEvent: Decodable, Hashable, Sendable {
    public var type: String
    public var index: Int?
    public var contentBlock: ContentBlock?
    public var delta: Delta?
    public var error: ErrorDetail?

    public init(
        type: String,
        index: Int? = nil,
        contentBlock: ContentBlock? = nil,
        delta: Delta? = nil,
        error: ErrorDetail? = nil
    ) {
        self.type = type
        self.index = index
        self.contentBlock = contentBlock
        self.delta = delta
        self.error = error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = container.lenient(String.self, .type) ?? ""
        index = container.lenient(Int.self, .index)
        contentBlock = container.lenient(ContentBlock.self, .contentBlock)
        delta = container.lenient(Delta.self, .delta)
        error = container.lenient(ErrorDetail.self, .error)
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case index
        case contentBlock = "content_block"
        case delta
        case error
    }
}

extension AnthropicStreamEvent {
    public struct ContentBlock: Decodable, Hashable, Sendable {
        public var type: String
        public var name: String?
        public var id: String?
        public var toolUseId: String?
        public var isError: Bool?
        public var contentType: String?

        public init(
            type: String,
            name: String? = nil,
            id: String? = nil,
            toolUseId: String? = nil,
            isError: Bool? = nil,
            contentType: String? = nil
        ) {
            self.type = type
            self.name = name
            self.id = id
            self.toolUseId = toolUseId
            self.isError = isError
            self.contentType = contentType
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = container.lenient(String.self, .type) ?? ""
            name = container.lenient(String.self, .name)
            id = container.lenient(String.self, .id)
            toolUseId = container.lenient(String.self, .toolUseId)
            isError = container.lenient(Bool.self, .isError)
            contentType = container.lenient(TypedContent.self, .content)?.type
        }

        private struct TypedContent: Decodable {
            var type: String?
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case name
            case id
            case toolUseId = "tool_use_id"
            case isError = "is_error"
            case content
        }
    }

    public struct Delta: Decodable, Hashable, Sendable {
        public var type: String?
        public var text: String?
        public var thinking: String?
        public var partialJson: String?
        public var stopReason: String?

        public init(
            type: String? = nil,
            text: String? = nil,
            thinking: String? = nil,
            partialJson: String? = nil,
            stopReason: String? = nil
        ) {
            self.type = type
            self.text = text
            self.thinking = thinking
            self.partialJson = partialJson
            self.stopReason = stopReason
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = container.lenient(String.self, .type)
            text = container.lenient(String.self, .text)
            thinking = container.lenient(String.self, .thinking)
            partialJson = container.lenient(String.self, .partialJson)
            stopReason = container.lenient(String.self, .stopReason)
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case text
            case thinking
            case partialJson = "partial_json"
            case stopReason = "stop_reason"
        }
    }

    public struct ErrorDetail: Decodable, Hashable, Sendable {
        public var type: String?
        public var message: String?

        public init(type: String? = nil, message: String? = nil) {
            self.type = type
            self.message = message
        }
    }
}
