//
//  ActionGroup.swift
//  Alamofire
//
//  Created by ray on 2017/12/8.
//  Copyright © 2017年 ray. All rights reserved.
//


open class Group<T>: Sequence {
    
    var allElements: [T] = []

    public enum ExcuteType {
        case sequence, spawn
    }
    
    public required init(elements: [T]? = nil, excuteType: ExcuteType = .sequence) {
        if let elements = elements {
            allElements.append(contentsOf: elements)
        }
        self.excuteType = excuteType
    }
    
    public func makeIterator() -> Array<T>.Iterator {
        return allElements.makeIterator()
    }
    
    var excuteType: ExcuteType
    
    public func append(elements: [T]) {
        allElements.append(contentsOf: elements)
    }
    
    public func append(element: T) {
        allElements.append(element)
    }
    
    public func insert(elements: [T]) {
        allElements.insert(contentsOf:elements, at: 0)
    }
    
    public func insert(element: T) {
        allElements.insert(element, at: 0)
    }
    
    public var count: Int {
        return allElements.count
    }
}

public class ActionGroup: Group<Action>, Action {

    private var repeatTime: UInt = 0
    private var willExcuteHandler: ((UInt) -> Bool)?
    
    private lazy var excute_queue = DispatchQueue(label: "ActionGroup excute_queue", attributes: .concurrent)
    private lazy var excute_wait_semp = DispatchSemaphore(value: 0)
    
    private var isExcuting: AtomicProperty<Bool> = AtomicProperty<Bool>(false)

    public func excute() {
        if isExcuting.value {
            return
        }
        let done = {
            self.repeatTime = 0
            self.excute_wait_semp.signal()
            self.isExcuting.value = false
        }
        let sequenceExcute = {
            self.isExcuting.value = true
            for action in self {
                action.excute()
            }
        }
        let spawnExcute: (DispatchGroup) -> Void = { dispatch_group in
            self.isExcuting.value = true
            for action in self {
                dispatch_group.enter()
                self.excute_queue.async {
                    action.excute()
                    dispatch_group.leave()
                }
            }
        }
        switch excuteType {
        case .sequence:
            excute_queue.async {
                if let willExcute = self.willExcuteHandler?(self.repeatTime) {
                    if willExcute {
                        sequenceExcute()
                        self.repeatTime += 1
                        self.excute()
                    } else {
                        done()
                    }
                } else {
                    sequenceExcute()
                    done()
                }
            }
        case .spawn:
            let dispatch_group = DispatchGroup()

            if let willExcute = self.willExcuteHandler?(self.repeatTime) {
                if willExcute {
                    spawnExcute(dispatch_group)
                } else {
                    done()
                }
            } else {
                spawnExcute(dispatch_group)
            }

            dispatch_group.notify(queue: excute_queue, execute: {
                self.isExcuting.value = false
                if nil == self.willExcuteHandler {
                    done()
                } else {
                    self.repeatTime += 1
                    self.excute()
                }
            })
            excute_wait_semp.wait()
        }
    }
    
    
    public func and(_ action: Action) -> ActionGroup {
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
    
    public func then(_ action: Action) -> ActionGroup {
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
    
    public func `repeat`(_ willExcuteHandler: @escaping (UInt) -> Bool) -> Self {
        self.willExcuteHandler = willExcuteHandler
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



