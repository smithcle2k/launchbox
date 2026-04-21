//
//  NetworkManager.swift
//  LaunchBox
//

import Foundation

enum APIError: Error, Sendable {
    case invalidURL
    case transport(Error)
    case decoding(Error)
    case server(Int)
}

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Async/await `URLSession` template. Uses `Secrets.apiBaseURL` for relative paths.
/// `URLSession` is thread-safe; this type is a class (not `actor`) so it can read `Secrets` without crossing actor isolation.
final class NetworkManager: @unchecked Sendable {
    static let shared = NetworkManager()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func get<T: Decodable & Sendable>(
        _ path: String,
        as type: T.Type,
        decoder: JSONDecoder? = nil
    ) async throws -> T {
        try await dataRequest(path: path, method: .get, body: Optional<Data>.none, as: type, decoder: decoder)
    }

    func send<T: Decodable & Sendable, B: Encodable & Sendable>(
        _ path: String,
        method: HTTPMethod,
        body: B?,
        as type: T.Type,
        encoder: JSONEncoder? = nil,
        decoder: JSONDecoder? = nil
    ) async throws -> T {
        let enc = encoder ?? self.encoder
        let data: Data?
        if let body {
            data = try enc.encode(body)
        } else {
            data = nil
        }
        return try await dataRequest(path: path, method: method, body: data, as: type, decoder: decoder)
    }

    private func dataRequest<T: Decodable & Sendable>(
        path: String,
        method: HTTPMethod,
        body: Data?,
        as type: T.Type,
        decoder: JSONDecoder?
    ) async throws -> T {
        let base = Secrets.apiBaseURL
        guard let url = URL(string: path, relativeTo: base)?.absoluteURL else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(URLError(.badServerResponse))
        }

        guard (200 ..< 300).contains(http.statusCode) else {
            throw APIError.server(http.statusCode)
        }

        let dec = decoder ?? self.decoder
        do {
            return try dec.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}
