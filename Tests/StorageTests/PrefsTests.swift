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
	
	func testInsert() throws {
		let prefs = createPrefs(name: #function)
		prefs.edit().put(key: .name, "Gal").commit()
		
		XCTAssertEqual(prefs.string(key: .name), "Gal")
		afterWrite(at: prefs) { json in
			XCTAssertEqual(json[PrefKey.name.value], "Gal")
		}
		
		try teardown(prefs)
	}
	
	func testReplace() throws {
		let prefs = createPrefs(name: #function)
		
		prefs.edit()
			.put(key: .name, "Gal")
			.put(key: .age, 26)
			.commit()
		
		prefs.edit().put(key: .name, "Bubu").commit()
		
		XCTAssertEqual(prefs.string(key: .name), "Bubu")
		afterWrite(at: prefs) { json in
			XCTAssertEqual(json[PrefKey.name.value], "Bubu")
		}
		
		try teardown(prefs)
	}
	
	func testRemove() throws {
		let prefs = createPrefs(name: #function)
		
		prefs.edit()
			.put(key: .name, "Bubu")
			.put(key: .isAlive, true)
			.commit()
		
		prefs.edit().remove(key: .isAlive).commit()
		
		XCTAssertEqual(prefs.dict[PrefKey.isAlive.value], nil)
		afterWrite(at: prefs) { (json) in
			XCTAssertEqual(json[PrefKey.isAlive.value], nil)
		}
		
		try teardown(prefs)
	}
	
	func testClear() throws {
		let prefs = createPrefs(name: #function)
		
		prefs.edit()
			.put(key: .name, "Gal")
			.put(key: .age, 26)
			.commit()
		
		prefs.edit().clear().commit()
		
		let expectation = XCTestExpectation(description: "wait to delete Prefs")
		prefs.queue.async {
			XCTAssertEqual(prefs.dict.count, 0)
			XCTAssertFalse(FileSystem.fileExists(prefs.filename))
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 2)
		
		try teardown(prefs)
	}
	
	func testCodable() throws {
		let prefs = createPrefs(name: #function)
		
		let dict = ["one": 1, "two": 2]
		prefs.edit().put(key: .numbers, dict).commit()
		
		XCTAssertEqual(dict, prefs.codable(key: .numbers))
		
		afterWrite(at: prefs) { json in
			do {
				guard let dictStr = json[PrefKey.numbers.value] else {
					XCTFail("numbers dictionary is nil")
					return
				}
				
				let dict2: [String: Int] = try .from(json: dictStr)
				XCTAssertEqual(dict, dict2)
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
		
		try teardown(prefs)
	}
	
	func testParallelWrites() throws {
		let prefs = createPrefs()
		
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
			XCTAssertEqual(json.count, prefixes.count * range.count)
			
			for prefix in prefixes {
				for i in range {
					XCTAssertEqual(json["\(prefix)-\(i)"], "\(i)")
				}
			}
		}
		
		try teardown(prefs)
	}
	
	func testMultiplePrefs() throws {
		let prefs1 = createPrefs(name: #function + "1")
		let prefs2 = createPrefs(name: #function + "2")
		
		let e = XCTestExpectation(description: "waiting for concurrent prefs")
		async {
			prefs1.edit()
				.put(key: .name, "Bubu")
				.put(key: .age, 100)
				.commit()
			
			XCTAssertEqual(prefs1.dict.count, 2)
			
			self.afterWrite(at: prefs1) { json in
				XCTAssertEqual(json.count, 2)
			}
			
			e.fulfill()
		}
		wait(for: [e], timeout: 10)
		
		prefs2.edit()
			.put(key: .name, "Groot")
			.put(key: .age, 200)
			.put(key: .isAlive, true)
			.commit()
		
		XCTAssertEqual(prefs2.dict.count, 3)
		
		afterWrite(at: prefs2) { json in
			XCTAssertEqual(json.count, 3)
		}
		
		try teardown(prefs1, prefs2)
	}
	
	func testStringAsCodable() throws {
		let prefs = createPrefs(name: #function)
		
		prefs.edit().put(key: .name, "Bubu").commit()
		
		let str1 = prefs.string(key: .name)
		let str2: String? = prefs.codable(key: .name)
		
		XCTAssertEqual(str1, str2)
		
		try teardown(prefs)
	}
	
	func testBatchingStrategy() throws {
		let prefs = createPrefs(name: #function, strategy: .batch)
		
		for i in 1...10 {
			prefs.edit().put(key: .age, i).commit()
			XCTAssertEqual(prefs.int(key: .age), i)
		}
		
		let expectation = XCTestExpectation(description: "wait to write batch to Prefs")
		prefs.queue.asyncAfter(deadline: .now() + DEFAULT_BATCH_DELAY) {
			self.check(prefs, expectation) { json in
				XCTAssertEqual(json[PrefKey.age.value], "10")
			}
		}
		wait(for: [expectation], timeout: 10)
		
		try teardown(prefs)
	}
	
	func testContains() throws {
		let prefs = createPrefs(name: #function)
		
		prefs.edit()
			.put(key: .age, 10)
			.put(key: .name, "gal")
			.commit()
		
		XCTAssert(prefs.contains(.age))
		XCTAssert(prefs.contains(.age, .name))
		XCTAssertFalse(prefs.contains(.isAlive))
		XCTAssertFalse(prefs.contains(.age, .name, .isAlive))
		
		try teardown(prefs)
	}
	
	func testObservers() throws {
		let prefs = createPrefs(name: #function)
		var didNotify = [false, false]
		
		let key1 = prefs.observe { didNotify[0] = true }
		let key2 = prefs.observe { didNotify[1] = true }
		
		prefs.edit().put(key: .name, "gal").commit()
		
		XCTAssertTrue(didNotify[0])
		XCTAssertTrue(didNotify[1])
		prefs.removeObservers(withKeys: key1, key2)
		
		try teardown(prefs)
	}
}
	
extension PrefsTests {
	private func createPrefs(name: String = #function, strategy: Prefs.WriteStrategyType = .immediate) -> Prefs {
		Prefs(file: Filename(name: name), writeStrategy: strategy)
	}
	
	private func teardown(_ prefs: Prefs...) throws {
		for p in prefs {
			try p.queue.sync {
				try FileSystem.delete(file: p.filename)
			}
		}
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
		guard let data = try? FileSystem.read(file: prefs.filename) else {
			XCTFail("could not read file: \(prefs.filename.value)")
			return
		}
		guard let json: [String: String] = try? .from(json: data) else {
			XCTFail("could not decode file: \(prefs.filename.value)")
			return
		}
		test(json)
	}
}

fileprivate typealias TestHandler = ([String:String]) -> Void

fileprivate extension PrefKey {
	static let name = PrefKey(value: "name")
	static let age = PrefKey(value: "age")
	static let isAlive = PrefKey(value: "isAlive")
	static let numbers = PrefKey(value: "numbers")
}
