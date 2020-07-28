//
//  FileSystem.swift
//  Storage
//
//  Created by Gal Yedidovich on 15/06/2020.
//

import Foundation
/// An interface to work with the local storage of the device using a layer of Encryption.
///
/// The `FileSystem` class provides easy IO (read/write) operations to local files, that are automatically encrypted with `Encryptor` functions for cipher data.
public final class FileSystem {
	private init() { }
	
	private static let fm = FileManager.default
	/// the URL in storage, where all fiels & folders under FileSystem, are managed.
	public static var rootURL = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
	
	
	/// Writes data into given Filename
	/// - Parameters:
	///   - data: data to write
	///   - file: target filename, represents file in storage.
	public static func write(data: Data, to file: Filename) throws {
		try write(data: data, to: url(of: file))
	}
	
	/// Writes data into given URL, this method will create the parent folder if needed.
	/// The data will be written using the Encryptor's `encrypt` method for security.
	/// The write operation is atomic, to encsure the integrity of the file.
	/// - Parameters:
	///   - data: data to write
	///   - url: taget url in storage.
	public static func write(data: Data, to url: URL) throws {
		try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
		
		let encData = try Encryptor.encrypt(data: data)
		try encData.write(to: url, options: .atomic)
	}
	
	/// Read a file from storage and return is content
	/// The data will be read using the Encryptor's `decrypt`
	/// - Parameter file: target Filename to read from
	/// - Returns: the content of the file or nil if unsuccessful.
	public static func read(file: Filename) -> Data? {
		do {
			let data = try Data(contentsOf: url(of: file))
			return try Encryptor.decrypt(data: data)
		} catch {
			print(error)
			return nil
		}
	}
	
	/// check if a given Filename exists in storage
	/// - Parameter file: target Filename
	/// - Returns: true if exists, otherwise false.
	public static func fileExists(_ file: Filename) -> Bool {
		fm.fileExists(atPath: url(of: file).path)
	}
	
	/// delete a Filename from storage
	/// - Parameter file: target Filename to delete
	public static func delete(file: Filename) throws {
		let fileUrl = url(of: file)
		if fm.fileExists(atPath: fileUrl.path) {
			try fm.removeItem(at: fileUrl)
		}
	}
	
	/// delete a Folder from storage, including its content
	/// - Parameter file: target Folder to delete
	public static func delete(folder: Folder) throws {
		let fileUrl = url(of: folder)
		if fm.fileExists(atPath: fileUrl.path) {
			try fm.removeItem(at: fileUrl)
		}
	}
	
	/// generate url from given Filename, using the `rootURL` path and the value of the Filename
	/// - Parameter file: target Filename
	/// - Returns: URL in storage
	public static func url(of file: Filename) -> URL {
		rootURL.appendingPathComponent(file.value)
	}
	
	/// generate url from given Folder, using the `rootURL` path and the value of the Folder
	/// - Parameter file: target Folder
	/// - Returns: URL in storage
	public static func url(of folder: Folder) -> URL {
		rootURL.appendingPathComponent(folder.value)
	}
}

/// String Wrapper for files, each value represent a filename under the FileSystem's `rootURL`
public struct Filename {
	public static let prefs = Filename(name: "_")
	
	public init(name: String) {
		value = name
	}
	
	public let value: String
}

/// String Wrapper for folders, each value represent a folder-name under the FileSystem's `rootURL`
public struct Folder {
	public init(name: String) {
		value = name
	}
	
	public let value: String
}
