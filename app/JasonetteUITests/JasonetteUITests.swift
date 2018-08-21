//
//  JasonetteUITests.swift
//  JasonetteUITests
//
//  Created by Felix Barros on 8/21/18.
//  Copyright © 2018 Jasonette. All rights reserved.
//

import XCTest

class JasonetteUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOpenMenu() {
        let app = XCUIApplication()
        // Open menu
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
        element.children(matching: .other).element(boundBy: 1).tap()
        
        // Find home link
        let home = app.tables.children(matching: .cell).element(boundBy: 0).children(matching: .other).element(boundBy: 0).children(matching: .staticText)["Home"]
        let exists = NSPredicate(format: "hittable == true")
        
        // Ensure home link is hittable
        expectation(for: exists, evaluatedWith: home, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
}
