//
//  QueryRepresentable+Public.swift
//  
//
//  Created by Artem Shvetsov on 12.09.2020.
//

import Foundation

public extension QueryRepresentable {
    
    func query() -> Query? {
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

    static func from(query: Query?) -> Self? {
        let query = query?.removingPercentEncoding
        
        guard
            let dict = query?.queryDictionary else {
                return nil
        }

        return Self.decode(from: dict)
    }

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
