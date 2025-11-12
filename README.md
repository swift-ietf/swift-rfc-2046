# swift-rfc-2046

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Swift implementation of RFC 2046: Multipurpose Internet Mail Extensions (MIME) Part Two: Media Types

## Overview

This package provides a Swift implementation of MIME multipart media types as defined in [RFC 2046](https://www.rfc-editor.org/rfc/rfc2046.html), with additional support for [RFC 2387](https://www.rfc-editor.org/rfc/rfc2387.html) (multipart/related) and [RFC 7578](https://www.rfc-editor.org/rfc/rfc7578.html) (multipart/form-data).

It enables creating and rendering multipart messages for:
- 📧 Email with text/HTML alternatives and attachments
- 🖼️ HTML emails with inline images
- 📤 HTTP form data with file uploads

## Features

- ✅ **RFC 2046**: Multipart media types (alternative, mixed, digest, parallel)
- ✅ **RFC 2387**: Multipart/related with type/start parameters for compound documents
- ✅ **RFC 7578**: Multipart/form-data for HTTP file uploads with binary support
- ✅ **Binary data support**: Data-based content with automatic encoding (base64, quoted-printable)
- ✅ **Extensible design**: Struct-based subtypes support custom values
- ✅ Body part structure with headers and binary/text content
- ✅ Automatic boundary generation with RFC validation
- ✅ RFC-compliant multipart rendering with proper encoding
- ✅ Content-Disposition escaping for safe field names
- ✅ Convenience constructors for common cases
- ✅ Preamble and epilogue support
- ✅ Swift 6 strict concurrency support
- ✅ Full `Sendable` and `Codable` conformance
- ✅ Empty parts validation and boundary length checks

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-rfc-2046", branch: "main")
]
```

## Usage

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
// "multipart/alternative; boundary=----=_Part_<UUID>"

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

### Multipart/Related (HTML with Inline Images) - RFC 2387

```swift
import RFC_2046

// HTML part that references images via Content-ID
let htmlPart = RFC_2046.BodyPart(
    contentType: .textHTMLUTF8,
    text: """
    <html>
    <body>
        <h1>Welcome!</h1>
        <img src="cid:logo@example.com" alt="Logo">
    </body>
    </html>
    """
)

// Image part with Content-ID (using binary content)
let imagePart = RFC_2046.BodyPart(
    headers: [
        "Content-Type": "image/png",
        "Content-ID": "<logo@example.com>",
        "Content-Transfer-Encoding": "base64"
    ],
    content: imageData  // Binary Data
)

// Create multipart/related
let multipart = try RFC_2046.Multipart.related(
    rootPart: htmlPart,
    relatedParts: [imagePart]
)
```

### Multipart/Form-Data (HTTP File Upload) - RFC 7578

```swift
import RFC_2046
import Foundation

// Load image data
let imageData = try Data(contentsOf: URL(fileURLWithPath: "photo.jpg"))

// Create multipart/form-data for HTTP POST with binary files
let formData = try RFC_2046.Multipart.formData(
    fields: [
        "username": "john_doe",
        "email": "john@example.com"
    ],
    files: [
        try .init(
            fieldName: "avatar",
            filename: "photo.jpg",
            contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
            transferEncoding: .base64,  // Binary data will be base64-encoded
            content: imageData
        ),
        try .init(
            fieldName: "document",
            filename: "resume.pdf",
            contentType: RFC_2045.ContentType(type: "application", subtype: "pdf"),
            transferEncoding: .base64,
            content: try Data(contentsOf: URL(fileURLWithPath: "resume.pdf"))
        )
    ]
)

// Use in HTTP request
let contentType = formData.contentType.headerValue
// "multipart/form-data; boundary=----=_Part_<UUID>"
let body = formData.render()  // Binary data automatically base64-encoded
```

### Custom/Extensible Subtypes

```swift
// The struct-based design allows custom subtypes
let custom = try RFC_2046.Multipart(
    subtype: RFC_2046.Multipart.Subtype(rawValue: "x-custom"),
    parts: [...]
)

