public import Byte

extension RFC_2046.Entity {

    public struct Field: Sendable, Hashable {

        public let name: String

        public let value: [Byte]

        public init(name: String, value: [Byte]) {
            self.name = name
            self.value = value
        }
    }
}
