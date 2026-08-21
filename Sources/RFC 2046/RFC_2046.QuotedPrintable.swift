import INCITS_4_1986

extension RFC_2046 {

    enum QuotedPrintable {

        static func encode(_ bytes: [Byte]) -> [Byte] {
            let equals = ASCII.Code.equalsSign.byte
            let cr = ASCII.Code.cr.byte
            let lf = ASCII.Code.lf.byte
            let hexDigits: [Byte] = [Byte]("0123456789ABCDEF".utf8)

            var output: [Byte] = []
            output.reserveCapacity(bytes.count + bytes.count / 3)
            var lineLength = 0

            for byte in bytes {
                let isLiteral = (33...126).contains(byte.underlying) && byte != equals
                let tokenLength = isLiteral ? 1 : 3

                if lineLength + tokenLength > 75 {
                    output.append(equals)
                    output.append(cr)
                    output.append(lf)
                    lineLength = 0
                }

                if isLiteral {
                    output.append(byte)
                } else {
                    output.append(equals)
                    output.append(hexDigits[Int(byte.underlying >> 4)])
                    output.append(hexDigits[Int(byte.underlying & 0x0F)])
                }
                lineLength += tokenLength
            }
            return output
        }

        static func decode(_ bytes: [Byte]) -> [Byte]? {
            let equals = ASCII.Code.equalsSign.byte
            let cr = ASCII.Code.cr.byte
            let lf = ASCII.Code.lf.byte

            func hexValue(_ byte: Byte) -> UInt8? {
                switch byte.underlying {
                case 0x30...0x39: return byte.underlying - 0x30
                case 0x41...0x46: return byte.underlying - 0x41 + 10
                case 0x61...0x66: return byte.underlying - 0x61 + 10
                default: return nil
                }
            }

            var output: [Byte] = []
            output.reserveCapacity(bytes.count)
            var index = bytes.startIndex

            while index < bytes.endIndex {
                let byte = bytes[index]
                if byte == equals {
                    let next = index + 1

                    if next < bytes.endIndex, bytes[next] == cr,
                        next + 1 < bytes.endIndex, bytes[next + 1] == lf
                    {
                        index = next + 2
                        continue
                    }
                    if next < bytes.endIndex, bytes[next] == lf {
                        index = next + 1
                        continue
                    }

                    guard next + 1 < bytes.endIndex,
                        let high = hexValue(bytes[next]),
                        let low = hexValue(bytes[next + 1])
                    else { return nil }
                    output.append(Byte((high << 4) | low))
                    index = next + 2
                } else {
                    output.append(byte)
                    index += 1
                }
            }
            return output
        }
    }
}
