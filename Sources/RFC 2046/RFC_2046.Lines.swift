import INCITS_4_1986

extension RFC_2046 {

    static func lines(of bytes: [Byte]) -> [ArraySlice<Byte>] {
        let cr = ASCII.Code.cr.byte
        let lf = ASCII.Code.lf.byte

        var result: [ArraySlice<Byte>] = []
        var lineStart = bytes.startIndex
        var index = bytes.startIndex

        while index < bytes.endIndex {
            let byte = bytes[index]
            if byte == cr {
                result.append(bytes[lineStart..<index])
                let next = bytes.index(after: index)
                index =
                    next < bytes.endIndex && bytes[next] == lf
                    ? bytes.index(after: next)
                    : next
                lineStart = index
            } else if byte == lf {
                result.append(bytes[lineStart..<index])
                index = bytes.index(after: index)
                lineStart = index
            } else {
                index = bytes.index(after: index)
            }
        }

        if lineStart < bytes.endIndex {
            result.append(bytes[lineStart..<bytes.endIndex])
        }
        return result
    }
}
