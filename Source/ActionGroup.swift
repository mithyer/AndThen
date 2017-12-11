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
    
    public lazy var excute_queue = DispatchQueue(label: "ActionGroup excute_queue", attributes: .concurrent)
    
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
            self.excute_queue.async {
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
                self.excute_queue.async {
                    action.excute({
                        dispatch_group.leave()
                    })
                }
            }
            dispatch_group.notify(queue: self.excute_queue, execute: spawnDone)
        }
        switch excuteType {
        case .sequence:
            excute_queue.async {
                if self.repeatEnabled {
                    if self.willExcuteHandler!(self.repeatTime) {
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
                if self.willExcuteHandler!(self.repeatTime) {
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







