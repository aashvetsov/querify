//
//  Extensions.swift
//  
//
//  Created by Artem Shvetsov on 12.09.2020.
//

import Foundation

public typealias Query = String

public extension Query {
    
    func hasChanges(comparing with: Query?) -> Bool {
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
