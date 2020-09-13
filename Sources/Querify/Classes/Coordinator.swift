//
//  Coordinator.swift
//  UTL
//
//  Created by Artem Shvetsov on 3/1/20.
//  Copyright © 2020 Artem Shvetsov. All rights reserved.
//

import UIKit

public typealias CoordinatorOwner = UIViewController & CoordinatorHandling
public typealias CoordinatorId = String
public typealias CoordinatorPath = [CoordinatorStep]

public class CoordinatorStep {
    
    let animation: NavigationAnimation
    let controller: UIViewController.Type
    
    required public init(animation: NavigationAnimation, controller: UIViewController.Type) {
        self.animation = animation
        self.controller = controller
    }
}

public class Coordinator {

    // MARK: - Public

    public let identifier: CoordinatorId?
    public var owner: CoordinatorOwner?

    required public init(identifier: CoordinatorId?,
                         path: CoordinatorPath,
                         owner: CoordinatorOwner? = nil) {
        self.owner = owner
        self.path = path
        self.identifier = identifier
        navigator = UINavigationController()
        navigator?.isNavigationBarHidden = true
        if #available(iOS 13.0, *) {
            navigator?.isModalInPresentation = true
        }
        guard
            let initialController = controller(at: 0) else {
                return
        }
        navigator?.viewControllers = [initialController]
        initialController.coordinator = self
    }
    
    required public init(identifier: CoordinatorId?,
                         path: CoordinatorPath,
                         owner: CoordinatorOwner? = nil,
                         navigator: UINavigationController) {
        self.owner = owner
        self.path = path
        self.identifier = identifier
        self.navigator = navigator
        let controllers = navigator.viewControllers
        for controller in controllers {
            cache?[String(describing: type(of: controller))] = controller
            controller.coordinator = self
        }
    }
    
    public var isModalInPresentation: Bool? {
        didSet {
            if #available(iOS 13.0, *) {
                navigator?.isModalInPresentation = isModalInPresentation ?? false
            }
        }
    }

    public var modalPresentationStyle: UIModalPresentationStyle? {
        didSet {
            guard let modalPresentationStyle = modalPresentationStyle else {
                return
            }
            navigator?.modalPresentationStyle = modalPresentationStyle
        }
    }

    // MARK: - Private

    fileprivate var navigator: UINavigationController?
    fileprivate var path: CoordinatorPath?
    fileprivate var cache: CoordinatorCache? = [:]

    fileprivate var originalCache: CoordinatorCache?
    fileprivate var originalPath: CoordinatorPath?
    fileprivate var attachedPath: CoordinatorPath?
}

// MARK: - Coordinatable

extension Coordinator: Coordinatable {
    
    public func next(with query: String?,
                     animated flag: Bool = true,
                     _ completion: ControllerCompletion? = nil) {
        // go to the last point of path before merge
        let didPopMergedPath = popMergedPathIfNeeded(with: query, animated: flag)
        if didPopMergedPath { return }
        
        // pop to the root if non-merged path is completed
        let didPopToRoot = popToRootNeeded(with: query, animated: flag)
        if didPopToRoot { return }
        
        // just go to next point of navigation
        let nextIndex = currentIndex()+1
        guard
            let nextController = controller(at: nextIndex),
            let navigationType = animationType(at: nextIndex) else {
                return
        }
        
        nextController.coordinator = self
        nextController.initialQuery = query
        nextController.query = query

        switch navigationType {
        case .push:
            navigator?.pushViewController(nextController, animated: flag)
        }
        completion?(nextController)
    }
    
    public func back(animated flag: Bool) {
        let index = currentIndex()
        
        guard
            let className = className(at: index),
            let navigationType = animationType(at: index),
            let controller = controller(at: index) else {
                return
        }
        
        cache?.removeValue(forKey: className)

        unmergeIfNeeded(for: controller)

        switch navigationType {
        case .push:
            navigator?.popViewController(animated: true)
        }
    }
    
    public func attach(_ path: CoordinatorPath) {
        guard
            let currentPath = self.path else {
                return
        }
        
        originalPath = self.path
        originalCache = cache
        attachedPath = path
        self.path = currentPath + path
    }

    public func present(with query: String? = nil,
                        animated flag: Bool = true,
                        _ completion: ControllerCompletion? = nil) {
        guard
            let navigator = navigator else {
                return
        }
        navigator.viewControllers.set(query: query)
        navigator.viewControllers.set(coordinator: self)
        owner?.present(navigator, animated: flag)
        completion?(navigator.viewControllers.first)
    }
    
