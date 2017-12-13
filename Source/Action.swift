//
//  Action.swift
//  Alamofire
//
//  Created by ray on 2017/12/8.
//  Copyright © 2017年 ray. All rights reserved.
//



var ActionExcuteQueue = DispatchQueue(label: "ActionExcuteQueue", attributes: .concurrent)

public protocol Action {
    func excute(_ doneCallback: @escaping () -> Void)
    var repeatEnabled: Bool { get }
}

public class WorkAction: Action {
    
    var work: () -> Void
    
    public init(_ work: @escaping () -> Void) {
        self.work = work
    }
    
    public func excute(_ doneCallback: @escaping () -> Void) {
        ActionExcuteQueue.async {
            self.work()
            doneCallback()
        }
    }
}


public class DelayAction: Action {
    
    private var delaySeconds: TimeInterval
    private var isExcuting: AtomicProperty<Bool> = AtomicProperty<Bool>(false)

    public init(_ delaySeconds: TimeInterval) {
        self.delaySeconds = delaySeconds
    }
    
    public func excute(_ doneCallback: @escaping () -> Void) {
        if self.isExcuting.value {
            return
        }
        self.isExcuting.value = true
        let semp = DispatchSemaphore(value: 0)
        ActionExcuteQueue.async {
            let _ = semp.wait(timeout: .now() + self.delaySeconds)
            self.isExcuting.value = false
            doneCallback()
        }
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


