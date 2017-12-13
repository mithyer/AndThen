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
    
    var passEnabled: AtomicProperty<Bool> { get set }
    var repeatEnabled: Bool { get }
}

public class WorkAction: Action {

    var work: () -> Void
    public var passEnabled = AtomicProperty<Bool>(false)
    
    public init(_ work: @escaping () -> Void) {
        self.work = work
    }
    
    public func excute(_ doneCallback: @escaping () -> Void) {
        if passEnabled.value {
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
    public var passEnabled = AtomicProperty<Bool>(false)

    public init(_ delaySeconds: TimeInterval) {
        self.delaySeconds = delaySeconds
    }
    
    public func excute(_ doneCallback: @escaping () -> Void) {
        if passEnabled.value {
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




