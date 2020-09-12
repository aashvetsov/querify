//
//  CommonProtocols.swift
//  UTL
//
//  Created by Artem Shvetsov on 3/8/20.
//  Copyright © 2020 Artem Shvetsov. All rights reserved.
//

import Foundation

public protocol Mergable: Codable {
    
    func merge(with: Self) -> Self?
    
    func dictionary() -> [String: Any]?

    static func decode(from dict: [String: Any]) -> Self?
}
