//
//  AndThen.swift
//  ralyo
//
//  Created by ray on 2017/12/11.
//  Copyright © 2017年 ray. All rights reserved.
//

import Foundation


public extension Action {

    var repeatEnabled: Bool {
        return false
    }
    
    public func and(_ action: Action) -> Action {
        if let i = self as? ActionGroup {
            return i.groupAnd(action)
        } else if let action = action as? ActionGroup {
            switch action.excuteType {
            case .spawn:
                action.append(element: self)
                return action
            default:break
            }
        }
        return ActionGroup(elements: [self, action], excuteType: .spawn)
    }
    
    public func then(_ action: Action) -> Action {
        if let i = self as? ActionGroup {
            return i.groupThen(action)
        } else if let action = action as? ActionGroup {
            switch action.excuteType {
            case .sequence:
                action.insert(element: self)
                return action
            default:break
            }
        }
        return ActionGroup(elements: [self, action], excuteType: .sequence)
    }
    
    public func `repeat`(_ willExcuteHandler: @escaping (_ repeatCount: UInt, _ delay: inout TimeInterval?) -> Bool) -> Action {
        return ActionGroup(elements: [self], excuteType: .sequence).repeat(willExcuteHandler)
    }
}


public extension ActionGroup {
    
    public func groupAnd(_ action: Action) -> ActionGroup {
        if self.excuteType == .sequence || self.repeatEnabled {
            return ActionGroup(elements: [self, action], excuteType: .spawn)
        }
        if let action = action as? ActionGroup {
            switch (excuteType, action.excuteType) {
            case (.spawn, .spawn):
                if let all = action.allElements {
                    self.append(elements: all)
                    return self
                }
            case (.spawn, .sequence):
                self.append(element: action)
                return self
            case (.sequence, .spawn):
                action.append(element: self)
                return action
            case (.sequence, .sequence):
                return ActionGroup(elements: [self, action], excuteType: .spawn)
            }
        }

        append(element: action)
        return self
    }
    
    public func groupThen(_ action: Action) -> ActionGroup {
        if self.excuteType == .spawn || self.repeatEnabled {
            return ActionGroup(elements: [self, action], excuteType: .sequence)
        }
        if let action = action as? ActionGroup {
            switch (excuteType, action.excuteType) {
            case (.spawn, .spawn):
                return ActionGroup(elements: [self, action], excuteType: .sequence)
            case (.spawn, .sequence):
                action.insert(element: self)
                return action
            case (.sequence, .spawn):
                append(element: action)
                return self
            case (.sequence, .sequence):
                if let all = action.allElements {
                    self.append(elements: all)
                    return self
                }
            }
        }
        append(element: action)
        return self
    }
    
    public func `repeat`(_ willExcuteHandler: @escaping (UInt, inout TimeInterval?) -> Bool) -> Action {
        if self.repeatEnabled {
            return ActionGroup(elements: self.allElements, excuteType: self.excuteType).repeat(willExcuteHandler)
        }
        self.repeatEnabled = true
        self.willExcuteHandler = willExcuteHandler
        return self
    }
    
}

public struct AtomicProperty<T> {
    
    private var lock = DispatchSemaphore(value: 1)
    private var _value: T
    
    init(_ value: T) {
        _value = value
    }
    
    public var value: T {
        mutating get {
            lock.wait()
            defer { lock.signal() }
            return _value
        }
        mutating set(new) {
            lock.wait()
            _value = new
            lock.signal()
        }
    }

}

infix operator -->: AdditionPrecedence
public func --> (left: Action, right: Action) -> ActionGroup {
    return left.then(right) as! ActionGroup
}

infix operator &: MultiplicationPrecedence
public func & (left: Action, right: Action) -> ActionGroup {
    return left.and(right) as! ActionGroup
}

