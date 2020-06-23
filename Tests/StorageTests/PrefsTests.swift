//
//  PrefsTest.swift
//  StorageTests
//
//  Created by Gal Yedidovich on 13/06/2020.
//

import XCTest
import BasicExtensions
@testable import StorageExtensions

final class PrefsTests: XCTestCase {
	
	override static func setUp() {
		FileSystem.delete(file: .prefs)
	}
	
	override func tearDown() {
		FileSystem.delete(file: .prefs)
		Prefs.standard.dict = [:]
	}
	
	func testInsert() {
		let prefs = Prefs.standard
		
		prefs.edit().put(key: .name, "Gal").commit()
		
		XCTAssert(prefs.string(key: .name) == "Gal")
		afterWrite(at: prefs) { json in
			XCTAssert(json[.name] == "Gal")
		}
	}
	
	func testReplace() {
		let prefs = Prefs.standard
		
		prefs.edit()
			.put(key: .name, "Gal")
			.put(key: .age, 26)
			.commit()
		
		prefs.edit().put(key: .name, "Bubu").commit()
		
		XCTAssert(prefs.string(key: .name) == "Bubu")
		afterWrite(at: prefs) { json in
			XCTAssert(json[.name] == "Bubu")
		}
	}
	
	func testRemove() {
		let prefs = Prefs.standard
		
		prefs.edit().put(key: .isAlive, true).commit()
		prefs.edit().remove(key: .isAlive).commit()
		
		XCTAssert(prefs.dict[.isAlive] == nil)
		afterWrite(at: prefs) { (json) in
			XCTAssert(json[.isAlive] == nil)
		}
	}
	
	func testClear() {
		let prefs = Prefs.standard
		
		prefs.edit()
			.put(key: .name, "Gal")
			.put(key: .age, 26)
			.commit()
		
		prefs.edit().clear().commit()
		
		XCTAssert(prefs.dict.count == 0)
		XCTAssert(!FileSystem.fileExists(prefs.filename))
	}
	
	func testCodable() {
		let prefs = Prefs.standard
		
		let dict = ["one": 1, "two": 2]
		prefs.edit().put(key: .numbers, dict).commit()
		
		XCTAssert(dict == prefs.codable(key: .numbers))
		
		afterWrite(at: prefs) { json in
			XCTAssert(dict == .from(json: json[.numbers]!))
		}
	}
	
	func testParallelWrites() {
		let prefs = Prefs.standard
		let prefixes = ["Bubu", "Groot", "Deadpool"]
		let range = 0...9
		
		let expectation = XCTestExpectation(description: "for concurrent writing")
		expectation.expectedFulfillmentCount = prefixes.count
		for prefix in prefixes {
			async {
				for i in range {
					prefs.edit()
						.put(key: "\(prefix)-\(i)", i)
						.commit()
				}
				expectation.fulfill()
			}
		}
		wait(for: [expectation], timeout: 2)
		
		afterWrite(at: prefs) { json in
			XCTAssert(json.count == 30)
			
			for prefix in prefixes {
				for i in range {
					XCTAssert(json["\(prefix)-\(i)"] == "\(i)")
				}
			}
		}
	}
	
	private func afterWrite(at prefs: Prefs, test: @escaping ([String:String]) -> ()) {
		let expectation = XCTestExpectation(description: "wait to write to Prefs")
		
		Prefs.Editor.queue.async { //after written to storage
			let data = FileSystem.read(file: prefs.filename)!
			let json: [String: String] = .from(json: data)
			test(json)
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 2)
	}
	
	static var allTests = [
		("testInsert", testInsert),
		("testReplace", testReplace),
		("testRemove", testRemove),
		("testClear", testClear),
	]
	
}

fileprivate extension String {
	static let name = "name"
	static let age = "age"
	static let isAlive = "isAlive"
	static let numbers = "numbers"
}
