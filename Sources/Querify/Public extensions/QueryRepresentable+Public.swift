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
}
