# swift-rfc-2046

Use this package when you need to build, write or read a MIME multipart body, such as an email with alternatives and attachments or a form upload. Start from `RFC_2046.Multipart` to build and write one, with `RFC_2046.BodyPart` for each part and `RFC_2046.Boundary.random()` for a boundary. To read a whole message whose structure you don't know in advance, start from `RFC_2046.Entity`. For the `Content-Type` value itself, use `RFC_2045.ContentType` from swift-rfc-2045. To compose an email without handling MIME parts yourself, use swift-email-standard. For `Codable`, add the `RFC 2046 Foundation Integration` product.

## Laws

- A boundary is 1 to 70 ASCII characters, each a letter, a digit, a space or one of `'()+_,-./:=?`, and it may not end with a space.
- `RFC_2046.Boundary.random()` gives `----Part_` followed by 32 lowercase hex digits. With the same generator state, `RFC_2046.Boundary.random(using:)` gives the same boundary.
- A subtype is stored lowercase, so `ALTERNATIVE` and `alternative` are the same value.
- `RFC_2046.Multipart.contentType` always names the multipart's own boundary. A `boundary` entry in the additional parameters is refused by the initializer and ignored by `contentType`.
- `RFC_2046.BodyPart.Content` holds the decoded bytes. Writing a part applies its base64 or quoted-printable transfer encoding, and reading a part undoes it, so a part round-trips without being encoded twice. Any other transfer encoding passes the bytes through unchanged.
- Content that isn't valid for its base64 or quoted-printable encoding fails `RFC_2046.BodyPart` and `RFC_2046.Multipart` parsing. `RFC_2046.Entity.content` returns nil for it instead.
- Quoted-printable output escapes `=` and every byte outside 0x21 to 0x7E, so spaces and line breaks are escaped too. Soft line breaks keep every line at 76 characters or fewer.
- Part headers are written as `Content-Disposition`, `Content-Type`, `Content-Transfer-Encoding`, then custom headers in order, each ending in CRLF.
- When reading part headers, folded lines are unfolded. A `Content-Type`, `Content-Disposition` or `Content-Transfer-Encoding` value that doesn't parse is dropped and leaves that header nil. A line without a colon fails the whole header block.
- When reading a multipart body, a delimiter line may end in spaces or tabs. A line that starts with the delimiter but goes on with other text is content. The line break before a delimiter belongs to the delimiter, and every other byte, including bare CR and LF, stays in the part.
- `RFC_2046.Multipart.init(binary:boundary:subtype:)` takes the boundary and subtype from its arguments, not from the bytes. An empty preamble or epilogue reads as nil.
- `RFC_2046.Entity.init(binary:)` never fails. Field names match case-insensitively and values keep their raw octets. Lines without a colon are skipped. CRLF and bare LF are both accepted.
- An entity without a `Content-Type` is `text/plain`, except a part of `multipart/digest`, which is `message/rfc822`. A `Content-Type` that doesn't parse also gives `text/plain`.
- An entity is split into parts only when it is `multipart` with a `boundary` parameter, and read as a nested message only when it is `message/rfc822`. Otherwise the body is kept as bytes. Nesting stops after 32 levels, and the rest is kept as bytes.
- With `RFC 2046 Foundation Integration`, a boundary and a subtype encode as strings and are validated again when decoded. Content encodes as an array of byte values. Decoding a multipart applies the same checks as its initializer.
