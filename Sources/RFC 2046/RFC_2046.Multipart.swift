public import Binary_Serializable_Primitives
import INCITS_4_1986
public import RFC_2045

extension RFC_2046 {
    /// Multipart message structure
    ///
    /// Represents a MIME multipart message containing multiple body parts
    /// separated by boundary delimiters.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Text + HTML alternative
    /// let multipart = try RFC_2046.Multipart(
    ///     subtype: .alternative,
    ///     parts: [
    ///         .init(
    ///             contentType: .textPlainUTF8,
    ///             text: "Hello!"
    ///         ),
    ///         .init(
    ///             contentType: .textHTMLUTF8,
    ///             text: "<h1>Hello!</h1>"
    ///         )
    ///     ]
    /// )
    ///
    /// // Serialize to bytes
    /// let bytes = [UInt8](multipart)
    /// let body = String(decoding: bytes, as: UTF8.self)
    /// let headers = [
    ///     "Content-Type": multipart.contentType.headerValue
    /// ]
    /// ```
    public struct Multipart: Hashable, Sendable, Codable {
        /// Multipart subtype
        public let subtype: Subtype

        /// Body parts
        public let parts: [BodyPart]

        /// Boundary for separating parts
        ///
        /// A validated boundary string conforming to RFC 2046 requirements.
        public let boundary: Boundary

        /// Optional preamble (text before first boundary)
        public let preamble: String?

        /// Optional epilogue (text after last boundary)
        public let epilogue: String?

        /// Additional Content-Type parameters beyond boundary
        ///
        /// Allows RFC extensions (2387, 7578, etc.) to add custom parameters
        /// to the multipart Content-Type header.
        ///
        /// Uses type-safe `RFC_2045.Parameter.Name` for parameter names.
        /// String literals work via `ExpressibleByStringLiteral` conformance.
        public let additionalParameters: [RFC_2045.Parameter.Name: String]

        /// Creates a multipart WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 2046 validation.
        /// Only use for internal construction after validation.
        public init(
            __unchecked _: Void,
            subtype: Subtype,
            parts: [BodyPart],
            boundary: Boundary,
            preamble: String?,
            epilogue: String?,
            additionalParameters: [RFC_2045.Parameter.Name: String]
        ) {
            self.subtype = subtype
            self.parts = parts
            self.boundary = boundary
            self.preamble = preamble
            self.epilogue = epilogue
            self.additionalParameters = additionalParameters
        }

        /// Creates a multipart message
        ///
        /// - Parameters:
        ///   - subtype: Multipart subtype
        ///   - parts: Body parts (must not be empty)
        ///   - boundary: Boundary delimiter (caller must provide)
        ///   - preamble: Optional preamble text
        ///   - epilogue: Optional epilogue text
        ///   - additionalParameters: Additional Content-Type parameters (e.g., type, start for RFC 2387)
        ///
        /// - Throws: `RFC_2046.Multipart.Error.emptyParts` if parts array is empty
        public init(
            subtype: Subtype,
            parts: [BodyPart],
            boundary: Boundary,
            preamble: String? = nil,
            epilogue: String? = nil,
            additionalParameters: [RFC_2045.Parameter.Name: String] = [:]
        ) throws(Error) {
            guard !parts.isEmpty else {
                throw RFC_2046.Multipart.Error.emptyParts
            }

            // F-006: validate parameter values HERE (typed error) so
            // `contentType` can stay non-throwing and build structurally.
            for (name, value) in additionalParameters {
                guard Self.isRepresentableParameterValue(value) else {
                    throw RFC_2046.Multipart.Error.invalidParameterValue(
                        name: name.rawValue,
                        value: value
                    )
                }
            }

            self.init(
                __unchecked: (),
                subtype: subtype,
                parts: parts,
                boundary: boundary,
                preamble: preamble,
                epilogue: epilogue,
                additionalParameters: additionalParameters
            )
        }
    }
}
//
//// MARK: - Convenience Initializers
//
// extension RFC_2046.Multipart {
//    /// Creates a multipart message with a string boundary
//    ///
//    /// Convenience initializer that validates and converts a string boundary.
//    ///
//    /// - Parameters:
//    ///   - subtype: Multipart subtype
//    ///   - parts: Body parts (must not be empty)
//    ///   - boundary: Boundary string to validate
//    ///   - preamble: Optional preamble text
//    ///   - epilogue: Optional epilogue text
//    ///   - additionalParameters: Additional Content-Type parameters
//    ///
//    /// - Throws: `RFC_2046.Multipart.Error` if validation fails
//    public init(
//        subtype: Subtype,
//        parts: [RFC_2046.BodyPart],
//        boundary: String,
//        preamble: String? = nil,
//        epilogue: String? = nil,
//        additionalParameters: [RFC_2045.Parameter.Name: String] = [:]
//    ) throws {
//        try self.init(
//            subtype: subtype,
//            parts: parts,
//            boundary: RFC_2046.Boundary(boundary),
//            preamble: preamble,
//            epilogue: epilogue,
//            additionalParameters: additionalParameters
//        )
//    }
// }

