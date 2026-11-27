import Foundation

public protocol EventTranslator {
    associatedtype Event
    init()
    mutating func translate(_ event: Event) -> [AgentEvent]
}

@discardableResult
public func follow<Events: AsyncSequence, Translator: EventTranslator>(
    _ events: Events,
    using translator: Translator.Type,
    tracker: ActivityTracker
) async throws -> ActivityTracker where Events.Element == Translator.Event {
    var translate = translator.init()
    do {
        for try await event in events {
            let translated = translate.translate(event)
            await tracker.push(contentsOf: translated)
        }
    } catch {
        await tracker.push(.error(message: error.localizedDescription))
        throw error
    }
    return tracker
}

@discardableResult
public func followAnthropicStream<Events: AsyncSequence>(
    _ events: Events,
    tracker: ActivityTracker = ActivityTracker()
) async throws -> ActivityTracker where Events.Element == AnthropicStreamEvent {
    try await follow(events, using: AnthropicTranslator.self, tracker: tracker)
}

@discardableResult
public func followOpenAIResponses<Events: AsyncSequence>(
    _ events: Events,
    tracker: ActivityTracker = ActivityTracker()
) async throws -> ActivityTracker where Events.Element == OpenAIResponsesEvent {
    try await follow(events, using: OpenAIResponsesTranslator.self, tracker: tracker)
}

@discardableResult
public func followChatCompletions<Events: AsyncSequence>(
    _ events: Events,
    tracker: ActivityTracker = ActivityTracker()
) async throws -> ActivityTracker where Events.Element == ChatCompletionChunk {
    try await follow(events, using: ChatCompletionsTranslator.self, tracker: tracker)
}
