import Foundation
import CoreLocation
import Combine
import UIKit

/// The app model that communicates with the server.
class BlabberModel: ObservableObject {
  var username = ""
  var urlSession = URLSession.shared

  init() {
  }

  /// Current live updates
  @Published var messages: [Message] = []

  /// Shares the current user's address in chat.
  func shareLocation() async throws {
  }

  /// Does a countdown and sends the message.
  func countdown(to message: String) async throws {
    guard !message.isEmpty else { return }
    let counter = AsyncStream<String> { continuation in
      var countdown = 3
      var timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
        guard countdown > 0 else {
          timer.invalidate()
          continuation.yield(with: .success("🎉 " + message))
          return
        }
        continuation.yield("\(countdown) ...")
        countdown -= 1
      })
    }
    
    for try await countdownMessage in counter {
      try await say(countdownMessage)
    }
  }

  /// Start live chat updates
  @MainActor
  func chat() async throws {
    guard
      let query = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
      let url = URL(string: "http://localhost:8080/chat/room?\(query)")
      else {
      throw "Invalid username"
    }

    let (stream, response) = try await liveURLSession.bytes(from: url, delegate: nil)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw "The server responded with an error."
    }

    print("Start live updates")

    try await withTaskCancellationHandler {
      print("End live updates")
      messages = []
    } operation: {
      try await readMessages(stream: stream)
    }
  }

  /// Reads the server chat stream and updates the data model.
  @MainActor
  private func readMessages(stream: URLSession.AsyncBytes) async throws {
    var iterator = stream.lines.makeAsyncIterator()
    
    guard let first = try await iterator.next() else { throw "No response from the server" }
    guard let data = first.data(using: .utf8),
          let status = try? JSONDecoder().decode(ServerStatus.self, from: data)
    else { throw "Invalid response from server" }
    messages.append(Message(message: "\(status.activeUsers) active users"))
    
    for try await line in stream.lines {
      if let data = line.data(using: .utf8),
         let update = try? JSONDecoder().decode(Message.self, from: data) {
        messages.append(update)
      }
    }
    
  }

  /// Sends the user's message to the chat server
  func say(_ text: String, isSystemMessage: Bool = false) async throws {
    guard
      !text.isEmpty,
      let url = URL(string: "http://localhost:8080/chat/say")
    else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = try JSONEncoder().encode(
      Message(id: UUID(), user: isSystemMessage ? nil : username, message: text, date: Date())
    )

    let (_, response) = try await urlSession.data(for: request, delegate: nil)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw "The server responded with an error."
    }
  }

  /// A URL session that goes on indefinitely, receiving live updates.
  private var liveURLSession: URLSession = {
    var configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = .infinity
    return URLSession(configuration: configuration)
  }()
}
