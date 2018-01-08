//
//  Action.swift
//  Alamofire
//
//  Created by ray on 2017/12/8.
//  Copyright © 2017年 ray. All rights reserved.
//


let ActionExcuteQueue = DispatchQueue(label: "ActionExcuteQueue", attributes: .concurrent)

public protocol Action {
    func excute(_ doneCallback: @escaping () -> Void)
    var isPassEnabled: AtomicProperty<Bool> { get set }
}

public class WorkAction: Action {

    var work: () -> Void
    public var isPassEnabled = AtomicProperty<Bool>(false)
    
    public init(_ work: @escaping () -> Void) {
        self.work = work
    }
    
    public func excute(_ doneCallback: @escaping () -> Void) {
        if isPassEnabled.value {
            doneCallback()
            return
        }
        ActionExcuteQueue.async {
            self.work()
            doneCallback()
        }
    }
}

public class DelayAction: Action {
    
    private var delaySeconds: TimeInterval
    public var isPassEnabled = AtomicProperty<Bool>(false)

    public init(_ delaySeconds: TimeInterval) {
        self.delaySeconds = delaySeconds
    }
    
    public func excute(_ doneCallback: @escaping () -> Void) {
        if isPassEnabled.value {
            doneCallback()
            return
        }
        let semp = DispatchSemaphore(value: 0)
        ActionExcuteQueue.async {
            let _ = semp.wait(timeout: .now() + self.delaySeconds)
            doneCallback()
        }
    }
}

public extension Action {
    
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



