//
//  Encryptor.swift
//  Storage
//
//  Created by Gal Yedidovich on 15/06/2020.
//

import Foundation
import CryptoKit

public class Encryptor {
	private init() {}
	
	/// A Dictionary, representing query ths is used to store & fetch the encryption key.
	/// 
	/// You can change this value to as you see fit, default value is:
	/// ```
	/// [
	///	    kSecClass: kSecClassGenericPassword,
	///	    kSecAttrService: "encryption key",
	///     kSecAttrAccount: "SwiftStorage"
	/// ]
	/// ```
	public static var keyChainQuery: [CFString : Any] = [
		kSecClass: kSecClassGenericPassword,
		kSecAttrService: "encryption key", //role
		kSecAttrAccount: "SwiftStorage", //login
	]
	
	/// Encrypt data with CGM encryption, and returns the encrypted data in result
	/// - Parameter data: the data to encrypt
	/// - Returns: encrypted data
	public static func encrypt(data: Data) -> Data {
		try! AES.GCM.seal(data, using: key).combined!
	}
	
	/// Deccrypt data with CGM decryption, and returns the original (clear-text) data in result
	/// - Parameter data: Encrypted data to decipher.
	/// - Throws: check exception
	/// - Returns: original, Clear-Text data
	public static func decrypt(data: Data) throws -> Data {
		try AES.GCM.open(try AES.GCM.SealedBox(combined: data), using: key)
	}
	
	/// Encryption key for cipher operations, lazy loaded, it will get the current key in Keychain or will generate new one.
	private static var key: SymmetricKey = {
		var query = keyChainQuery
		query[kSecReturnData] = true
		
		var item: CFTypeRef? //reference to the result
		let readStatus = SecItemCopyMatching(query as CFDictionary, &item)
		if readStatus == errSecSuccess {
			return SymmetricKey(data: item as! Data) // Convert back to a key.
		}
		
		return storeNewKey()
	}()
	
	/// Generate a new Symmetric encryption key and stores it in the Keychain
	/// - Returns: newly created encryption key.
	private static func storeNewKey() -> SymmetricKey {
		let key = SymmetricKey(size: .bits256) //create new key
		var query = keyChainQuery
		query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
		query[kSecValueData] = key.dataRepresentation //request to get the result (key) as data

		let _ = SecItemAdd(query as CFDictionary, nil)
//		guard status == errSecSuccess else {
//			fatalError("Unable to store item \(addStatus)")
//		}
		
		return key
	}
	
	/// convenince `xor` method for byte operation on given data. it will change each byte in the data (byte array) and will return the result.
	/// - Parameters:
	///   - src: Data to manipulate with `xor` operation
	///   - xor: an integer to fo the `xor` with.
	/// - Returns: manipulated data after the operation.
	public static func xor(_ src: Data, with xor: UInt8) -> Data {
		Data(src.map { byte in byte ^ xor })
	}
}

extension SymmetricKey {
    /// A Data instance created safely from the contiguous bytes without making any copies.
    var dataRepresentation: Data {
        return withUnsafeBytes { bytes in
            let cfdata = CFDataCreateWithBytesNoCopy(nil, bytes.baseAddress?.assumingMemoryBound(to: UInt8.self), bytes.count, kCFAllocatorNull)
            return ((cfdata as NSData?) as Data?) ?? Data()
        }
    }
}

