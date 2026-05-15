//
//  Codable+UIKit.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 09/10/25.
//

import UIKit

// MARK: - CodableColor Wrapper
public struct CodableColor: Codable, Equatable {
    private let wrapped: UIColor

    public init(_ color: UIColor) {
        self.wrapped = color
    }

    // Accessor for UIKit API compatibility
    public var uiColor: UIColor { wrapped }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        guard let hex = wrapped.hexString else {
            throw EncodingError.invalidValue(
                wrapped,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Failed to encode UIColor to hex"
                )
            )
        }
        try container.encode(hex)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hex = try container.decode(String.self)
        guard let decoded = UIColor(hexString: hex) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid hex string: \(hex)"
            )
        }
        self.wrapped = decoded
    }
}

// MARK: - CodableFont Wrapper
public struct CodableFont: Codable, Equatable {
    private let wrapped: UIFont

    public init(_ font: UIFont) {
        self.wrapped = font
    }

    // Accessor for UIKit API compatibility
    public var uiFont: UIFont { wrapped }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrapped.fontName)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let name = try container.decode(String.self)
        guard let decodedFont = UIFont(name: name, size: .zero) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid font name: \(name)"
            )
        }
        self.wrapped = decodedFont
    }
}
