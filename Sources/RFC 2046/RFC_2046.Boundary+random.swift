extension RFC_2046.Boundary {

    public static func random() -> Self {
        var generator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }

    public static func random(
        using generator: inout some RandomNumberGenerator
    ) -> Self {
        let digits: [Character] = [
            "0", "1", "2", "3", "4", "5", "6", "7",
            "8", "9", "a", "b", "c", "d", "e", "f",
        ]

        var hex = ""
        hex.reserveCapacity(32)
        for _ in 0..<2 {
            var word = generator.next()
            for _ in 0..<8 {
                let octet = UInt8(truncatingIfNeeded: word)
                hex.append(digits[Int(octet >> 4)])
                hex.append(digits[Int(octet & 0x0F)])
                word >>= 8
            }
        }

        do throws(RFC_2046.Boundary.Error) {
            return try Self("----Part_\(hex)")
        } catch {
            fatalError("RFC_2046.Boundary.random() produced an invalid boundary: \(error)")
        }
    }
}
