public import Binary_Serializable_Primitives
import INCITS_4_1986
public import RFC_2045

extension RFC_2046 {

    public struct Multipart: Hashable, Sendable, Codable {

        public let subtype: Subtype

        public let parts: [BodyPart]

        public let boundary: Boundary

        public let preamble: String?

        public let epilogue: String?

        public let additionalParameters: [RFC_2045.Parameter.Name: String]

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

extension RFC_2046.Multipart {

    static func isRepresentableParameterValue(_ value: String) -> Bool {
        value.utf8.allSatisfy { byte in
            (0x20...0x7E).contains(byte)
                && byte != UInt8(ascii: "\"")
                && byte != UInt8(ascii: "\\")
        }
    }

    public var contentType: RFC_2045.ContentType {
        var parameters: [RFC_2045.Parameter.Name: String] = [.boundary: boundary.rawValue]

        parameters.merge(additionalParameters) { _, new in new }

        return RFC_2045.ContentType(
            __unchecked: (),
            type: "multipart",
            subtype: subtype.rawValue,
            parameters: parameters
        )
    }
}

extension RFC_2046.Multipart: Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ multipart: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        let hyphen = ASCII.Code.hyphen.byte
        let cr = ASCII.Code.cr.byte
        let lf = ASCII.Code.lf.byte

        if let preamble = multipart.preamble {
            buffer.append(contentsOf: [Byte](preamble.utf8))
            buffer.append(cr)
            buffer.append(lf)
            buffer.append(cr)
            buffer.append(lf)
        }

        for part in multipart.parts {
            buffer.append(hyphen)
            buffer.append(hyphen)

            RFC_2046.Boundary.serialize(multipart.boundary, into: &buffer)
            buffer.append(cr)
            buffer.append(lf)

            RFC_2046.BodyPart.serialize(part, into: &buffer)
            buffer.append(cr)
            buffer.append(lf)
        }

        buffer.append(hyphen)
        buffer.append(hyphen)
        RFC_2046.Boundary.serialize(multipart.boundary, into: &buffer)
        buffer.append(hyphen)
        buffer.append(hyphen)
        buffer.append(cr)
        buffer.append(lf)

        if let epilogue = multipart.epilogue {
            buffer.append(contentsOf: [Byte](epilogue.utf8))
            buffer.append(cr)
            buffer.append(lf)
        }
    }
}

extension [Byte] {

    init(_ multipart: RFC_2046.Multipart) {
        self = []
        RFC_2046.Multipart.serialize(multipart, into: &self)
    }
}
