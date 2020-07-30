//
//  Basic.swift
//  Basic
//
//  Created by Gal Yedidovich on 15/06/2020.
//

import Foundation

public extension String {
	/// Initialize a string instance, in JSON format, from a given Encodable value
	/// - Parameter json: An encodable value that can be parsed into JSON string
	init(json: Encodable) {
		self = String(decoding: json.json(), as: UTF8.self)
	}
	
	/// get the localized version of a given string, using the string value as key.
	var localized: String {
		NSLocalizedString(self, comment: self)
	}
}

public extension DateFormatter {
	
	/// Initialize new instance with string format
	/// - Parameter format: date fromat string
	convenience init(format: String) {
		self.init()
		dateFormat = format
	}
}

public extension URL {
	///computes file size at the url, if exists
	var fileSize: UInt64? {
		try? FileManager.default.attributesOfItem(atPath: path)[.size] as? UInt64
	}
}

/// Run a block of code in the main thread, with a delay if exists
/// - Parameters:
///   - delay: time to wait before running the task
///   - block: a completion handler to run in the main thread
public func post(delay: TimeInterval? = nil, block: @escaping ()->()) {
	if let delay = delay {
		DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
	} else {
		DispatchQueue.main.async(execute: block)
	}
}

/// Run a block of code in a backgorund thread, the thread is controlled by GCD
/// - Parameter block: a completion handler to run in the background
public func async(quality: DispatchQoS.QoSClass = .background, block: @escaping ()->()) {
	DispatchQueue.global(qos: quality).async(execute: block)
}

public extension Encodable {
	/// encode in JSON encoding
	/// - Returns: JSON represention of data
	func json() -> Data {
		try! JSONEncoder().encode(self)
	}
}

public extension Decodable {
	/// Decode data in JSON decoding
	/// - Parameter json: JSON encoded data
	/// - Returns: Generic Decodable value representing the JSON
	static func from <T: Decodable> (json: Data) throws -> T {
		try JSONDecoder().decode(T.self, from: json)
	}
	/// Decode data in JSON decoding
	/// - Parameter json: JSON encoded string
	/// - Returns: Generic Decodable value representing the JSON
	static func from <T: Decodable> (json: String) throws -> T {
		try from(json: Data(json.utf8))
	}
}
