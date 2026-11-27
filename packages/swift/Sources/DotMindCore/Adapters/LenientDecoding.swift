extension KeyedDecodingContainer {
    func lenient<Value: Decodable>(_ type: Value.Type, _ key: Key) -> Value? {
        (try? decodeIfPresent(type, forKey: key)) ?? nil
    }
}

extension String {
    var jsLength: Int { utf16.count }
}

extension Optional where Wrapped == String {
    var jsLength: Int { self?.utf16.count ?? 0 }

    var nonEmpty: String? {
        guard let self, !self.isEmpty else { return nil }
        return self
    }
}
