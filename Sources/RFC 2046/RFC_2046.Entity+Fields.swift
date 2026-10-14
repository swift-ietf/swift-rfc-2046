public import Byte
public import RFC_2045

extension RFC_2046.Entity {

    public subscript(name: String) -> [Byte]? {
        fields.first { $0.name.lowercased() == name.lowercased() }?.value
    }

    public var transferEncoding: RFC_2045.ContentTransferEncoding? {
        self["Content-Transfer-Encoding"].flatMap { value in
            do throws(RFC_2045.ContentTransferEncoding.Error) {
                return try RFC_2045.ContentTransferEncoding(ascii: value)
            } catch {
                return nil
            }
        }
    }
}
