//
//  Action.swift
//  Alamofire
//
//  Created by ray on 2017/12/8.
//  Copyright © 2017年 ray. All rights reserved.
//


public protocol Action {
    
    func excute()
    
    func and(_ action: Action) -> Action
    
    func then(_ action: Action) -> Action
    
    func `repeat`(_ willExcuteHandler: @escaping (_ didRepeatTime: UInt) -> Bool) -> Self
    
}



public extension Action {
    
    public func and(_ action: Action) -> Action {
        if let i = self as? ActionGroup {
            return i.and(action)
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
            return i.then(action)
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
}

public struct AtomicProperty<T> {
    private lazy var lock = DispatchSemaphore(value: 1)
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


public class DelayAction: Action {
    
    private var delaySecond: TimeInterval
    private var willExcuteHandler: ((UInt) -> Bool)?
    private var repeatTime: UInt = 0
    private var isExcuting: AtomicProperty<Bool> = AtomicProperty<Bool>(false)
    
    init(_ delaySecond: TimeInterval) {
        self.delaySecond = delaySecond
    }
    
    public func excute() {
        if self.isExcuting.value {
            return
        }
        let wait = {
            let semp = DispatchSemaphore(value: 0)
            let _ = semp.wait(timeout: DispatchTime(uptimeNanoseconds: UInt64(self.delaySecond * 1000 * 1000)))
        }
        
        if let willExcute = self.willExcuteHandler?(repeatTime) {
            if willExcute {
                self.isExcuting.value = true
                wait()
                repeatTime += 1
                excute()
            }
        } else {
            wait()
        }
    }
    
    public func `repeat`(_ willExcuteHandler: @escaping (UInt) -> Bool) -> Self {
        self.willExcuteHandler = willExcuteHandler
        return self
    }
    
    
    
    
}

