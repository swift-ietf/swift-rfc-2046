extension RFC_2046.BodyPart {

    public enum Error: Swift.Error, Sendable, Equatable {

        case invalidHeaders(_ reason: String)

        case invalidTransferEncodedContent(_ reason: String)
    }
}
