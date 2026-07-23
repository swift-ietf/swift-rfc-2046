# Swift RFC 2046

[![CI](https://github.com/swift-ietf/swift-rfc-2046/workflows/CI/badge.svg)](https://github.com/swift-ietf/swift-rfc-2046/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Swift implementation of RFC 2046: Multipurpose Internet Mail Extensions (MIME) Part Two: Media Types

## Overview

This package provides a Swift implementation of MIME multipart media types as defined in [RFC 2046](https://www.rfc-editor.org/rfc/rfc2046.html). It enables creating and rendering multipart messages for email with text/HTML alternatives and attachments.

## Features

- **Multipart Media Types**: Support for alternative, mixed, digest, and parallel subtypes
- **Binary Data Support**: Data-based content with automatic encoding (base64, quoted-printable)
- **Extensible Design**: Struct-based subtypes support custom values
- **Body Part Structure**: Headers and binary/text content
- **Automatic Boundary Generation**: RFC-compliant boundary generation with validation
- **Multipart Rendering**: RFC-compliant rendering with proper encoding
- **Convenience Constructors**: Common cases like alternative and mixed
- **Preamble and Epilogue**: Support for preamble and epilogue text
- **Swift 6 Support**: Strict concurrency support with full `Sendable` and `Codable` conformance

## Installation

Add swift-rfc-2046 to your package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/swift-ietf/swift-rfc-2046.git", from: "0.3.5")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RFC 2046", package: "swift-rfc-2046")
    ]
)
```

## Quick Start

### Multipart/Alternative (Text + HTML)

```swift
import RFC_2046

// Create multipart/alternative message
let multipart = try RFC_2046.Multipart.alternative(
    textContent: "Hello, World!",
    htmlContent: "<h1>Hello, World!</h1>"
)

// Get Content-Type header
let contentType = multipart.contentType.headerValue
// "multipart/alternative; boundary=----Part_a3f5d8b2c1e4f6a7b9d0c2e5f8a1b3d4"

// Render the complete multipart body
let body = multipart.render()
```

### Custom Multipart Messages

```swift
// Create body parts
let textPart = RFC_2046.BodyPart(
    contentType: .textPlainUTF8,
    transferEncoding: .sevenBit,
    text: "Plain text version"
)

let htmlPart = RFC_2046.BodyPart(
    contentType: .textHTMLUTF8,
    transferEncoding: .sevenBit,
    text: "<p>HTML version</p>"
)

// Create multipart message
let multipart = try RFC_2046.Multipart(
    subtype: .alternative,
    parts: [textPart, htmlPart],
    boundary: "my-custom-boundary"
)
```

### Multipart/Mixed (With Attachments)

```swift
// Main content part
let contentPart = RFC_2046.BodyPart(
    contentType: .textHTMLUTF8,
    text: "<h1>Email with attachment</h1>"
)

// Attachment part (simplified example)
let attachmentPart = RFC_2046.BodyPart(
    headers: [
        "Content-Type": "application/pdf; name=\"document.pdf\"",
        "Content-Transfer-Encoding": "base64",
        "Content-Disposition": "attachment; filename=\"document.pdf\""
    ],
    text: "<base64-encoded-pdf-content>"
)

// Create multipart/mixed
let multipart = try RFC_2046.Multipart.mixed(
    parts: [contentPart, attachmentPart]
)
```

## Usage

### Type Overview

#### `RFC_2046.Multipart`

Represents a complete multipart message.

```swift
public struct Multipart {
    public let subtype: Subtype
    public let parts: [BodyPart]
    public let boundary: String
    public let preamble: String?
    public let epilogue: String?
    public let additionalParameters: [String: String]

    public var contentType: RFC_2045.ContentType
    public func render() -> String
}
```

#### `RFC_2046.Multipart.Subtype`

Extensible multipart subtype supporting standard and custom values.

```swift
public struct Subtype: RawRepresentable {
    public let rawValue: String

    // RFC 2046 Standard Subtypes
    public static let mixed: Subtype        // Independent parts in sequence
    public static let alternative: Subtype  // Alternative representations
    public static let digest: Subtype       // Collection of messages
    public static let parallel: Subtype     // Parts viewed simultaneously

    // Custom subtypes supported
    public init(rawValue: String)
}
```

#### `RFC_2046.BodyPart`

A single part within a multipart message.

```swift
public struct BodyPart {
    public let headers: [String: String]
    public let content: Data

    public var contentType: RFC_2045.ContentType?
    public var transferEncoding: RFC_2045.ContentTransferEncoding?
    public var textContent: String?
}
```

### Body Parts

```swift
// Create with Content-Type
let part1 = RFC_2046.BodyPart(
    contentType: .textPlainUTF8,
    text: "Hello!"
)

// Create with custom headers
let part2 = RFC_2046.BodyPart(
    headers: [
        "Content-Type": "text/html; charset=UTF-8",
        "Content-Transfer-Encoding": "quoted-printable"
    ],
    text: "<h1>Hello!</h1>"
)

// Create with binary content
let part3 = RFC_2046.BodyPart(
    contentType: RFC_2045.ContentType(type: "image", subtype: "png"),
    transferEncoding: .base64,
    content: imageData
)

// Access part properties
print(part1.contentType?.charset)  // Charset?
print(part2.transferEncoding)      // ContentTransferEncoding?
```

### Custom Subtypes

```swift
// The struct-based design allows custom subtypes
let custom = try RFC_2046.Multipart(
    subtype: RFC_2046.Multipart.Subtype(rawValue: "x-custom"),
    parts: [textPart, htmlPart]
)

// Standard subtypes work as before
let standard = try RFC_2046.Multipart(
    subtype: .alternative,  // Type-safe static property
    parts: [textPart, htmlPart]
)
```

### Example Output

```
This is a multipart message (preamble)

------=_Part_12345
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 7bit

Hello, World!
------=_Part_12345
Content-Type: text/html; charset=UTF-8
Content-Transfer-Encoding: 7bit

<h1>Hello, World!</h1>
------=_Part_12345--
```

## RFC 2046 Compliance

This implementation follows RFC 2046 specifications:

- Boundary format: `--boundary` for parts, `--boundary--` for end
- CRLF line endings in rendered output
- Proper header/body separation
- Support for all four multipart subtypes (mixed, alternative, digest, parallel)
- Preamble and epilogue handling
- Boundary length validation (1-70 chars)
- Empty parts validation

## Requirements

- Swift 6.0+
- macOS 14.0+ / iOS 17.0+ / tvOS 17.0+ / watchOS 10.0+

## Related Packages

### Dependencies
- [swift-rfc-2045](https://github.com/swift-ietf/swift-rfc-2045) - MIME fundamentals (Content-Type, Content-Transfer-Encoding)

### Related
- [swift-rfc-7578](https://github.com/swift-ietf/swift-rfc-7578) - Returning Values from Forms: multipart/form-data
- [swift-rfc-2388](https://github.com/swift-ietf/swift-rfc-2388) - Returning Values from Forms: multipart/form-data encoding

## License

This library is released under the Apache License 2.0. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
