# swift-rfc-2046

Domain model for RFC 2046, MIME Part Two (Media Types), restricted to the multipart family: `RFC_2046.Multipart` with its `Multipart.Subtype` and `RFC_2046.Boundary`, and `RFC_2046.BodyPart` with `BodyPart.Headers` (`RFC_2183.ContentDisposition`, `RFC_2045.ContentType`, `RFC_2045.ContentTransferEncoding`, custom `RFC_5322.Header`s) and byte `BodyPart.Content`. `Boundary` and `Multipart.Subtype` validate on construction through `init(_:)`, `Boundary.random()` mints RFC-valid boundaries, and `Multipart.contentType` builds the structural `multipart/<subtype>; boundary=...` content type; the `RFC 2046 Foundation Integration` product bridges every type to `Codable`. Wire parsing and serialization (`ASCII.Parseable`, `ASCII.Serializable`, `Binary.Serializable`, the nested `Coder` types, the quoted-printable codec and every text form) live in [swift-rfc-2046-coder](https://github.com/swift-ietf/swift-rfc-2046-coder).

```swift
import RFC_2045
import RFC_2046

let boundary = try RFC_2046.Boundary("----=_Part_12345")
let multipart = try RFC_2046.Multipart(
    subtype: .alternative,
    parts: [
        RFC_2046.BodyPart(contentType: .textPlainUTF8, text: "Hello, World!"),
        RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<h1>Hello, World!</h1>"),
    ],
    boundary: boundary
)
multipart.contentType.subtype                        // "alternative"
multipart.contentType.parameters[.boundary]          // "----=_Part_12345"
multipart.parts.first?.transferEncoding              // .eightBit
```

```swift
import Byte
import RFC_2046
import RFC_2046_Coder

let coder = RFC_2046.Multipart.coder(boundary: boundary, subtype: .alternative)
var wire: [Byte] = []
try coder.serialize(multipart, into: &wire)

var input = wire[...]
let parsed = try coder.parse(&input)
parsed.parts.count                                   // 2
```
