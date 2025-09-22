import Foundation
import RealmSwift

extension AnyRealmValue {
    init(fromAny value: Any) {
        switch value {
        case let v as String: self = .string(v)
        case let v as Int: self = .int(v)
        case let v as Double: self = .double(v)
        case let v as Float: self = .float(v)
        case let v as Bool: self = .bool(v)
        case let v as Date: self = .date(v)
        case let v as Data: self = .data(v)
        case is NSNull: self = .none
        case let v as [String: Any]: self = .dictionary(Self.convertToMap(v))
        default:
            self = .string(String(describing: value))
        }
    }

    var toAny: Any {
        switch self {
        case .string(let v): return v
        case .int(let v): return v
        case .double(let v): return v
        case .float(let v): return v
        case .bool(let v): return v
        case .date(let v): return v
        case .data(let v): return v
        case .none: return NSNull()
        case .dictionary(let dict): return Dictionary(uniqueKeysWithValues: dict.map { ($0.key, $0.value.toAny) })
        @unknown default: return NSNull()
        }
    }

    private static func convertToMap(_ dict: [String: Any]) -> Map<String, AnyRealmValue> {
        let map = Map<String, AnyRealmValue>()
        for (key, value) in dict {
            map[key] = AnyRealmValue(fromAny: value)
        }
        return map
    }
}
