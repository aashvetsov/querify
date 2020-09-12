//
//  Extensions.swift
//  
//
//  Created by Artem Shvetsov on 12.09.2020.
//

import Foundation

public extension QueryRepresentable {
    
    func query() -> String? {
        guard let json = JSON() else { return nil }

        var urlComponents = URLComponents()
        urlComponents.setQueryItems(with: json)
        
        guard
            let queryWithPercents = urlComponents.url?.absoluteString else {
                return nil
        }
        
        let query = queryWithPercents.removingPercentEncoding
        
        return query
    }

    static func from(query: String?) -> Self? {
        let query = query?.removingPercentEncoding
        
        guard
            let dict = query?.queryDictionary else {
                return nil
        }

        return Self.decode(from: dict)
    }
}

public extension String {
    
    func hasChanges(comparing with: String?) -> Bool {
        guard
            let target = with?.queryDictionary,
            let source = queryDictionary else {
                return true
        }

        let sourceDict = NSDictionary(dictionary: source)
        let targetDict = NSDictionary(dictionary: target)

        return !sourceDict.isEqual(targetDict)
    }
}

public extension Mergable {
    
    func merge(with: Self) -> Self? {
        guard
            var selfDict = dictionary(),
            let withDict = with.dictionary() else {
                return nil
        }

        selfDict.merge(withDict, uniquingKeysWith: { (_, new) in new })
        guard
            let final = try? JSONSerialization.data(withJSONObject: selfDict) else {
                return nil
        }
        
        return try? JSONDecoder().decode(Self.self, from: final)
    }
    
    func dictionary() -> [String: Any]? {
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
