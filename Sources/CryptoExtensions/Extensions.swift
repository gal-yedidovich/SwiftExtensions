//
//  Extensions.swift
//  
//
//  Created by Gal Yedidovich on 17/04/2021.
//

import Foundation
import CryptoKit

extension Data {
	/// Returns data after `xor` operation. it will change each byte of the byte array.
	/// - Parameters:
	///   - data: the main operand, the data which is "xorred"
	///   - xor: a `xor` operand.
	/// - Returns: manipulated copy of the data after the operation.
	public static func ^(data: Data, xor: UInt8) -> Data {
		return Data(data.map { $0 ^ xor })
	}
	
	internal var bytes: [UInt8] { [UInt8](self) }
}

public extension String {
	/// Returns data after `xor` operation. it will change each byte of the byte array.
	/// - Parameters:
	///   - data: the main operand, the data which is "xorred"
	///   - xor: a `xor` operand.
	/// - Returns: manipulated copy of the data after the operation.
	static func ^(string: String, xor: UInt8) -> String {
		let xorred = Data(string.utf8) ^ xor
		return String(decoding: xorred, as: UTF8.self)
	}
}

public extension SymmetricKey {
	/// A Data instance created safely from the contiguous bytes without making any copies.
	var dataRepresentation: Data {
		return withUnsafeBytes { bytes in
			let cfdata = CFDataCreateWithBytesNoCopy(nil, bytes.baseAddress?.assumingMemoryBound(to: UInt8.self), bytes.count, kCFAllocatorNull)
			return (cfdata as Data?) ?? Data()
		}
	}
}
