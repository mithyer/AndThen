//
//  ActionGroup.swift
//  Alamofire
//
//  Created by ray on 2017/12/8.
//  Copyright © 2017年 ray. All rights reserved.
//


public class Group<T>: Sequence {
    
    var allElements: [T]?
    
    public enum ExcuteType {
        case sequence, spawn
    }
    
    public private(set) var excuteType: ExcuteType
    
    public required init(elements: [T]? = nil, excuteType: ExcuteType = .sequence) {
        if let elements = elements {
            allElements = elements
        }
        self.excuteType = excuteType
    }
    
    public func makeIterator() -> Array<T>.Iterator {
        return (allElements ?? []).makeIterator()
    }
    
    
    public func append(elements: [T]) {
        allElements?.append(contentsOf: elements)
    }
    
    public func append(element: T) {
        allElements?.append(element)
    }
    
    public func insert(elements: [T]) {
        allElements?.insert(contentsOf:elements, at: 0)
    }
    
    public func insert(element: T) {
        allElements?.insert(element, at: 0)
    }
    
    public var count: Int {
        return allElements?.count ?? 0
    }
}

public class ActionGroup: Group<Action>, Action {

    private var repeatTime: UInt = 0
    var willExcuteHandler: ((_ repeatCount: UInt, _ delay: inout TimeInterval?) -> Bool)?
    public var isPassEnabled: AtomicProperty<Bool> = AtomicProperty<Bool>(false)
    
    public func excute(_ doneCallback: @escaping () -> Void) {
        let done = {
            self.repeatTime = 0
            self.willExcuteHandler = nil
            doneCallback()
        }
        if isPassEnabled.value {
            done()
            return
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
                if let willExcuteHandler = self.willExcuteHandler {
                    var delay: TimeInterval?
                    if willExcuteHandler(self.repeatTime, &delay) {
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
                if let _ = self.willExcuteHandler {
                    self.repeatTime += 1
                    self.excute(doneCallback)
                } else {
                    done()
                }
            }
            
            if let willExcuteHandler = self.willExcuteHandler {
                var delay: TimeInterval?
                if willExcuteHandler(self.repeatTime, &delay) {
                    if let delay = delay {
                        let wait = DispatchSemaphore(value: 0)
                        let _ = wait.wait(timeout: .now() + delay)
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

public extension ActionGroup {
    
    public func groupAnd(_ action: Action) -> ActionGroup {
        if self.excuteType == .sequence || nil != self.willExcuteHandler {
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
        if self.excuteType == .spawn || nil != self.willExcuteHandler {
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
        if let _ = self.willExcuteHandler  {
            return ActionGroup(elements: self.allElements, excuteType: self.excuteType).repeat(willExcuteHandler)
        }
        self.willExcuteHandler = willExcuteHandler
        return self
    }
    
}






