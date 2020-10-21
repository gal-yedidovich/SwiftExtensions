//
//  JsonObjectTests.swift
//  
//
//  Created by Gal Yedidovich on 21/10/2020.
//

import XCTest
@testable import BasicExtensions

final class JsonObjectTests: XCTestCase {
	func testCreateFromData() throws {
		let data = Data(basicJsonStr.utf8)
		let json = try JsonObject(from: data)
		XCTAssertEqual(json.dict.count, 3)
	}
	
	func testCreateFromString() throws {
		let json = try JsonObject(from: basicJsonStr)
		XCTAssertEqual(json.dict.count, 3)
	}
	
	func testCreateFromDict() {
		let json = JsonObject(from: ["name": "Bubu", "age": 10, "isAlive": false])
		XCTAssertEqual(json.dict.count, 3)
	}
	
	func testRead() throws {
		let json = try JsonObject(from: JsonStr2)
		
		XCTAssertEqual(json.string(key: "name"), "Bubu")
		XCTAssertEqual(json.int(key: "age"), 10)
		XCTAssertEqual(json.bool(key: "isAlive"), true)
		
		XCTAssertEqual(json["name"], "Bubu")
		let grades: [Int]? = json["grades"]
		let grades2: [Int]? = json.arr(key: "grades")
		XCTAssertEqual(grades, [10, 20, 30, 40, 50])
		XCTAssertEqual(grades2, [10, 20, 30, 40, 50])
		
		let companian = json.jsonObject(key: "companian")!
		XCTAssertEqual(companian.string(key: "name"), "Groot")
		XCTAssertEqual(companian.bool(key: "isAlive"), true)
	}
	
	func testWrite() {
		let json = JsonObject()
			.put(key: "name", "Deadpool")
			.put(key: "age", 3)
		
		XCTAssertEqual(json.dict.count, 2)
		XCTAssertEqual(json["name"], "Deadpool")
		XCTAssertEqual(json.int(key: "age"), 3)
	}
	
	func testIteration() throws {
		let json = try JsonObject(from: JsonStr2)
		
		var copyDict: [String: Any] = [:]
		for (key, value) in json {
			copyDict[key] = value
		}
		
		XCTAssertEqual(json.dict.count, copyDict.count)
	}
	
	func testDecodable() throws {
		var json = try JsonObject(from: JsonStr2)
		
		struct Companian: Codable {
			let name: String
			let isAlive: Bool
		}
		
		let comp: Companian? = try json.decodable(key: "companian") //decoding
		XCTAssertEqual(comp?.name, "Groot")
		XCTAssertEqual(comp?.isAlive, true)
		
		json["companian2"] = Companian(name: "Pickachu", isAlive: false)
		let comp2: Companian? = try json.decodable(key: "companian2") //casting
		XCTAssertEqual(comp2?.name, "Pickachu")
		XCTAssertEqual(comp2?.isAlive, false)
	}
	
	func testArray() throws {
		let arr = JsonArray()
			.append(1)
			.append(2)
			.append("3")
			.append(true)
		
		let str = "[1,2,\"3\",true]"
		
		let jsonStr = String(decoding: try arr.data(), as: UTF8.self)
		XCTAssertEqual(str, jsonStr)
		
		let arr2 = try JsonArray(from: str)
		XCTAssertEqual(arr2.int(at: 0), 1)
		XCTAssertEqual(arr2.int(at: 1), 2)
		XCTAssertEqual(arr2.string(at: 2), "3")
		XCTAssertEqual(arr2.bool(at: 3), true)
	}
	
	func testInnerArray() {
		let arr = JsonArray(from: [
			["0", "1", "2"],
			[1, 2, 3]
		])
		
		let innerJsonArr = arr.jsonArray(at: 0)!
		XCTAssertEqual(innerJsonArr.count, 3)
		for i in 0..<innerJsonArr.count {
			XCTAssertEqual(innerJsonArr.string(at: i), "\(i)")
		}
		
		let intArr = arr[1] as! [Int]
		XCTAssertEqual(intArr, [1, 2, 3])
	}
	
	static var allTests = [
		("testCreateFromData", testCreateFromData),
		("testCreateFromString", testCreateFromString),
		("testCreateFromDict", testCreateFromDict),
		("testRead", testRead),
		("testWrite", testWrite),
		("testIteration", testIteration),
		("testDecodable", testDecodable),
		("testInnerArray", testInnerArray),
	]
}

let basicJsonStr = """
{
	"name":"Bubu",
	"age":10,
	"isAlive":true
}
"""

let JsonStr2 = """
{
	"name":"Bubu",
	"age":10,
	"isAlive":true,
	"grades": [
		10,
		20,
		30,
		40,
		50
	],
	"companian": {
		"name": "Groot",
		"isAlive": true
	}
}
"""
