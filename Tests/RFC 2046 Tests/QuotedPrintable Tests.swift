#if Coder
    import ASCII
    import Byte
    import RFC_2045
    import RFC_2046
    import Testing

    @Suite
    struct `Quoted-printable content` {
        @Test
        func `Serialize with quoted-printable encoding applies encoding`() throws {
            let part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(
                    contentType: .textPlainUTF8,
                    contentTransferEncoding: .quotedPrintable
                ),
                content: RFC_2046.BodyPart.Content(
                    [Byte](utf8: "a=b") + [Byte(bitPattern: 0x0F)]
                )
            )

            let string = String(decoding: [Byte](part), as: UTF8.self)

            #expect(string.contains("Content-Transfer-Encoding: quoted-printable"))
            #expect(string.hasSuffix("a=3Db=0F"))
        }

        @Test
        func `Quoted-printable codec round-trips arbitrary bytes`() throws {
            let payload: [Byte] = (UInt8.min...UInt8.max).map(Byte.init(bitPattern:))
            let encoded = RFC_2046.QuotedPrintable.encode(payload)

            #expect(encoded.allSatisfy { $0.bitPattern < 0x80 })
            #expect(RFC_2046.QuotedPrintable.decode(encoded) == payload)
        }

        @Test
        func `Quoted-printable encoded lines stay within 76 characters`() throws {
            let payload = [Byte](repeating: ASCII.Code.equalsSign.byte, count: 100)
            let encoded = RFC_2046.QuotedPrintable.encode(payload)
            let lines = String(decoding: encoded, as: UTF8.self).split(
                separator: "\r\n",
                omittingEmptySubsequences: false
            )

            #expect(lines.allSatisfy { $0.count <= 76 })
        }
    }
#endif
