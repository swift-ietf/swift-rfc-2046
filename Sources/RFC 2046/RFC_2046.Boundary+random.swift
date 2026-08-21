import INCITS_4_1986
import RFC_4648

extension RFC_2046.Boundary {

    public static func random() -> Self {
        var generator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }

    public static func random(
        using generator: inout some RandomNumberGenerator
    ) -> Self {
        var bytes: [Byte] = []
        bytes.reserveCapacity(16)
        for _ in 0..<2 {
            var word = generator.next()
            for _ in 0..<8 {
                bytes.append(Byte(UInt8(truncatingIfNeeded: word)))
                word >>= 8
            }
        }

        let hexCodes: [ASCII.Code] = RFC_4648.Hex.encode(bytes, uppercase: false)
        let hex = String(decoding: hexCodes, as: UTF8.self)

        do throws(RFC_2046.Boundary.Error) {
            return try Self("----Part_\(hex)")
        } catch {

            fatalError("RFC_2046.Boundary.random() produced an invalid boundary: \(error)")
        }
    }
}
