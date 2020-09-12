//
//  File.swift
//  
//
//  Created by Artem Shvetsov on 12.09.2020.
//

import Foundation

public protocol QueryRepresentable: Codable {
    
    func query() -> String?
    static func from(query: String?) -> Self?
}

// MARK: - Private

extension QueryRepresentable {
    
    func JSON() -> [String: Any]? {
        let encoder = JSONEncoder()
        
        guard
            let data = try? encoder.encode(self),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
        }
        
        return dict
    }
    
    static func decode(from dict: [String: Any]) -> Self? {
        do {
            let data = try JSONSerialization.data(withJSONObject: dict)
            return try JSONDecoder().decode(Self.self, from: data)
        } catch {
            return nil
        }
    }
}

extension String {
    
    enum QueryParamType: String {
        case bool
        case int
        case double
        case string
        case dictionary
    }
    
    var typedQueryValue: Any? {
        switch queryParamType {
        case .bool: return Bool(self)
        case .int: return Int(self)
        case .double: return Double(self)
        case .string:
            if (first == "'" && last == "'") || (first == "\"" && last == "\"") {
                let start = index(startIndex, offsetBy: 1)
                let end = index(endIndex, offsetBy: -1)
                let range = start..<end
                return self[range].removingPercentEncoding
            }
            return removingPercentEncoding
        case .dictionary:
            return dictionary()
        }
    }
    
    var queryParamType: QueryParamType {
        let isBool = lowercased() == "true" || lowercased() == "false"
        if isBool {
            return .bool
        }
        
        let isInt = (nil != Int(self)) && hasDigitsAndSignOnly
        if isInt {
            return .int
        }
        
        let isDouble = nil != Double(self) && hasDigitsSignAndSeparatorOnly
        if isDouble {
            return .double
        }
        
        let isDictionary = nil != dictionary()
        if isDictionary {
            return .dictionary
        }
        
        return .string
    }
    
    func dictionary() -> [String: Any]? {
        if let data = data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                return nil
            }
        }
        return nil
    }

    var queryDictionary: [String: Any]? {
        return components(separatedBy: "&").map({
            $0.components(separatedBy: "=")
        }).reduce(into: [String: Any]()) { dict, pair in
            guard
                pair.count >= 2,
                let key = pair.first?.replacingOccurrences(of: "?", with: "") else {
                return
            }
            var stringValue: String?
            if pair.count == 2 {
                stringValue = pair.last
            } else if pair.count > 2 {
                let lastIndex = pair.count
                stringValue = pair[1..<lastIndex].joined(separator: "=")
            }
            let value = stringValue?.replacingOccurrences(of: "\n", with: "").typedQueryValue
            dict[key] = value
        }
    }
}

extension URLComponents {
    
    mutating func setQueryItems(with parameters: [String: Any]) {
        queryItems = parameters.map {
            guard
                let value = $0.value as? [String: Any] else {
                    return URLQueryItem(name: $0.key, value: "\($0.value)")
            }
            return URLQueryItem(name: $0.key, value: value.jsonString)
        }
    }
}

fileprivate extension Dictionary {
    
    var jsonString: String? {
        let jsonData = try! JSONSerialization.data(withJSONObject: self, options: [])
        let decoded = String(data: jsonData, encoding: .utf8)!
        return decoded
    }
}

fileprivate extension String {
    
    var hasDigitsAndSignOnly: Bool {
        guard count > 0 else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-"]
        return Set(self).isSubset(of: nums)
    }

    var hasDigitsSignAndSeparatorOnly: Bool {
        guard count > 0 else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", ",", "-"]
        return Set(self).isSubset(of: nums)
    }
}
