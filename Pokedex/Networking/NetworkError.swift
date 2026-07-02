//
//  NetworkError.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation

/// Errors surfaced by the networking layer.
enum NetworkError: Error {
    case invalidResponse
    case unacceptableStatusCode(Int)
    case transport(underlying: Error)
    case decoding(underlying: Error)
}

extension NetworkError: Equatable {
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidResponse, .invalidResponse):
            return true
        case let (.unacceptableStatusCode(l), .unacceptableStatusCode(r)):
            return l == r
        case (.transport, .transport):
            return true
        case (.decoding, .decoding):
            return true
        default:
            return false
        }
    }
}
