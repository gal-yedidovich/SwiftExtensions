//
//  Basic.swift
//  Basic
//
//  Created by Gal Yedidovich on 15/06/2020.
//

import Foundation
import CryptoKit

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
public func async(quality: DispatchQoS.QoSClass = .default, block: @escaping ()->()) {
	DispatchQueue.global(qos: quality).async(execute: block)
}


public extension String {
	/// Initialize a string instance, in JSON format, from a given Encodable value
	/// - Parameter json: An encodable value that can be parsed into JSON string
	init(json: Encodable) {
		if let str = json as? String {
			self = str
		} else {
			self = String(decoding: json.json(), as: UTF8.self)
		}
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
	///computes file size at the URL, if exists
	var fileSize: UInt64? {
		try? FileManager.default.attributesOfItem(atPath: path)[.size] as? UInt64
	}
	
	/// computes wheter URL poins to a folder, if exists.
	var isDirectory: Bool {
		let values = try? resourceValues(forKeys: [.isDirectoryKey])
		return values?.isDirectory ?? false
	}
}

public extension HashFunction {
	/// Convenient method for hashing a file in the file system.
	///
	/// - Parameter url: file url in the file system.
	/// - Returns: Finalized Hash Digest or nil
	static func checksum(file url: URL) -> Self.Digest? {
		guard FileManager.default.fileExists(atPath: url.path),
			  !url.isDirectory, let input = InputStream(url: url) else {
			return nil
		}
		
		let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Self.blockByteCount)
		var hash = Self.init()
		
		input.open()
		defer { input.close() }
		
		while input.hasBytesAvailable {
			let bytesRead = input.read(buffer, maxLength: Self.blockByteCount)
			guard bytesRead > 0 else { break }
			let data = Data(bytes: buffer, count: bytesRead)
			hash.update(data: data)
		}
		
		return hash.finalize()
	}
}

public extension Digest {
	///create a hexadecimal string representation from the digest.
	var hexString: String {
		map { String(format: "%02x", $0) }.joined()
	}
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
