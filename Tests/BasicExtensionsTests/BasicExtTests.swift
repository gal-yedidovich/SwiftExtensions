//
//  BasicExtTests.swift
//  
//
//  Created by Gal Yedidovich on 19/12/2020.
//

import XCTest
import CryptoKit
import BasicExtensions

final class BasicExtTests: XCTestCase {
	static let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("hashTest.txt")
	static let content = "Bubu is the king"
	
	override class func setUp() {
		try! Data(content.utf8).write(to: Self.url)
	}
	
	override class func tearDown() {
		try? FileManager.default.removeItem(at: url)
	}
	
	func testDigestHexString() {
		let data = Data(Self.content.utf8)
		let hex = "d42254b4047044e74c45083fe483bf6708057d5b4579aae0bca9b30e7376e553" //data in SHA-256: https://xorbin.com/tools/sha256-hash-calculator
		let sha256 = SHA256.hash(data: data).hexString
		
		XCTAssertEqual(hex, sha256)
	}
	
	func testHashingFile() throws {
		let digest = SHA256.checksum(file: Self.url)
		XCTAssertEqual(digest?.hexString, "d42254b4047044e74c45083fe483bf6708057d5b4579aae0bca9b30e7376e553")
	}
	
	func testHashingDirectory() throws {
		let dirUrl = Self.url.deletingLastPathComponent().appendingPathComponent("hashDir", isDirectory: true)
		try FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true)
		defer { try? FileManager.default.removeItem(at: dirUrl) }
		
		let digest = SHA256.checksum(file: dirUrl)
		XCTAssertNil(digest)
	}
	
	func testFileSize() {
		guard let fileSize = Self.url.fileSize else { XCTFail("no file size"); return }
		XCTAssertEqual(fileSize, Self.content.count)
	}
	
	func testIsDirectory() {
		XCTAssert(Self.url.deletingLastPathComponent().isDirectory)
		XCTAssertFalse(Self.url.isDirectory)
	}
	
	func testSorted() {
		struct Item: Equatable {
			let num: Int
		}
		
		let items = (1...100).map(Item.init(num:))
		let random = items.shuffled()
		XCTAssertNotEqual(random, items)
		
		let sorted = random.sorted(by: \.num)
		XCTAssertEqual(sorted, items)
	}
}
