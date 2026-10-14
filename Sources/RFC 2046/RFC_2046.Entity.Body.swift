public import Byte

extension RFC_2046.Entity {

    public indirect enum Body: Sendable, Hashable {

        case discrete([Byte])

        case multipart(RFC_2046.Entity.Body.Multipart)

        case message(RFC_2046.Entity)
    }
}
