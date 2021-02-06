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
	
	/// cache encryption key from keychain.
	private static var key: SymmetricKey?
	
	/// Encrypt data with CGM encryption, and returns the encrypted data in result
	/// - Parameter data: the data to encrypt
	/// - Returns: encrypted data
	public static func encrypt(data: Data) throws -> Data {
		let key = try getKey()
		return try AES.GCM.seal(data, using: key).combined!
	}
	
	/// Deccrypt data with CGM decryption, and returns the original (clear-text) data in result
	/// - Parameter data: Encrypted data to decipher.
	/// - Throws: check exception
	/// - Returns: original, Clear-Text data
	public static func decrypt(data: Data) throws -> Data {
		let box = try AES.GCM.SealedBox(combined: data)
		let key = try getKey()
		return try AES.GCM.open(box, using: key)
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
		let fm = FileManager.default
		
		let tempDir = fm.temporaryDirectory
		try fm.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
		let tempFile = tempDir.appendingPathComponent(UUID().uuidString)
		
		let input = InputStream(url: src)!
		let output = OutputStream(url: tempFile, append: false)!
		let fileSize = src.fileSize!
		var offset: Int = 0
		
		output.open()
		defer { output.close() }
		
		let bufferSize = isEncryption ? BUFFER_SIZE : BUFFER_SIZE + 28
		let method = isEncryption ? encrypt(data:) : decrypt(data:)
		
		try input.readAll(bufferSize: bufferSize) { buffer, bytesRead in
			offset += bytesRead
			onProgress?(Int((offset * 100) / fileSize))
			let data = Data(bytes: buffer, count: bytesRead)
			output.write(data: try method(data))
		}
		
		if fm.fileExists(atPath: dest.path) {
			try fm.removeItem(at: dest)
		}
		
		try fm.moveItem(at: tempFile, to: dest)
	}
	
	/// Encryption key for cipher operations, lazy loaded, it will get the current key in Keychain or will generate new one.
	private static func getKey() throws -> SymmetricKey {
		if let key = key { return key }
		
		var query = keyChainQuery
		query[kSecReturnData] = true
		
		var item: CFTypeRef? //reference to the result
		let readStatus = SecItemCopyMatching(query as CFDictionary, &item)
		switch readStatus {
		case errSecSuccess: return SymmetricKey(data: item as! Data) // Convert back to a key.
		case errSecItemNotFound: return try storeNewKey()
		default: throw Errors.fetchKeyError(readStatus)
		}
	}
	
	/// Generate a new Symmetric encryption key and stores it in the Keychain
	/// - Returns: newly created encryption key.
	private static func storeNewKey() throws -> SymmetricKey {
		let key = SymmetricKey(size: .bits256) //create new key
		var query = keyChainQuery
		query[kSecAttrAccessible] = keyAccessibility
		query[kSecValueData] = key.dataRepresentation //request to get the result (key) as data
		
		let status = SecItemAdd(query as CFDictionary, nil)
		guard status == errSecSuccess else {
			throw Errors.storeKeyError(status)
		}
		
		return key
	}
	
	private enum Errors: LocalizedError {
		case fetchKeyError(OSStatus)
		case storeKeyError(OSStatus)
		
		var errorDescription: String? {
			switch self {
			case .fetchKeyError(let status):
				return "unable to fetch key, os-status: '\(status)'"
			case .storeKeyError(let status):
				return "Unable to store key, os-status: '\(status)'"
			}
		}
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
