//
//  ActionGroup.swift
//  Alamofire
//
//  Created by ray on 2017/12/8.
//  Copyright © 2017年 ray. All rights reserved.
//

public class ActionGroup: Group<Action>, Action {

    private var repeatTime: UInt = 0
    public internal(set) var repeatEnabled: Bool = false
    
    private var isExcuting: AtomicProperty<Bool> = AtomicProperty<Bool>(false)

    public func excute(_ doneCallback: @escaping () -> Void) {
        if isExcuting.value && self.repeatTime < 1 {
            return
        }
        self.isExcuting.value = true
        let done = {
            self.repeatTime = 0
            self.isExcuting.value = false
            self.repeatEnabled = false
            doneCallback()
        }
        let sequenceExcute: (_ sequenceDone: @escaping () -> Void) -> Void = { sequenceDone in
            let semp = DispatchSemaphore(value: 0)
            ActionExcuteQueue.async {
                for action in self {
                    action.excute({
                        semp.signal()
                    })
                    semp.wait();
                }
                sequenceDone()
            }
        }
        let spawnExcute: (_ spawnDone: @escaping () -> Void) -> Void = { spawnDone in
            let dispatch_group = DispatchGroup()
            for action in self {
                dispatch_group.enter()
                ActionExcuteQueue.async {
                    action.excute({
                        dispatch_group.leave()
                    })
                }
            }
            dispatch_group.notify(queue: ActionExcuteQueue, execute: spawnDone)
        }
        switch excuteType {
        case .sequence:
            ActionExcuteQueue.async {
                if self.repeatEnabled {
                    var delay: TimeInterval?
                    if self.willExcuteHandler!(self.repeatTime, &delay) {
                        if let delay = delay {
                            let wait = DispatchSemaphore(value: 0)
                            let _ = wait.wait(timeout: .now() + delay)
                        }
                        sequenceExcute {
                            self.repeatTime += 1
                            self.excute(doneCallback)
                        }
                    } else {
                        done()
                    }
                } else {
                    sequenceExcute {
                        done()
                    }
                }
            }
        case .spawn:
            let spawnDone = {
                self.isExcuting.value = false
                if !self.repeatEnabled {
                    done()
                } else {
                    self.repeatTime += 1
                    self.excute(doneCallback)
                }
            }
            
            if self.repeatEnabled {
                var delay: TimeInterval?
                if self.willExcuteHandler!(self.repeatTime, &delay) {
                    if let delay = delay {
                        let wait = DispatchSemaphore(value: 0)
                        let _ = wait.wait(timeout: DispatchTime(uptimeNanoseconds: UInt64(delay * 10e6)))
                    }
                    spawnExcute(spawnDone)
                } else {
                    done()
                }
            } else {
                spawnExcute(spawnDone)
            }
        }
    }
    
}







