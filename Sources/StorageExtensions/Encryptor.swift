//
//  Encryptor.swift
//  Storage
//
//  Created by Gal Yedidovich on 15/06/2020.
//

import Foundation
import CryptoKit

internal let BUFFER_SIZE = 1024 * 32

/// An interface to cipher sensetive infomation using GCM encryption.
///
/// The `Encryptor` class provides basic cipher (encryption & decryption) operations on `Data` or files, using the `CryptoKit` framework.
/// All cipher operations are using a Symmetric key that is stored in the device's KeyChain. 
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
	
	/// This value control when the encryption key is accessible
	///
	/// This value is used when storing a newly created key in the Keychain. Since the key is resued this value is used once, as long as the key is exists in the Keychain.
	public static var keyAccessibility = kSecAttrAccessibleAfterFirstUnlock
	
	/// Encrypt data with CGM encryption, and returns the encrypted data in result
	/// - Parameter data: the data to encrypt
	/// - Returns: encrypted data
	public static func encrypt(data: Data) throws -> Data {
		try AES.GCM.seal(data, using: key).combined!
	}
	
	/// Deccrypt data with CGM decryption, and returns the original (clear-text) data in result
	/// - Parameter data: Encrypted data to decipher.
	/// - Throws: check exception
	/// - Returns: original, Clear-Text data
	public static func decrypt(data: Data) throws -> Data {
		try AES.GCM.open(try AES.GCM.SealedBox(combined: data), using: key)
	}
	
	/// Encrypt a file and save the encrypted content in a different file, this function let you encrypt scaleable chunck of content without risking memory to run out
	/// - Parameters:
	///   - src: source file to encrypt
	///   - dest: destination file to save the encrypted content
	///   - onProgress: a  progress event to track the progress of the writing
	public static func encrypt(file src: URL, to dest: URL, onProgress: ((Int)->())? = nil) throws {
		try process(file: src, to: dest, encrypt: true, onProgress: onProgress)
	}
	
	/// Decrypt a file and save the "clear text" content in a different file, this function let you decrypt scaleable chunck of content without risking memory to run out
	/// - Parameters:
	///   - src: An encrypted, source file to decrypt
	///   - dest: destination file to save the decrypted content
	///   - onProgress: a  progress event to track the progress of the writing
	public static func decrypt(file src: URL, to dest: URL, onProgress: ((Int)->())? = nil) throws {
		try process(file: src, to: dest, encrypt: false, onProgress: onProgress)
	}
	
	/// Streaming a cipher action from source file to destination file, and updating progress.
	/// - Parameters:
	///   - src: source file to cipher
	///   - dest: destination file to write processed data
	///   - isEncryption: flag for determinating to encrypt or decrypt
	///   - onProgress: a  progress event to track the progress of the writing
	private static func process(file src: URL, to dest: URL, encrypt isEncryption: Bool, onProgress: ((Int)->())?) throws {
		let bufferSize = isEncryption ? BUFFER_SIZE : BUFFER_SIZE + 28
		let fm = FileManager.default
		
		let tempDir = fm.temporaryDirectory
		try! fm.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
		let tempFile = tempDir.appendingPathComponent(UUID().uuidString)
		
		let input = InputStream(url: src)!
		let output = OutputStream(url: tempFile, append: false)!
		let fileSize = src.fileSize!
		var offset: UInt64 = 0
		
		output.open()
		defer { output.close() }
		
		try input.readAll(bufferSize: bufferSize) { (bytesRead, buffer) in
			offset += UInt64(bytesRead)
			onProgress?(Int((offset * 100) / fileSize))
			let data = Data(bytes: buffer, count: bytesRead)
			let processedData = isEncryption ? try encrypt(data: data) : try decrypt(data: data)
			output.write(data: processedData)
		}
		
		if fm.fileExists(atPath: dest.path) {
			try fm.removeItem(at: dest)
		}
		
		try fm.moveItem(at: tempFile, to: dest)
	}
	
	/// Encryption key for cipher operations, lazy loaded, it will get the current key in Keychain or will generate new one.
	private static var key: SymmetricKey = {
		var query = keyChainQuery
		query[kSecReturnData] = true
		
		var item: CFTypeRef? //reference to the result
		let readStatus = SecItemCopyMatching(query as CFDictionary, &item)
		switch readStatus {
			case errSecSuccess: return SymmetricKey(data: item as! Data) // Convert back to a key.
			case errSecItemNotFound: return storeNewKey()
			default: fatalError("unable to fetch key. error: '\(readStatus)'")
		}
	}()
	
	/// Generate a new Symmetric encryption key and stores it in the Keychain
	/// - Returns: newly created encryption key.
	private static func storeNewKey() -> SymmetricKey {
		let key = SymmetricKey(size: .bits256) //create new key
		var query = keyChainQuery
		query[kSecAttrAccessible] = keyAccessibility
		query[kSecValueData] = key.dataRepresentation //request to get the result (key) as data
		
		let status = SecItemAdd(query as CFDictionary, nil)
		guard status == errSecSuccess else {
			fatalError("Unable to store key, error: '\(status)'")
		}
		
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
