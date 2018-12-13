//
//  UnitTests.swift
//  UnitTests
//
//  Created by Johan Bloemberg on 09/12/2018.
//  Copyright © 2018 Johan Bloemberg. All rights reserved.
//

import XCTest

class UnitTests: XCTestCase {
    let testTunnels = [
        "test": Tunnel(
            interface: "Tunnel Name",
            connected: false,
            address: "",
            peers: []
        ),
    ]

    // menu image should properly represent state of tunnels
    func testMenuImage() {
        var tunnels = testTunnels

        XCTAssertEqual(menuImage(tunnels: tunnels).name(), "dragon-dim")
        tunnels["test"]!.connected = true
        XCTAssertEqual(menuImage(tunnels: tunnels).name(), "silhouette")
    }

    func testMenu() {
        let menu = buildMenu(tunnels: testTunnels)
        XCTAssertEqual(menu.items[0].title, "Tunnel Name: ")
        XCTAssertEqual(menu.items[0].state, NSControl.StateValue.off)
    }

    func testMenuEnabledTunnel() {
        var tunnels = testTunnels
        tunnels["test"]!.connected = true

        let menu = buildMenu(tunnels: tunnels)
        XCTAssertEqual(menu.items[0].title, "Tunnel Name: ")
        XCTAssertEqual(menu.items[0].state, NSControl.StateValue.on)
    }

    func testMenuNoTunnels() {
        let menu = buildMenu(tunnels: Tunnels())
        XCTAssertEqual(menu.items[0].title, "No tunnel configurations found")
    }

    func testMenuSorting() {
        let tunnels = [
            "Z": Tunnel(interface: "Z Tunnel Name", connected: false, address: "", peers: []),
            "A": Tunnel(interface: "A Tunnel Name", connected: false, address: "", peers: []),
        ]
        let menu = buildMenu(tunnels: tunnels)
        // tunnels should be sorted alphabetically
        XCTAssertEqual(menu.items[0].title, "A Tunnel Name: ")
    }

    func testConfigParsing() {
        let bundle = Bundle(for: type(of: self).self)
        let testConfig = bundle.path(forResource: "test", ofType: "conf")!
        XCTAssertNotNil(testConfig)

        let tunnel = parseConfig(configFilePath: testConfig))
        XCTAssertEqual(tunnel.interface, "test")
        XCTAssertEqual(tunnel.address, "10.10.101.123/24")
    }

    func testConfigParsing2() {
        let bundle = Bundle(for: type(of: self).self)
        let testConfig = bundle.path(forResource: "wg0", ofType: "conf")!
        XCTAssertNotNil(testConfig)

        let tunnel = parseConfig(configFilePath: testConfig))
        XCTAssertEqual(tunnel.interface, "wg0")
        XCTAssertEqual(tunnel.address, "10.10.101.123/24")
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
}
