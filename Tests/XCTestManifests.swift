import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
	return [
		testCase(PrefsTests.allTests),
		testCase(FileSystemTests.allTests),
		testCase(EncryptorTests.allTests),
		testCase(UrlRequestTests.allTests),
	]
}
#endif
