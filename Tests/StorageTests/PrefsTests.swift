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
	
	override func tearDownWithError() throws {
		prefs.strategy = Prefs.QueueStrategy(prefs: prefs)
		try prefs.queue.sync {
			try FileSystem.delete(file: prefs.filename)
			prefs.dict = [:]
		}
	}
	
	func testInsert() {
		prefs.edit().put(key: .name, "Gal").commit()
		
		XCTAssert(prefs.string(key: .name) == "Gal")
		afterWrite(at: prefs) { json in
			XCTAssert(json[PrefKey.name.value] == "Gal")
		}
	}
	
	func testReplace() {
		prefs.edit()
			.put(key: .name, "Gal")
			.put(key: .age, 26)
			.commit()
		
		prefs.edit().put(key: .name, "Bubu").commit()
		
		XCTAssert(prefs.string(key: .name) == "Bubu")
		afterWrite(at: prefs) { json in
			XCTAssert(json[PrefKey.name.value] == "Bubu")
		}
	}
	
	func testRemove() {
		prefs.edit().put(key: .isAlive, true).commit()
		prefs.edit().remove(key: .isAlive).commit()
		
		XCTAssert(prefs.dict[PrefKey.isAlive.value] == nil)
		afterWrite(at: prefs) { (json) in
			XCTAssert(json[PrefKey.isAlive.value] == nil)
		}
	}
	
	func testClear() {
		prefs.edit()
			.put(key: .name, "Gal")
			.put(key: .age, 26)
			.commit()
		
		prefs.edit().clear().commit()
		
		let expectation = XCTestExpectation(description: "wait to delete Prefs")
		prefs.queue.async {
			XCTAssert(prefs.dict.count == 0)
			XCTAssert(!FileSystem.fileExists(prefs.filename))
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 2)
	}
	
	func testCodable() {
		let dict = ["one": 1, "two": 2]
		prefs.edit().put(key: .numbers, dict).commit()
		
		XCTAssert(dict == prefs.codable(key: .numbers))
		
		afterWrite(at: prefs) { json in
			XCTAssert(dict == (try! .from(json: json[PrefKey.numbers.value]!)))
		}
	}
	
	func testParallelWrites() {
		let prefixes = ["Bubu", "Groot", "Deadpool"]
		let range = 0...9
		
		let expectation = XCTestExpectation(description: "for concurrent writing")
		expectation.expectedFulfillmentCount = prefixes.count
		for prefix in prefixes {
			async {
				for i in range {
					prefs.edit()
						.put(key: PrefKey(value: "\(prefix)-\(i)"), i)
						.commit()
				}
				expectation.fulfill()
			}
		}
		wait(for: [expectation], timeout: 2)
		
		afterWrite(at: prefs) { json in
			XCTAssert(json.count == prefixes.count * range.count)
			
			for prefix in prefixes {
				for i in range {
					XCTAssert(json["\(prefix)-\(i)"] == "\(i)")
				}
			}
		}
	}
	
	func testMultiplePrefs() {
		let prefs1 = Prefs(file: Filename(name: "prefs1"))
		let prefs2 = Prefs(file: Filename(name: "prefs2"))
		
		let e = XCTestExpectation(description: "waiting for concurrent prefs")
		async {
			prefs1.edit()
				.put(key: .name, "Bubu")
				.put(key: .age, 100)
				.commit()
			
			XCTAssert(prefs1.dict.count == 2)
			
			self.afterWrite(at: prefs1) { json in
				XCTAssert(json.count == 2)
			}
			
			e.fulfill()
		}
		wait(for: [e], timeout: 10)
		
		prefs2.edit()
			.put(key: .name, "Groot")
			.put(key: .age, 200)
			.put(key: .isAlive, true)
			.commit()
		
		XCTAssert(prefs2.dict.count == 3)
		
		afterWrite(at: prefs2) { json in
			XCTAssert(json.count == 3)
		}
		
		prefs1.edit().clear().commit()
		prefs2.edit().clear().commit()
	}
	
	func testStringAsCodable() {
		prefs.edit().put(key: .name, "Bubu").commit()
		
		let str1 = prefs.string(key: .name)
		let str2: String? = prefs.codable(key: .name)
		
		XCTAssertEqual(str1, str2)
	}
	
	func testBatchingStrategy() {
		prefs.strategy = Prefs.BatchStrategy(prefs: prefs)
		
		for i in 1...10 {
			prefs.edit().put(key: .age, i).commit()
			XCTAssertEqual(prefs.int(key: .age), i)
		}
		
		
		let expectation = XCTestExpectation(description: "wait to write batch to Prefs")
		prefs.queue.asyncAfter(deadline: .now() + 0.5) {
			self.check(prefs, expectation) { json in
				XCTAssertEqual(json[PrefKey.age.value], "10")
			}
		}
		wait(for: [expectation], timeout: 10)
	}
	
	private func afterWrite(at prefs: Prefs, test: @escaping TestHandler) {
		let expectation = XCTestExpectation(description: "wait to write to Prefs")
		
		prefs.queue.async { //after written to storage
			self.check(prefs, expectation, test: test)
		}
		
		wait(for: [expectation], timeout: 10)
	}
	
	private func check(_ prefs: Prefs, _ expectation: XCTestExpectation, test: @escaping TestHandler) {
		defer { expectation.fulfill() }
		guard let data = FileSystem.read(file: prefs.filename) else {
			XCTFail("could not read file: \(prefs.filename.value)")
			return
		}
		guard let json: [String: String] = try? .from(json: data) else {
			XCTFail("could not decode file: \(prefs.filename.value)")
			return
		}
		test(json)
	}
	
	static var allTests = [
		("testInsert", testInsert),
		("testReplace", testReplace),
		("testRemove", testRemove),
		("testClear", testClear),
		("testCodable", testCodable),
		("testParallelWrites", testParallelWrites),
		("testMultiplePrefs", testMultiplePrefs),
		("testStringAsCodable", testStringAsCodable),
	]
}

fileprivate typealias TestHandler = ([String:String]) -> Void

fileprivate let prefs = Prefs.standard

fileprivate extension PrefKey {
	static let name = PrefKey(value: "name")
	static let age = PrefKey(value: "age")
	static let isAlive = PrefKey(value: "isAlive")
	static let numbers = PrefKey(value: "numbers")
}