    public func dismiss(animated flag: Bool = true) {
        // fix for broken UIKit API WORKS ONLY TOGETHER WITH BELOW ONE
        owner?.viewWillDisappear(flag)
        owner?.viewDidDisappear(flag)
        //
        owner?.dismiss(animated: flag)
    }

    public func complete(with query: String?) {
        unmerge()
        cache?.removeCoordinators()
        cache = [:]
        navigator = nil
        owner?.didCompletePath(coordinator: self, with: query)
        // fix for broken UIKit API WORKS ONLY TOGETHER WITH ABOVE ONE
        owner?.viewWillAppear(true)
        owner?.viewDidAppear(true)
        //
    }
    
    public func hasNext() -> Bool {
        guard
            let path = path else {
                return false
        }
        
        return currentIndex() != path.count-1
    }
}

public enum NavigationAnimation {
    case push
}

// MARK: - Public Extensions

private var associateCoordinatorKey: Void?
private var associateInitialQueryKey: Void?
private var associateQueryKey: Void?

public extension UIViewController {
    
    var coordinator: Coordinator? {
        get {
            return objc_getAssociatedObject(self, &associateCoordinatorKey) as? Coordinator
        }
        set {
            objc_setAssociatedObject(self, &associateCoordinatorKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    var initialQuery: Query? {
        get {
            return objc_getAssociatedObject(self, &associateInitialQueryKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &associateInitialQueryKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    var query: Query? {
        get {
            return objc_getAssociatedObject(self, &associateQueryKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &associateQueryKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    func hasChanges(for query: Query) -> Bool {
        guard
            let source = initialQuery else {
                return true
        }
        
        return source.hasChanges(comparing: query)
    }
}

// MARK: - Private

private typealias CoordinatorCache = [String: UIViewController]

fileprivate extension Dictionary where Key: Hashable, Value: UIViewController {
        
    func removeCoordinators() {
        forEach (_:) {
            $0.value.coordinator = nil
        }
    }
}

fileprivate extension Sequence where Self.Element: UIViewController {
        
    func set(query: Query?) {
        guard
            let query = query else {
            return
        }
        forEach { element in
            element.query = query
            element.initialQuery = query
        }
    }

    func set(coordinator: Coordinator?) {
        guard
            let coordinator = coordinator else {
            return
        }
        forEach { element in
            element.coordinator = coordinator
        }
    }
}

fileprivate extension Coordinator {
    
    func currentIndex() -> Int {
        if
        let path = path,
        let visibleController = navigator?.topViewController,
        let index = path.firstIndex(where: {$0.controller.self == type(of: visibleController)}) {
            return index
        }
        return NSNotFound
    }

    func className(at index: Int) -> String? {
        if
        let path = path,
        0 ... path.count-1 ~= index {
            return String(describing: path[index].controller)
        }
        return nil
    }

    func controller(at index: Int) -> UIViewController? {
        guard
            let className = className(at: index),
            let path = path else {
                return nil
        }
        
        guard
            let cachedController = cache?[className] else {
                let newClass = path[index].controller
                let newController = newClass.init()
                cache?[className] = newController
                return newController
        }
        
        return cachedController
    }

    func animationType(at index: Int) -> NavigationAnimation? {
        return path?[index].animation
    }
    
    func unmerge() {
        guard
            let originalPath = originalPath else {
                return
        }
        
        path = originalPath
        attachedPath = nil
        cache = originalCache
    }
    
    func unmergeIfNeeded(for controller: UIViewController) {
        guard
            let index = indexInMergedPath(of: controller) else {
                return
        }
        
        if index == 0 || index == attachedPath?.count {
            unmerge()
        }
    }
    
    func indexInMergedPath(of controller: UIViewController) -> Int? {
        guard
            let mergedPath = attachedPath else {
                return nil
        }
        
        if let index = mergedPath.firstIndex(where: {$0.controller.self == type(of: controller)}) {
            return index
        }
        return nil
    }
    
    func popMergedPathIfNeeded(with query: String?, animated flag: Bool) -> Bool {
        guard
            let path = path else {
                return false
        }
        
        let index = currentIndex()
        if nil != attachedPath, index == path.count-1 {
            guard
                let originalPath = originalPath,
                let lastOriginalController = controller(at: originalPath.count-1) else {
                    return false
            }
            
            lastOriginalController.query = query
            navigator?.popToViewController(lastOriginalController, animated: flag)
            unmerge()
            return true
        }
        return false
    }

    func popToRootNeeded(with query: String?, animated flag: Bool) -> Bool {
        guard
            let path = path else {
                return false
        }
        
        let index = currentIndex()
        if index == path.count-1 {
            navigator?.popToRootViewController(animated: flag)
            complete(with: query)
            return true
        }
        return false
    }
}
