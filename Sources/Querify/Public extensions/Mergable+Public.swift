//
//  QueryRepresentable+Puiblic.swift
//  
//
//  Created by Artem Shvetsov on 12.09.2020.
//

import Foundation

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
