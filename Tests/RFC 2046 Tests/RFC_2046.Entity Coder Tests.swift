#if Coder
    import Byte
    import RFC_2045
    import RFC_2046
    import Testing

    extension RFC_2046.Entity {

        @Suite
        struct Test {

            @Suite
            struct Unit {}

            @Suite
            struct `Edge Case` {}

            static func entity(_ lines: [String], separator: String = "\r\n") -> RFC_2046.Entity {
                RFC_2046.Entity(binary: [Byte](utf8: lines.joined(separator: separator)))
            }

            static func text(_ bytes: [Byte]?) -> String? {
                bytes.map { String(decoding: $0.map(\.bitPattern), as: UTF8.self) }
            }

            static func parts(_ entity: RFC_2046.Entity) -> [RFC_2046.Entity] {
                switch entity.body {
                case .multipart(let multipart): multipart.parts
                case .discrete, .message: []
                }
            }
        }
    }

    extension RFC_2046.Entity.Test.Unit {

        @Test
        func `a plain message has its fields and a text body`() {
            let entity = RFC_2046.Entity.Test.entity([
                "From: a@example.com",
                "Subject: Invoice",
                " for October",
                "",
                "Hello",
            ])

            #expect(RFC_2046.Entity.Test.text(entity["subject"]) == "Invoice for October")
            #expect(RFC_2046.Entity.Test.text(entity["FROM"]) == "a@example.com")
            #expect(entity.contentType.type == "text")
            #expect(entity.contentType.subtype == "plain")
            #expect(RFC_2046.Entity.Test.text(entity.content) == "Hello")
        }

        @Test
        func `a mixed message holds a nested alternative and a base64 attachment`() {
            let entity = RFC_2046.Entity.Test.entity([
                "Content-Type: multipart/mixed; boundary=\"outer\"",
                "",
                "preamble",
                "--outer",
                "Content-Type: multipart/alternative; boundary=inner",
                "",
                "--inner",
                "Content-Type: text/plain; charset=utf-8",
                "",
                "Plain body",
                "--inner",
                "Content-Type: text/html; charset=utf-8",
                "",
                "<p>HTML body</p>",
                "--inner--",
                "--outer",
                "Content-Type: application/pdf; name=invoice.pdf",
                "Content-Transfer-Encoding: base64",
                "Content-Disposition: attachment; filename=invoice.pdf",
                "",
                "JVBERi0x",
                "LjQK",
                "--outer--",
                "",
            ])

            let parts = RFC_2046.Entity.Test.parts(entity)
            let alternatives = parts.first.map(RFC_2046.Entity.Test.parts) ?? []

            #expect(parts.count == 2)
            #expect(alternatives.count == 2)
            #expect(RFC_2046.Entity.Test.text(alternatives.first?.content) == "Plain body")
            #expect(alternatives.last?.contentType.subtype == "html")
            #expect(parts.last?.contentType.subtype == "pdf")
            #expect(RFC_2046.Entity.Test.text(parts.last?.content) == "%PDF-1.4\n")
        }

        @Test
        func `a forwarded message parses as an inner entity`() {
            let entity = RFC_2046.Entity.Test.entity([
                "Content-Type: message/rfc822",
                "",
                "Subject: Inner",
                "",
                "Inner body",
            ])

            switch entity.body {
            case .message(let inner):
                #expect(RFC_2046.Entity.Test.text(inner["Subject"]) == "Inner")
                #expect(RFC_2046.Entity.Test.text(inner.content) == "Inner body")
            case .discrete, .multipart:
                Issue.record("expected an inner message")
            }
        }

        @Test
        func `quoted printable content decodes`() {
            let entity = RFC_2046.Entity.Test.entity([
                "Content-Type: text/plain; charset=iso-8859-1",
                "Content-Transfer-Encoding: quoted-printable",
                "",
                "Caf=E9 and a soft=",
                " break",
            ])

            #expect(entity.content == [Byte](utf8: "Caf") + [Byte(bitPattern: 0xE9)] + [Byte](utf8: " and a soft break"))
        }

        @Test
        func `digest parts default to message rfc822`() {
            let entity = RFC_2046.Entity.Test.entity([
                "Content-Type: multipart/digest; boundary=d",
                "",
                "--d",
                "",
                "Subject: First",
                "",
                "One",
                "--d--",
            ])

            #expect(RFC_2046.Entity.Test.parts(entity).first?.contentType.type == "message")
        }
    }

    extension RFC_2046.Entity.Test.`Edge Case` {

        @Test
        func `UTF-8 octets in a header value are kept`() {
            let entity = RFC_2046.Entity.Test.entity(["Subject: Factuur café", "", "x"])

            #expect(RFC_2046.Entity.Test.text(entity["Subject"]) == "Factuur café")
        }

        @Test
        func `an invalid content type falls back to text plain`() {
            let entity = RFC_2046.Entity.Test.entity(["Content-Type: ???", "", "x"])

            #expect(entity.contentType.type == "text")
            #expect(entity.contentType.subtype == "plain")
        }

        @Test
        func `a multipart type without a boundary stays discrete`() {
            let entity = RFC_2046.Entity.Test.entity(["Content-Type: multipart/mixed", "", "--x", "", "y"])

            #expect(RFC_2046.Entity.Test.parts(entity).isEmpty)
            #expect(entity.content != nil)
        }

        @Test
        func `bare line feeds are accepted`() {
            let entity = RFC_2046.Entity.Test.entity(["Subject: LF", "", "Body"], separator: "\n")

            #expect(RFC_2046.Entity.Test.text(entity["Subject"]) == "LF")
            #expect(RFC_2046.Entity.Test.text(entity.content) == "Body")
        }

        @Test
        func `a line without a colon is skipped`() {
            let entity = RFC_2046.Entity.Test.entity(["From someone Mon Oct 14", "Subject: Kept", "", "x"])

            #expect(entity.fields.count == 1)
            #expect(RFC_2046.Entity.Test.text(entity["Subject"]) == "Kept")
        }

        @Test
        func `deep nesting stops at the depth limit`() {
            let lines = Array(repeating: ["Content-Type: message/rfc822", ""], count: 40).flatMap { $0 } + ["end"]
            var entity = RFC_2046.Entity.Test.entity(lines)
            var depth = 0
            while case .message(let inner) = entity.body {
                entity = inner
                depth += 1
            }

            #expect(depth == 32)
        }

        @Test
        func `invalid base64 content is absent`() {
            let entity = RFC_2046.Entity.Test.entity([
                "Content-Transfer-Encoding: base64",
                "",
                "é",
            ])

            #expect(entity.content == nil)
        }

        @Test
        func `an empty input has no fields and an empty body`() {
            let entity = RFC_2046.Entity(binary: [Byte]())

            #expect(entity.fields.isEmpty)
            #expect(entity.body == .discrete([]))
        }
    }
#endif
