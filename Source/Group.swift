//
//  Group.swift
//  ralyo
//
//  Created by ray on 2017/12/11.
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
