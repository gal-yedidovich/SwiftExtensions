//
//  SimpleEncryptorTests.swift
//  CryptoTests
//
//  Created by Gal Yedidovich on 13/06/2020.
//

import XCTest
import CryptoKit
import CryptoExtensions

final class SimpleEncryptorTests: XCTestCase {
	let encryptor = SimpleEncryptor(strategy: .gcm)
	
	func testEncryption() throws {
		let str = "Bubu is the king"
		let data = Data(str.utf8)
		
		let enc = try encryptor.encrypt(data: data)
		let dec = try encryptor.decrypt(data: enc)
		
		let strTest = String(decoding: dec, as: UTF8.self)
		XCTAssertEqual(str, strTest)
	}
	
	func testStreams() throws {
		let str = [String](repeating: "Bubu is the king", count: 5000).joined(separator: "\n")
		
		let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		let url = baseURL.appendingPathComponent("data.txt")
		let encUrl = baseURL.appendingPathComponent("enc_data.txt")
		let decUrl = baseURL.appendingPathComponent("dec_data.txt")
		
		try Data(str.utf8).write(to: url)
		try encryptor.encrypt(file: url, to: encUrl)
		try encryptor.decrypt(file: encUrl, to: decUrl)
		let str2 = try String(contentsOf: decUrl)
		XCTAssertEqual(str, str2)
		
		try FileManager.default.removeItem(at: url)
		try FileManager.default.removeItem(at: encUrl)
		try FileManager.default.removeItem(at: decUrl)
	}
}
