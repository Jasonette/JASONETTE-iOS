//
//  FinalsiteUITests.swift
//  FinalsiteUITests
//
//  Created by Felix Barros on 8/21/18.
//  Copyright © 2018 Jasonette. All rights reserved.
//

import XCTest

class FinalsiteUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testSnapshots() {
        
        let app = XCUIApplication()
        let tabBarsQuery = app.tabBars
        
        sleep(6)
        snapshot("01HomeScreen")
        tabBarsQuery.buttons.element(boundBy: 1).tap()
        sleep(6)
        snapshot("02TabScreen")
        tabBarsQuery.buttons.element(boundBy: 2).tap()
        sleep(6)
        snapshot("03TabScreen")
        tabBarsQuery.buttons.element(boundBy: 3).tap()
        sleep(6)
        snapshot("04TabScreen")
        tabBarsQuery.buttons.element(boundBy: 4).tap()
        sleep(6)
        snapshot("05TabScreen")
        
    }
    
}
