@_exported import RFC_2045

/// RFC 2046: Multipurpose Internet Mail Extensions (MIME) Part Two: Media Types
///
/// This module implements multipart media types and body part structures defined
/// in RFC 2046.
///
/// RFC 2046 defines:
/// - Multipart media types (alternative, mixed, digest, parallel)
/// - Boundary delimiters for separating body parts
/// - Body part structure (headers + content)
/// - Preamble and epilogue
///
/// ## Usage Example
///
/// ```swift
/// // Create a multipart/alternative message (text + HTML)
/// let textPart = RFC_2046.BodyPart(
///     headers: [
///         "Content-Type": "text/plain; charset=UTF-8",
///         "Content-Transfer-Encoding": "7bit"
///     ],
///     content: "Hello, World!"
/// )
///
/// let htmlPart = RFC_2046.BodyPart(
///     headers: [
///         "Content-Type": "text/html; charset=UTF-8",
///         "Content-Transfer-Encoding": "7bit"
///     ],
///     content: "<h1>Hello, World!</h1>"
/// )
///
/// let multipart = RFC_2046.Multipart(
///     subtype: .alternative,
///     parts: [textPart, htmlPart]
/// )
///
/// // Render the complete multipart body
/// let body = multipart.render()
/// ```
///
/// ## RFC Reference
///
/// From RFC 2046:
///
/// > The multipart media type is defined to allow the grouping of
/// > multiple entities into a single message body.
///
/// This module re-exports RFC 2045 (MIME Part 1) for convenience.
public enum RFC_2046 {
    /// Errors that can occur when working with multipart messages
    public enum MultipartError: Error, Hashable, Sendable {
        case invalidBoundary(String)
        case boundaryTooLong(String, length: Int)
        case missingBoundary
        case emptyParts
        case invalidSubtype(String)
    }
}
