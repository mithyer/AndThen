//
//  AndThen.swift
//  ralyo
//
//  Created by ray on 2017/12/11.
//  Copyright © 2017年 ray. All rights reserved.
//

import Foundation

var willExcuteHandlerKey: UInt8 = 0

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
        
    var willExcuteHandler: ((_ repeatCount: UInt, _ delay: inout TimeInterval?) -> Bool)? {
        get {
            return objc_getAssociatedObject(self, &willExcuteHandlerKey) as? ((_ repeatCount: UInt, _ delay: inout TimeInterval?) -> Bool)
        }
        set(new) {
            objc_setAssociatedObject(self, &willExcuteHandlerKey, new, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    public func `repeat`(_ willExcuteHandler: @escaping (_ repeatCount: UInt, _ delay: inout TimeInterval?) -> Bool) -> Action {
        var group = ActionGroup(elements: [self], excuteType: .sequence)
        group.repeatEnabled = true
        group.willExcuteHandler = willExcuteHandler
        return group
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
                self.append(elements: action.allElements)
                return self
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
                append(elements: action.allElements)
                return self
            }
        }
        append(element: action)
        return self
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

