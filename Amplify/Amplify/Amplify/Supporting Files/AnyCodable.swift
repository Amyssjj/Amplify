//
//  AnyCodable.swift
//  Amplify
//
//  Minimal AnyCodable implementation for OpenAPI generated models
//

import Foundation

// MARK: - AnyEncodable

/// Type-erased `Encodable` value.
public struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void
    
    public init<T: Encodable>(_ encodable: T) {
        self.encode = encodable.encode
    }
    
    public func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

// MARK: - AnyDecodable

/// Type-erased `Decodable` value.
public struct AnyDecodable: Decodable {
    public let value: Any
    
    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = ()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyDecodable].self) {
            value = array.map(\.value)
        } else if let dictionary = try? container.decode([String: AnyDecodable].self) {
            value = dictionary.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode value"
            )
        }
    }
}

// MARK: - AnyCodable

/// Type-erased `Codable` value.
public struct AnyCodable: Codable {
    public let value: Any
    
    public init<T: Codable>(_ value: T) {
        self.value = value
    }
    
    public init<T>(_ value: T) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let decodable = try AnyDecodable(from: decoder)
        self.value = decodable.value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        case let encodable as Encodable:
            try encodable.encode(to: encoder)
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Literal Conformances

extension AnyCodable: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.value = ()
    }
}

extension AnyCodable: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self.value = value
    }
}

extension AnyCodable: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.value = value
    }
}

extension AnyCodable: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.value = value
    }
}

extension AnyCodable: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.value = value
    }
}

extension AnyCodable: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Any...) {
        self.value = elements
    }
}

extension AnyCodable: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (AnyHashable, Any)...) {
        let dictionary = Dictionary(elements, uniquingKeysWith: { first, _ in first })
        self.value = dictionary
    }
}