// Standard subtypes work as before
let standard = try RFC_2046.Multipart(
    subtype: .alternative,  // ✅ Type-safe static property
    parts: [...]
)
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

// Access part properties
print(part1.contentType?.charset)  // "UTF-8"
print(part2.transferEncoding)      // .quotedPrintable
```

## Type Overview

### `RFC_2046.Multipart`

Represents a complete multipart message.

```swift
public struct Multipart {
    public let subtype: Subtype
    public let parts: [BodyPart]
    public let boundary: String
    public let preamble: String?
    public let epilogue: String?

    public var contentType: RFC_2045.ContentType
    public func render() -> String
}
```

### `RFC_2046.Multipart.Subtype`

Extensible multipart subtype supporting standard and custom values.

```swift
public struct Subtype: RawRepresentable {
    public let rawValue: String

    // RFC 2046 Standard Subtypes
    public static let mixed: Subtype        // Independent parts in sequence
    public static let alternative: Subtype  // Alternative representations
    public static let digest: Subtype       // Collection of messages
    public static let parallel: Subtype     // Parts viewed simultaneously

    // Additional Standard Subtypes
    public static let related: Subtype      // RFC 2387: Compound documents
    public static let formData: Subtype     // RFC 7578: HTTP form uploads

    // Custom subtypes supported
    public init(rawValue: String)
}
```

### `RFC_2046.BodyPart`

A single part within a multipart message.

```swift
public struct BodyPart {
    public let headers: [String: String]
    public let content: String

    public var contentType: RFC_2045.ContentType?
    public var transferEncoding: RFC_2045.ContentTransferEncoding?
}
```

## RFC 2046 Compliance

This implementation follows RFC 2046 specifications:

- ✅ Boundary format: `--boundary` for parts, `--boundary--` for end
- ✅ CRLF line endings in rendered output
- ✅ Proper header/body separation
- ✅ Support for all four multipart subtypes
- ✅ Preamble and epilogue handling

## Example Output

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

## Key Improvements

### Binary Data Support
- **`BodyPart.content`** now uses `Data` instead of `String`
- Properly handles binary files (images, PDFs, etc.)
- Automatic base64 encoding for binary content
- Text convenience initializers for backward compatibility

### RFC 2387 Compliance
- `multipart/related` now supports `type` and `start` parameters
- Auto-detects root Content-Type from first part
- Proper Content-ID referencing for inline images

### RFC 7578 Compliance
- `FormFile` uses `Data` with transfer encoding support
- Proper Content-Disposition escaping (handles quotes in field names)
- Base64 encoding by default for file uploads

### Validation & Safety
- Empty parts validation (precondition check)
- Boundary length validation (1-70 chars per RFC 2046)
- Content-Disposition escaping prevents injection attacks

## Requirements

- Swift 6.0+
- macOS 14+, iOS 17+, tvOS 17+, watchOS 10+

## Related RFCs

### Core MIME Standards
- [RFC 2045](https://www.rfc-editor.org/rfc/rfc2045.html) - MIME Part One: Format of Internet Message Bodies
- [RFC 2046](https://www.rfc-editor.org/rfc/rfc2046.html) - MIME Part Two: Media Types (implemented)
- [RFC 2047](https://www.rfc-editor.org/rfc/rfc2047.html) - MIME Part Three: Header Extensions

### Multipart Extensions
- [RFC 2387](https://www.rfc-editor.org/rfc/rfc2387.html) - The MIME Multipart/Related Content-type (implemented)
- [RFC 7578](https://www.rfc-editor.org/rfc/rfc7578.html) - Returning Values from Forms: multipart/form-data (implemented)

### Related Standards
- [RFC 5322](https://www.rfc-editor.org/rfc/rfc5322.html) - Internet Message Format

## Related Packages

- [swift-rfc-2045](https://github.com/coenttb/swift-rfc-2045) - MIME fundamentals (Content-Type, Content-Transfer-Encoding)
- [swift-rfc-5322](https://github.com/coenttb/swift-rfc-5322) - Internet Message Format

## License

Licensed under Apache 2.0.

## Contributing

Contributions welcome! Please ensure:
- All tests pass
- Code follows existing style
- RFC 2046 compliance maintained
