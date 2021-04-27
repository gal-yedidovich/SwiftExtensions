//
//  UrlRequestExt.swift
//  
//
//  Created by Gal Yedidovich on 18/06/2020.
//

import Foundation
public extension URLRequest {
	/// Creates a new request instance with a url from given string
	/// - Parameter url: url string
	init(url: String) {
		self.init(url: URL(string: url)!)
	}
	
	/// convenience method for settings the method, using method chaining
	/// - Parameter method: http method of the request
	/// - Returns: new request after setting the method
	func set(method: Method) -> URLRequest {
		var req = self
		req.httpMethod = method.rawValue
		return req
	}
	
	/// convenience method for settings the content-type, using method chaining
	/// - Parameter contentType: content-type header of the request
	/// - Returns: new request after setting the content-type
	func set(contentType: ContentType) -> URLRequest {
		set(header: "Content-Type", value: contentType.value)
	}
	
	/// convenience method for settings a header, using method chaining
	/// - Parameters:
	///   - header: header name
	///   - value: header value
	/// - Returns: new request after settings the header
	func set(header: String, value: String) -> URLRequest {
		var req = self
		req.setValue(value, forHTTPHeaderField: header)
		return req
	}
	
	/// convenience method for settings the body, using method chaining
	/// - Parameter body: the request body in string
	/// - Returns: new request after settings the body
	func set(body: String) -> URLRequest {
		set(body: Data(body.utf8))
	}
	
	/// convenience method for settings the body, using method chaining
	/// - Parameter body: the request body data
	/// - Returns: new request after settings the body
	func set(body: Data) -> URLRequest {
		var req = self
		req.httpBody = body
		return req
	}
	
	/// Convenince HTTP methods for `URLRequest`
	enum Method: String {
		case GET, POST, PUT, DELETE, PATCH
	}
}

/// Convenience Content-type values for `URLRequest`
public struct ContentType: ExpressibleByStringLiteral {
	public static var json: ContentType { "application/json" }
	public static var text: ContentType { "text/plain" }
	public static var xml: ContentType { "text/xml" }
	public static var urlEncoded: ContentType { "application/x-www-form-urlencoded" }
	public static var multipartFormData: ContentType { "multipart/form-data" }
	
	public init(stringLiteral value: String) {
		self.value = value
	}
	
	let value: String
}

/// Convenient Netwrok Response, with Two types, Success & Failure
public enum NetResponse<Success, Failure> {
	case success(Success)
	case failure(Int, Failure)
	case error(Error)
}

public extension URLSession {
	
	/// Convenience request method.
	/// Creates a `URLSeesionDataTask` with completion handler that trasform the basic paraemters into `Result<Data, Data>`
	///
	/// The result is holding the data/error from the request using enum + assosiated value
	///
	/// - Parameters:
	///   - request: a request to send to a remote server
	///   - completion: a completion handler that accepts the result from the response, can be either success/failure/error.
	/// - Returns: Task, prepared to start with `resume()` call
	func dataTask(with request: URLRequest, completion: @escaping (NetResponse<Data, Data>) -> Void) -> URLSessionDataTask {
		dataTask(with: request) { (d, r, e) in
			if let error = e { completion(.error(error)); return }
			guard let data = d, let urlRes = r as? HTTPURLResponse else { completion(.error(URLError(.badServerResponse))); return }
			
			if urlRes.statusCode / 100 == 2 {
				completion(.success(data))
			} else {
				completion(.failure(urlRes.statusCode, data))
			}
		}
	}
	
	/// Convenience method for generic result type.
	/// This overloadded method, calls `send(_: completion:)` and decode the response data to the generic type (unless there is an error)
	/// - Parameters:
	///   - request: a request to send to a remote server
	///   - completion: a completion handler that accepts the generic result from the response, can be either success/failure/error.
	/// - Returns: Task, prepared to start with `resume()` call
	func dataTask<Response: Decodable, FailRes: Decodable>(with request: URLRequest, completion: @escaping (NetResponse<Response, FailRes>) -> Void) -> URLSessionDataTask {
		dataTask(with: request) { result in
			do {
				switch result {
					case .success(let data): completion(.success(try .from(json: data)))
					case .failure(let status, let data): completion(.failure(status, try .from(json: data)))
					case .error(let error): completion(.error(error))
				}
			} catch {
				completion(.error(error))
			}
		}
	}
}
