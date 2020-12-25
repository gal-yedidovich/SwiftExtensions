//
//  EncryptorTests.swift
//  StorageTests
//
//  Created by Gal Yedidovich on 13/06/2020.
//

import XCTest
import CryptoKit
@testable import StorageExtensions

final class EncryptorTests: XCTestCase {
	func testEncryption() throws {
		let str = "Bubu is the king"
		let data = Data(str.utf8)
		
		let enc = try Encryptor.encrypt(data: data)
		let dec = try Encryptor.decrypt(data: enc)
		
		let strTest = String(decoding: dec, as: UTF8.self)
		XCTAssert(str == strTest)
	}
	
	func testStreams() throws {
		let str = [String](repeating: "Bubu is the king", count: 5000).joined(separator: "\n")
		
		let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		let url = baseURL.appendingPathComponent("data.txt")
		let encUrl = baseURL.appendingPathComponent("enc_data.txt")
		let decUrl = baseURL.appendingPathComponent("dec_data.txt")
		
		try Data(str.utf8).write(to: url)
		try Encryptor.encrypt(file: url, to: encUrl)
		try Encryptor.decrypt(file: encUrl, to: decUrl)
		let str2 = try String(contentsOf: decUrl)
		XCTAssert(str == str2)
		
		try FileManager.default.removeItem(at: url)
		try FileManager.default.removeItem(at: encUrl)
		try FileManager.default.removeItem(at: decUrl)
	}
	
	static var allTests = [
		("testEncryption", testEncryption),
		("testStreams", testStreams),
	]
}
