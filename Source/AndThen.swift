//
//  AndThen.swift
//  ralyo
//
//  Created by ray on 2017/12/11.
//  Copyright © 2017年 ray. All rights reserved.
//


import Foundation

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


infix operator -->: AdditionPrecedence
public func --> (left: Action, right: Action) -> ActionGroup {
    return left.then(right) as! ActionGroup
}

infix operator &: MultiplicationPrecedence
public func & (left: Action, right: Action) -> ActionGroup {
    return left.and(right) as! ActionGroup
}



