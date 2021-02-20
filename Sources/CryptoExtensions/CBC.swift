//
//  CBC.swift
//  
//
//  Created by Gal Yedidovich on 20/02/2021.
//

import Foundation
import CryptoKit
import CommonCrypto
import BasicExtensions

public extension AES {
	/// The Advanced Encryption Standard (AES) Cipher Block Chaining (CBC) cipher suite.
	enum CBC {
		/// Encrypt data using CBC algorithm with PKCS7 padding
		/// - Parameters:
		///   - data: the data to encrypt
		///   - key: a symmetric key for encryption
		///   - iv: initial vector data
		/// - Throws: when fails to encrypt
		/// - Returns: encrypted data
		public static func encrypt(_ data: Data, using key: SymmetricKey, iv: Data, options: CCOptions = pkcs7Padding) throws -> Data {
			try process(data, using: key, iv: iv, operation: kCCEncrypt, options: options)
		}
		
		/// Decrypts encrypted data using CBC algorithm with PKCS7 padding
		/// - Parameters:
		///   - data: encrypted data to decrypt
		///   - key: a symmetric key for encryption
		///   - iv: initial vector data
		/// - Throws: when fails to decrypt
		/// - Returns: clear text data after decryption
		public static func decrypt(_ data: Data, using key: SymmetricKey, iv: Data, options: CCOptions = pkcs7Padding) throws -> Data {
			try process(data, using: key, iv: iv, operation: kCCDecrypt, options: options)
		}
		
		/// Process data, either encrypt or decrypt it
		private static func process(_ data: Data, using key: SymmetricKey, iv: Data, operation: Int, options: CCOptions) throws -> Data {
			let rawData = [UInt8](data)
			let keyData = [UInt8](key.dataRepresentation)
			let ivData = [UInt8](iv)
			
			let bufferSize = rawData.count + kCCBlockSizeAES128
			var buffer = [UInt8](repeating: 0, count: bufferSize)
			var numBytesProcessed = 0
			
			let cryptStatus = CCCrypt(
				CCOperation(operation), CCAlgorithm(kCCAlgorithmAES), options, //params
				keyData, keyData.count, ivData, rawData, rawData.count, //input data
				&buffer, bufferSize, &numBytesProcessed //output data
			)
			
			
			guard cryptStatus == CCCryptorStatus(kCCSuccess) else {
				throw CBCError(message: "Operation Failed", status: cryptStatus)
			}
			
			buffer.removeSubrange(numBytesProcessed..<buffer.count)
			return Data(buffer)
		}
		
		public static var pkcs7Padding: CCOptions { CCOptions(kCCOptionPKCS7Padding) }
	}
}
