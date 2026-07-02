//
//  HTTPClient.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation


protocol HTTPClient: Sendable {
    /// Performs a GET and returns the raw body, throwing `NetworkError` on a
    /// non-2xx status or a transport failure.
    func get(from url: URL) async throws -> Data
}
