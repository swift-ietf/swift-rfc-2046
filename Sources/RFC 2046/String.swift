//
//  File.swift
//  swift-rfc-2046
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

extension String {
    public init(
        _ bodypartHeaders: RFC_2046.BodyPart.Headers
    ) {
        self = [String:String](bodypartHeaders)
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\r\n")
    }
}
