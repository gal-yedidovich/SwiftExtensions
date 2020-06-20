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
	
	override func setUp() { //before each test
		FileSystem.delete(file: .prefs)
	}
	
	func testInsert() {
		let prefs = Prefs.standard
		
		prefs.edit()
			.put(key: "name", "Gal")
			.commit()
		
		XCTAssert(prefs.string(key: "name") == "Gal")
		
		afterWrite(at: prefs) { json in
			XCTAssert(json["name"] == "Gal")
		}
	}
	
	func testReplace() {
		let prefs = Prefs.standard
		
		prefs.edit()
			.put(key: "name", "Gal")
			.put(key: "age", 26)
			.commit()
		
		prefs.edit()
			.put(key: "name", "Bubu")
			.commit()
		
		XCTAssert(prefs.dict["name"] == "Bubu")
		
		afterWrite(at: prefs) { json in
			XCTAssert(json["name"] == "Bubu")
		}
	}
	
	func testRemove() {
		let prefs = Prefs.standard
		
		prefs.edit()
			.put(key: "test", true)
			.commit()
		
		prefs.edit()
			.remove(key: "test")
			.commit()
		
		XCTAssert(prefs.dict["test"] == nil)
		
		afterWrite(at: prefs) { (json) in
			XCTAssert(json["test"] == nil)
		}
	}
	
	func testClear() {
		let prefs = Prefs.standard
		
		prefs.edit()
			.put(key: "name", "Gal")
			.put(key: "age", 26)
			.commit()
		
		prefs.edit().clear().commit()
		
		XCTAssert(prefs.dict.count == 0)
		XCTAssert(!FileSystem.fileExists(prefs.filename))
	}
	
	func testCodable() {
		let prefs = Prefs.standard
		
		let dict = ["one": 1, "two": 2]
		prefs.edit()
			.put(key: "codable", dict)
			.commit()
		
		XCTAssert(dict == prefs.codable(key: "codable"))
		
		afterWrite(at: prefs) { json in
			XCTAssert(dict == .from(json: json["codable"]!))
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
