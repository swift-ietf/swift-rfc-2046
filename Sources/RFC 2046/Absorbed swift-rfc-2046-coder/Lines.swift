#if Coder
    import ASCII
    import Byte

    enum Lines {

        static func split(_ bytes: [Byte]) -> [ArraySlice<Byte>] {
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

        static func firstIndex(of pattern: [Byte], in bytes: [Byte]) -> Int? {
            guard !pattern.isEmpty, bytes.count >= pattern.count else { return nil }

            var start = bytes.startIndex
            let limit = bytes.endIndex - pattern.count

            while start <= limit {
                if bytes[start..<(start + pattern.count)].elementsEqual(pattern) {
                    return start
                }
                start += 1
            }
            return nil
        }
    }
#endif
