//
//  FileSystemTests.swift
//  StorageTests
//
//  Created by Gal Yedidovich on 13/06/2020.
//

import XCTest
@testable import StorageExtensions

final class FileSystemTests: XCTestCase {
	func testWrite() throws {
		let str = "Bubu is the king"
		try FileSystem.write(data: Data(str.utf8), to: .file)
		
		XCTAssert(FileSystem.fileExists(.file))
		
		let data = try FileSystem.read(file: .file)
		XCTAssertEqual(str, String(data: data, encoding: .utf8))
		
		try FileSystem.delete(file: .file)
	}
	
	func testOverwrite() throws {
		try FileSystem.write(data: Data("Bubu is the king".utf8), to: .file)
		
		let newText = "I am Groot"
		try FileSystem.write(data: Data(newText.utf8), to: .file)
		
		let fileData = try FileSystem.read(file: .file)
		XCTAssertEqual(newText, String(data: fileData, encoding: .utf8))
		
		try FileSystem.delete(file: .file)
	}
	
	func testDelete() throws {
		try FileSystem.write(data: Data("Bubu is the king".utf8), to: .file)
		
		try FileSystem.delete(file: .file)
		XCTAssertFalse(FileSystem.fileExists(.file))
		XCTAssertFalse(FileManager.default.fileExists(atPath: FileSystem.url(of: .file).path))
	}
	
	func testLoadJson() throws {
		struct Person: Codable, Equatable {
			let name: String
			let age: Int
		}
		
		let bubu = Person(name: "Bubu", age: 120)
		try FileSystem.write(data: bubu.json(), to: .file)
		let loaded: Person = try FileSystem.load(json: .file)
		
		XCTAssertEqual(bubu, loaded)
		try FileSystem.delete(file: .file)
	}
	
	func testReadFileNotFound() throws {
		XCTAssertThrowsError(try FileSystem.read(file: .file))
	}
	
	static var allTests = [
		("testWrite", testWrite),
		("testOverwrite", testOverwrite),
		("testDelete", testDelete),
		("testLoadJson", testLoadJson),
		("testReadFileNotFound", testReadFileNotFound),
	]
}

fileprivate extension Filename {
	static let file = Filename(name: "file1")
}
