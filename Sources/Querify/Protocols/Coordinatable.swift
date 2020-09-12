//
//  Coordinator.swift
//  UTL
//
//  Created by Artem Shvetsov on 2/21/20.
//  Copyright © 2020 Artem Shvetsov. All rights reserved.
//

import UIKit

// MARK: - Coordinatable

public typealias ControllerCompletion = (_ controller: UIViewController?) -> Void

public protocol Coordinatable {
    
    associatedtype CoordinatorId
    associatedtype CoordinatorPath
    associatedtype CoordinatorOwner

    init(identifier: CoordinatorId?, path: CoordinatorPath, owner: CoordinatorOwner)

    func hasNext() -> Bool
    func next(with query: String?, animated flag: Bool, _ completion: ControllerCompletion?)
    func back(animated flag: Bool)
    func attach(_ path: CoordinatorPath)

    func present(with query: String?, animated flag: Bool, _ completion: ControllerCompletion?)
    func dismiss(animated flag: Bool)

    func complete(with query: String?)
}

// MARK: - CoordinatorHandling

public protocol CoordinatorHandling {
    
    func didCompletePath(coordinator: Coordinator, with query: String?)
}

public extension CoordinatorHandling {
    
    func didCompletePath(coordinator: Coordinator, with query: String?) {
    }
}
