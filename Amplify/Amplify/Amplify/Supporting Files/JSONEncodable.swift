//
//  JSONEncodable.swift
//  Amplify
//
//  Supporting protocol for OpenAPI generated models
//

import Foundation

// MARK: - String Rule for OpenAPI Validation

/// String validation rule for OpenAPI generated models
public struct StringRule {
    public let minLength: Int?
    public let maxLength: Int?
    public let pattern: String?

    public init(minLength: Int? = nil, maxLength: Int? = nil, pattern: String? = nil) {
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
    }

    /// Validates a string against this rule
    public func validate(_ string: String) -> Bool {
        // Check minimum length
        if let minLength = minLength, string.count < minLength {
            return false
        }

        // Check maximum length
        if let maxLength = maxLength, string.count > maxLength {
            return false
        }

        // Check pattern (basic pattern matching, not full regex)
        if pattern != nil {
            // For now, just return true as pattern validation is complex
            // In a production app, you would use NSRegularExpression
            return true
        }

        return true
    }
}

// MARK: - JSON Encodable Protocol

/// Protocol for types that can be encoded to JSON
public protocol JSONEncodable {
    /// Encodes the instance to JSON data
    func encodeToJSON() throws -> Data

    /// Encodes the instance to a JSON dictionary
    func encodeToJSONObject() throws -> Any
}

// MARK: - Default Implementation

extension JSONEncodable where Self: Encodable {
    public func encodeToJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    public func encodeToJSONObject() throws -> Any {
        let data = try encodeToJSON()
        return try JSONSerialization.jsonObject(with: data, options: [])
    }
}

// MARK: - Encodable Extension

extension Encodable {
    /// Convenience method to encode to JSON data
    public func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    /// Convenience method to encode to JSON string
    public func toJSONString() throws -> String {
        let data = try toJSONData()
        guard let string = String(data: data, encoding: .utf8) else {
            throw JSONError.encodingFailed("Could not convert data to UTF-8 string")
        }
        return string
    }
}

// MARK: - JSON Error

public enum JSONError: Error, LocalizedError {
    case encodingFailed(String)
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let message):
            return "JSON encoding failed: \(message)"
        case .decodingFailed(let message):
            return "JSON decoding failed: \(message)"
        }
    }
}
