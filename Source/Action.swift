//
//  Action.swift
//  Alamofire
//
//  Created by ray on 2017/12/8.
//  Copyright © 2017年 ray. All rights reserved.
//


public protocol Action {
    func excute(_ doneCallback: @escaping () -> Void)
    var repeatEnabled: Bool { get }
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


public class DelayAction: Action {
    
    private var delaySecond: TimeInterval
    private var repeatCount: UInt = 0
    private var isExcuting: AtomicProperty<Bool> = AtomicProperty<Bool>(false)
    public internal(set) var repeatEnabled: Bool = false

    init(_ delaySecond: TimeInterval) {
        self.delaySecond = delaySecond
    }
    
    public func excute(_ doneCallback: @escaping () -> Void) {
        if self.isExcuting.value && repeatCount < 1 {
            return
        }
        self.isExcuting.value = true
        let wait = {
            let semp = DispatchSemaphore(value: 0)
            let _ = semp.wait(timeout: DispatchTime(uptimeNanoseconds: UInt64(self.delaySecond * 10e6)))
        }
        let done = {
            self.isExcuting.value = false
            self.repeatCount = 0
            self.repeatEnabled = false
            doneCallback()
        }
        
        if let willExcute = self.willExcuteHandler?(repeatCount) {
            if willExcute {
                wait()
                repeatCount += 1
                excute(doneCallback)
            } else {
                done()
            }
        } else {
            wait()
            done()
        }
    }
    
}

