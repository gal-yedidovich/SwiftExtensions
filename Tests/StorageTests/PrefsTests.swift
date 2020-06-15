//
//  PrefsTest.swift
//  StorageTests
//
//  Created by Gal Yedidovich on 13/06/2020.
//

import XCTest
@testable import StorageExtensions

final class PrefsTests: XCTestCase {
	func testInsert() {
		let prefs = preparePrefs()
		
		prefs.edit()
			.put(key: "name", "Gal")
			.commit()
		
		XCTAssert(prefs.string(key: "name") == "Gal")
		
		afterWrite(at: prefs) { json in
			XCTAssert(json["name"] == "Gal")
		}
	}
	
	func testRemove() {
		let prefs = preparePrefs()
		
		prefs.edit()
			.put(key: "name", "Gal")
			.commit()
		
		prefs.edit()
			.remove(key: "name")
			.commit()
		
		XCTAssert(prefs.dict["name"] == nil)
		
		afterWrite(at: prefs) { (json) in
			XCTAssert(json.count == 0)
		}
	}
	
	func testReplace() {
		let prefs = preparePrefs()
		
		
		prefs.edit()
			.put(key: "name", "Gal")
			.put(key: "age", "26")
			.commit()
		
		prefs.edit()
			.put(key: "name", "Bubu")
			.commit()
		
		XCTAssert(prefs.dict["name"] == "Bubu")
		
		afterWrite(at: prefs) { json in
			XCTAssert(json["name"] == "Bubu")
		}
	}
	
	func testClear() {
		let prefs = preparePrefs()
		
		prefs.edit()
			.put(key: "name", "Gal")
			.put(key: "age", "26")
			.commit()
		
		prefs.edit().clear().commit()
		
		XCTAssert(prefs.dict.count == 0)
		XCTAssert(!FileSystem.fileExists(prefs.filename))
	}
	
	private func preparePrefs() -> Prefs {
		FileSystem.delete(file: .prefs)
		return Prefs.standard
	}
	
	private func afterWrite(at prefs: Prefs, test: @escaping ([String:String]) -> ()) {
		let expectation = XCTestExpectation(description: "wait to write to Prefs")
		
		Prefs.Editor.queue.async { //after written to storage
			let data = FileSystem.read(file: prefs.filename)!
			let json: [String: String] = .from(json: data)
			test(json)
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 5)
	}
	
	static var allTests = [
		("testInsert", testInsert),
		("testRemove", testRemove),
		("testReplace", testReplace),
		("testClear", testClear),
	]
	
}
