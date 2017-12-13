//
//  AndThenTests.swift
//  AndThenTests
//
//  Created by ray on 2017/12/13.
//  Copyright © 2017年 ray. All rights reserved.
//

import XCTest
@testable import AndThen

class AndThenTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testWorkAction() {
        let workExct: XCTestExpectation = self.expectation(description: "workExct")
        let doneExct: XCTestExpectation = self.expectation(description: "doneExct")
        WorkAction {
            workExct.fulfill()
        }.excute {
            doneExct.fulfill()
        }
        self.wait(for: [workExct, doneExct], timeout: 5, enforceOrder: true)
    }
    
    func testAnd() {
        let workExct: XCTestExpectation = self.expectation(description: "workExct")
        workExct.expectedFulfillmentCount = 2
        workExct.assertForOverFulfill = true
        let doneExct: XCTestExpectation = self.expectation(description: "doneExct")
        
        (WorkAction {
            workExct.fulfill()
        } & WorkAction {
            workExct.fulfill()
        }).excute {
            doneExct.fulfill()
        }
        self.wait(for: [workExct, doneExct], timeout: 5, enforceOrder: true)
    }
    
    func testThen() {
        let work1Exct: XCTestExpectation = self.expectation(description: "work1Exct")
        let work2Exct: XCTestExpectation = self.expectation(description: "work2Exct")
        let doneExct: XCTestExpectation = self.expectation(description: "doneExct")
        
        (WorkAction {
            work1Exct.fulfill()
        } --> WorkAction {
            work2Exct.fulfill()
        }).excute {
            doneExct.fulfill()
        }
        self.wait(for: [work1Exct, work2Exct, doneExct], timeout: 5, enforceOrder: true)
    }
    
    func testAndThen() {
        
        let work1Exct: XCTestExpectation = self.expectation(description: "work1Exct")
        work1Exct.expectedFulfillmentCount = 2
        work1Exct.assertForOverFulfill = true
        let work2Exct: XCTestExpectation = self.expectation(description: "work2Exct")
        let doneExct: XCTestExpectation = self.expectation(description: "doneExct")
        
        (WorkAction {
            work1Exct.fulfill()
        } & WorkAction {
            work1Exct.fulfill()
        } --> WorkAction {
            work2Exct.fulfill()
        }).excute {
            doneExct.fulfill()
        }
        self.wait(for: [work1Exct, work2Exct, doneExct], timeout: 5, enforceOrder: true)
        
    }
    
    func testThenAnd() {
    
        let work1Exct: XCTestExpectation = self.expectation(description: "work1Exct")
        work1Exct.expectedFulfillmentCount = 2
        work1Exct.assertForOverFulfill = true
        let work2Exct: XCTestExpectation = self.expectation(description: "work2Exct")
        let doneExct: XCTestExpectation = self.expectation(description: "doneExct")
        
        (WorkAction {
            work2Exct.fulfill()
        } --> WorkAction {
            work1Exct.fulfill()
        } & WorkAction {
            work1Exct.fulfill()
        }).excute {
            doneExct.fulfill()
        }
        self.wait(for: [work2Exct, work1Exct, doneExct], timeout: 5, enforceOrder: true)
    }
    
    func testDelayAction() {
        let work1Exct: XCTestExpectation = self.expectation(description: "work1Exct")
        let work2Exct: XCTestExpectation = self.expectation(description: "work2Exct")
        let work3Exct: XCTestExpectation = self.expectation(description: "work3Exct")
        let doneExct: XCTestExpectation = self.expectation(description: "doneExct")
        
        let delayWork1 = DelayAction(1) --> WorkAction {
            work1Exct.fulfill()
        }
        let delayWork2 = DelayAction(2) --> WorkAction {
            work2Exct.fulfill()
        }
        let work3 = WorkAction {
            work3Exct.fulfill()
        }
        (delayWork1 & delayWork2 & work3).excute {
            doneExct.fulfill()
        }
        self.wait(for: [work3Exct, work1Exct, work2Exct, doneExct], timeout: 5, enforceOrder: true)
    }
    
    func testRepeat() {
        let repeatTime = 3
        
        let workExct: XCTestExpectation = self.expectation(description: "workExct")
        workExct.expectedFulfillmentCount = repeatTime
        workExct.assertForOverFulfill = true
        let doneExct: XCTestExpectation = self.expectation(description: "doneExct")

        WorkAction {
            workExct.fulfill()
        }.repeat { count, delay -> Bool in
            return count < repeatTime
        }.excute {
            doneExct.fulfill()
        }
        
        self.wait(for: [workExct, doneExct], timeout: 5, enforceOrder: true)
    }
    
    func testRepeatDelay() {
        let repeatTime = 3

        let workExct1: XCTestExpectation = self.expectation(description: "workExct1")
        workExct1.expectedFulfillmentCount = repeatTime
        workExct1.assertForOverFulfill = true

        WorkAction {
            workExct1.fulfill()
        }.repeat { count, delay -> Bool in
            print("1: count\(count)")
            delay = 2
            return count < repeatTime
        }.excute {

        }

        let workExct2: XCTestExpectation = self.expectation(description: "workExct2")
        workExct2.expectedFulfillmentCount = repeatTime
        workExct2.assertForOverFulfill = true

        WorkAction {
            workExct2.fulfill()
        }.repeat { count, delay -> Bool in
            print("2: count\(count)")
            delay = 1
            return count < repeatTime
        }.excute {

        }

        let work3DoneExct: XCTestExpectation = self.expectation(description: "work3DoneExct")

        DelayAction(7).excute {
            print("3")
            work3DoneExct.fulfill()
        }

        self.wait(for: [workExct2, workExct1, work3DoneExct], timeout: 10, enforceOrder: true)

    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