// MARK: - Computed Properties

extension RFC_2046.Multipart {
    /// True when `value` can be carried as an RFC 2045 parameter value —
    /// representable as a token or a quoted-string the serializer can emit
    /// without escaping (printable ASCII, no CR/LF/controls, no `"` or `\`).
    ///
    /// F-006: enforced in `init` with a typed error so `contentType` can stay
    /// non-throwing and be constructed structurally.
    static func isRepresentableParameterValue(_ value: String) -> Bool {
        value.utf8.allSatisfy { byte in
            (0x20...0x7E).contains(byte)
                && byte != UInt8(ascii: "\"")
                && byte != UInt8(ascii: "\\")
        }
    }

    /// The Content-Type for this multipart message
    ///
    /// Includes boundary parameter and any additional parameters.
    ///
    /// F-006: constructed STRUCTURALLY from the validated fields — no
    /// interpolate-then-reparse, no `try!`. `boundary` is validated by
    /// `Boundary`, `subtype` by `Subtype`, and `additionalParameters` values
    /// by `init` (`isRepresentableParameterValue`); canonical RFC 2045
    /// parameter quoting is applied by `ContentType`'s serialization.
    public var contentType: RFC_2045.ContentType {
        var parameters: [RFC_2045.Parameter.Name: String] = [.boundary: boundary.rawValue]

        // Merge additional parameters from RFC extensions
        parameters.merge(additionalParameters) { _, new in new }

        return RFC_2045.ContentType(
            __unchecked: (),
            type: "multipart",
            subtype: subtype.rawValue,
            parameters: parameters
        )
    }
}

// MARK: - Binary.Serializable ([FAM-012] — Multipart is byte-domain, Binary-only)

extension RFC_2046.Multipart: Binary.Serializable {
    /// Serializes the whole multipart body as wire bytes.
    ///
    /// [FAM-012] Multipart is byte-domain (its parts may carry binary / MIME-
    /// encoded content), so it conforms to `Binary.Serializable` ONLY.
    /// Serialization is context-free — the value carries its own boundary.
    /// Clause-9: composes `Boundary`'s and `BodyPart`'s own `Byte` verbs directly
    /// into the sink — never a `[Byte]`-intermediate detour.
    ///
    /// ## RFC 2046 Format
    ///
    /// ```
    /// [preamble CRLF CRLF]
    /// --boundary CRLF
    /// headers CRLF CRLF content CRLF
    /// ...
    /// --boundary-- CRLF
    /// [epilogue CRLF]
    /// ```
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ multipart: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        let hyphen = ASCII.Code.hyphen.byte
        let cr = ASCII.Code.cr.byte
        let lf = ASCII.Code.lf.byte

        // Preamble (optional)
        if let preamble = multipart.preamble {
            buffer.append(contentsOf: [Byte](preamble.utf8))
            buffer.append(cr)
            buffer.append(lf)
            buffer.append(cr)
            buffer.append(lf)
        }

        // Body parts, each fenced by "--boundary"
        for part in multipart.parts {
            buffer.append(hyphen)
            buffer.append(hyphen)
            // clause-9: Boundary Byte verb
            RFC_2046.Boundary.serialize(multipart.boundary, into: &buffer)
            buffer.append(cr)
            buffer.append(lf)

            RFC_2046.BodyPart.serialize(part, into: &buffer)  // clause-9: BodyPart Byte verb
            buffer.append(cr)
            buffer.append(lf)
        }

        // Final "--boundary--"
        buffer.append(hyphen)
        buffer.append(hyphen)
        RFC_2046.Boundary.serialize(multipart.boundary, into: &buffer)
        buffer.append(hyphen)
        buffer.append(hyphen)
        buffer.append(cr)
        buffer.append(lf)

        // Epilogue (optional)
        if let epilogue = multipart.epilogue {
            buffer.append(contentsOf: [Byte](epilogue.utf8))
            buffer.append(cr)
            buffer.append(lf)
        }
    }
}

// MARK: - [Byte] convenience

extension [Byte] {
    /// Creates wire bytes from a `Multipart` via its `Binary.Serializable` verb.
    init(_ multipart: RFC_2046.Multipart) {
        self = []
        RFC_2046.Multipart.serialize(multipart, into: &self)
    }
}
