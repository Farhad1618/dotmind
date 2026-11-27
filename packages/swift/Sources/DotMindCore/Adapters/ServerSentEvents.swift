import Foundation

public struct ServerSentEvents<Lines: AsyncSequence, Event: Decodable>: AsyncSequence where Lines.Element == String {
    public typealias Element = Event

    private let lines: Lines
    private let decoder: JSONDecoder

    public init(lines: Lines, as type: Event.Type = Event.self, decoder: JSONDecoder = JSONDecoder()) {
        self.lines = lines
        self.decoder = decoder
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(lines: lines.makeAsyncIterator(), decoder: decoder)
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        var lines: Lines.AsyncIterator
        let decoder: JSONDecoder

        public mutating func next() async throws -> Event? {
            while let line = try await lines.next() {
                guard let payload = Self.payload(of: line) else { continue }
                return try decoder.decode(Event.self, from: Data(payload.utf8))
            }
            return nil
        }

        private static func payload(of line: String) -> Substring? {
            guard line.hasPrefix("data:") else { return nil }
            var payload = line.dropFirst(5)
            if payload.first == " " { payload = payload.dropFirst() }
            if payload.isEmpty || payload == "[DONE]" { return nil }
            return payload
        }
    }
}

extension AsyncSequence where Element == String {
    public func serverSentEvents<Event: Decodable>(
        _ type: Event.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) -> ServerSentEvents<Self, Event> {
        ServerSentEvents(lines: self, as: type, decoder: decoder)
    }
}
