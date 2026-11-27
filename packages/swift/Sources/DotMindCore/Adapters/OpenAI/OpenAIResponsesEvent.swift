public struct OpenAIResponsesEvent: Decodable, Hashable, Sendable {
    public var type: String
    public var delta: String?
    public var item: Item?
    public var response: Response?
    public var message: String?

    public init(
        type: String,
        delta: String? = nil,
        item: Item? = nil,
        response: Response? = nil,
        message: String? = nil
    ) {
        self.type = type
        self.delta = delta
        self.item = item
        self.response = response
        self.message = message
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = container.lenient(String.self, .type) ?? ""
        delta = container.lenient(String.self, .delta)
        item = container.lenient(Item.self, .item)
        response = container.lenient(Response.self, .response)
        message = container.lenient(String.self, .message)
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case delta
        case item
        case response
        case message
    }
}

extension OpenAIResponsesEvent {
    public struct Item: Decodable, Hashable, Sendable {
        public var type: String
        public var name: String?
        public var id: String?
        public var callId: String?
        public var serverLabel: String?

        public init(
            type: String,
            name: String? = nil,
            id: String? = nil,
            callId: String? = nil,
            serverLabel: String? = nil
        ) {
            self.type = type
            self.name = name
            self.id = id
            self.callId = callId
            self.serverLabel = serverLabel
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = container.lenient(String.self, .type) ?? ""
            name = container.lenient(String.self, .name)
            id = container.lenient(String.self, .id)
            callId = container.lenient(String.self, .callId)
            serverLabel = container.lenient(String.self, .serverLabel)
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case name
            case id
            case callId = "call_id"
            case serverLabel = "server_label"
        }
    }

    public struct Response: Decodable, Hashable, Sendable {
        public var output: [Item]?

        public init(output: [Item]? = nil) {
            self.output = output
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            output = container.lenient([Item].self, .output)
        }

        private enum CodingKeys: String, CodingKey {
            case output
        }
    }
}
