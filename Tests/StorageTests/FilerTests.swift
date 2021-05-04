//
//  FilerTests.swift
//  StorageTests
//
//  Created by Gal Yedidovich on 13/06/2020.
//

import XCTest
@testable import StorageExtensions

final class FilerTests: XCTestCase {
	func testWrite() throws {
		let str = "Bubu is the king"
		try Filer.write(data: Data(str.utf8), to: .file)
		
		XCTAssert(Filer.fileExists(.file))
		
		let data = try Filer.read(file: .file)
		XCTAssertEqual(str, String(data: data, encoding: .utf8))
		
		try Filer.delete(file: .file)
	}
	
	func testOverwrite() throws {
		try Filer.write(data: Data("Bubu is the king".utf8), to: .file)
		
		let newText = "I am Groot"
		try Filer.write(data: Data(newText.utf8), to: .file)
		
		let fileData = try Filer.read(file: .file)
		XCTAssertEqual(newText, String(data: fileData, encoding: .utf8))
		
		try Filer.delete(file: .file)
	}
	
	func testDelete() throws {
		try Filer.write(data: Data("Bubu is the king".utf8), to: .file)
		
		try Filer.delete(file: .file)
		XCTAssertFalse(Filer.fileExists(.file))
		XCTAssertFalse(FileManager.default.fileExists(atPath: Filer.url(of: .file).path))
	}
	
	func testLoadJson() throws {
		struct Person: Codable, Equatable {
			let name: String
			let age: Int
		}
		
		let bubu = Person(name: "Bubu", age: 120)
		try Filer.write(data: bubu.json(), to: .file)
		let loaded: Person = try Filer.load(json: .file)
		
		XCTAssertEqual(bubu, loaded)
		try Filer.delete(file: .file)
	}
	
	func testReadFileNotFound() throws {
		XCTAssertThrowsError(try Filer.read(file: .file))
	}
	
	func testConcatingPaths() {
		let folder1 = Folder(name: "folder1")
		let folder2 = Folder(name: "folder2")
		let file2 = Filename(name: "file2")
		
		let path1 = folder1 / .file
		let path2 = folder1 / folder2
		let path3 = folder1.append(folder2).append(file2)
		
		XCTAssertEqual(path1.value, "folder1/file1")
		XCTAssertEqual(path2.value, "folder1/folder2")
		XCTAssertEqual(path3.value, "folder1/folder2/file2")
	}
}

fileprivate extension Filename {
	static let file = Filename(name: "file1")
}
