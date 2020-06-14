//
//  File.swift
//  Extensions
//
//  Created by Gal Yedidovich on 14/06/2020.
//

import Foundation

extension Encodable {
	/// encode in JSON encoding
	/// - Returns: JSON represention of data
	func json() -> Data {
		try! JSONEncoder().encode(self)
	}
}

extension Decodable {
	/// Decode data in JSON decoding
	/// - Parameter json: JSON encoded data
	/// - Returns: Generic Decodable value representing the JSON
	static func from <T: Decodable> (json: Data) -> T {
		try! JSONDecoder().decode(T.self, from: json)
	}
}
