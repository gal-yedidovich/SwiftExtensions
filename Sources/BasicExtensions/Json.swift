//
//  Json.swift
//  
//
//  Created by Gal Yedidovich on 21/10/2020.
//

import Foundation

//MARK: - serialization
public struct JsonObject {
	var dict: [String: Any]
	
	public init(from dict: [String: Any] = [:]) {
		self.dict = dict
	}
	
	public init(data: Data) throws {
		let json = try JSONSerialization.jsonObject(with: data)
		guard let dict = json as? [String: Any] else { throw JsonErrors.wrongType }
		
		self.init(from: dict)
	}
	
	public init(string: String) throws {
		try self.init(data: Data(string.utf8))
	}
	
	public init(encodable: Encodable) throws {
		try self.init(data: encodable.json())
	}
	
	public func data(options: JSONSerialization.WritingOptions = []) throws -> Data {
		try JSONSerialization.data(withJSONObject: dict, options: options)
	}
}

//MARK: - read & write
public extension JsonObject {
	func string(key: String) -> String? {
		dict[key] as? String
	}
	
	func int(key: String) -> Int? {
		dict[key] as? Int
	}
	
	func bool(key: String) -> Bool? {
		dict[key] as? Bool
	}
	
	func arr<Value: Any>(key: String) -> [Value]? {
		dict[key] as? [Value]
	}
	
	func jsonObject(key: String) -> JsonObject? {
		guard let innerDict = dict[key] as? [String: Any] else { return nil }
		
		return JsonObject(from: innerDict)
	}
	
	func jsonArray(key: String) -> JsonArray? {
		guard let arr = dict[key] as? [Any] else { return nil }
		
		return JsonArray(from: arr)
	}
	
	func codable<Value: Decodable>(key: String, as: Value.Type = Value.self) throws -> Value? {
		guard let value = dict[key] else { return nil }
		if let v = value as? Value { return v }
		
		let data = try JSONSerialization.data(withJSONObject: value)
		return try .from(json: data)
	}
	
	subscript<Value>(key: String) -> Value? {
		get { dict[key] as? Value }
		set {
			precondition(newValue != nil)
			dict[key] = unwrap(value: newValue!)
		}
	}
	
	@discardableResult
	func with(key: String, _ value: Any) -> JsonObject {
		var copy = self
		copy.put(key: key, value)
		return copy
	}
	
	@discardableResult
	func removing(key: String) -> JsonObject {
		var copy = self
		copy.remove(key: key)
		return copy
	}
	
	mutating func put(key: String, _ value: Any) {
		dict[key] = unwrap(value: value)
	}
	
	mutating func remove(key: String) {
		dict.removeValue(forKey: key)
	}
}

extension JsonObject: Sequence {
	public func makeIterator() -> Dictionary<String, Any>.Iterator {
		dict.makeIterator()
	}
}

extension JsonObject: CustomDebugStringConvertible {
	public var debugDescription: String {
		if dict.isEmpty { return "{}" }
		
		return String(decoding: try! data(options: .prettyPrinted), as: UTF8.self)
	}
}

public struct JsonArray {
	var array: [Any]
	
	public init(from array: [Any] = []) {
		self.array = array
	}
	
	public init(data: Data) throws {
		let json = try JSONSerialization.jsonObject(with: data)
		guard let arr = json as? [Any] else { throw JsonErrors.wrongType }
		
		self.init(from: arr)
	}
	
	public init(string: String) throws {
		try self.init(data: Data(string.utf8))
	}
	
	public init(encodable: Encodable) throws {
		try self.init(data: encodable.json())
	}
	
	public func data(options: JSONSerialization.WritingOptions = []) throws -> Data {
		try JSONSerialization.data(withJSONObject: array, options: options)
	}
}

public extension JsonArray {
	func string(at index: Int) -> String? {
		array[index] as? String
	}
	
	func int(at index: Int) -> Int? {
		array[index] as? Int
	}
	
	func bool(at index: Int) -> Bool? {
		array[index] as? Bool
	}
	
	func jsonObject(at index: Int) -> JsonObject? {
		guard let dict = array[index] as? [String: Any] else { return nil }
		return JsonObject(from: dict)
	}
	
	func jsonArray(at index: Int) -> JsonArray? {
		guard let array = array[index] as? [Any] else { return nil }
		return JsonArray(from: array)
	}
	
	mutating func append(_ value: Any) {
		array.append(unwrap(value: value))
	}
	
	mutating func insert(_ value: Any, at index: Int) {
		array.insert(unwrap(value: value), at: index)
	}
	
	mutating func remove(at index: Int) {
		array.remove(at: index)
	}
	
	func appended(_ value: Any) -> JsonArray {
		var copy = self
		copy.append(value)
		return copy
	}
	
	func inserted(_ value: Any, at index: Int) -> JsonArray {
		var copy = self
		copy.insert(value, at: index)
		return copy
	}
	
	func removed(at index: Int) -> JsonArray {
		var copy = self
		copy.remove(at: index)
		return copy
	}
}

extension JsonArray: MutableCollection {
	public typealias Element = Any
	public typealias Index = Int
	
	public var startIndex: Int { array.startIndex }
	
	public var endIndex: Int { array.endIndex }
	
	public subscript(position: Index) -> Element {
		get { array[position] }
		set { array[position] = unwrap(value: newValue) }
	}
	
	public func index(after i: Int) -> Int {
		array.index(after: i)
	}
	
	public func makeIterator() -> Array<Any>.Iterator {
		array.makeIterator()
	}
}

extension JsonArray: CustomDebugStringConvertible {
	public var debugDescription: String {
		if array.isEmpty { return "[]" }
		
		return String(decoding: try! data(options: .prettyPrinted), as: UTF8.self)
	}
}

enum JsonErrors: Error {
	case wrongType
}

fileprivate func unwrap(value: Any) -> Any {
	switch value {
	case let arr as JsonArray: return arr.array.map(unwrap(value:))
	case let array as [Any]: return array.map(unwrap(value:))
	case let obj as JsonObject: return obj.dict.mapValues(unwrap(value:))
	case let dict as [String: Any]: return dict.mapValues(unwrap(value:))
	default: return value
	}
}
