import XCTest
@testable import ADIParser


final class TestDelegate: ADIParserDelegate {
    var row: [String: String] = [:]
    var fieldName: String?
    var dataLength: Int?
    var dataType: String?
    var data: String?
    var lineNumber: Int = 0
    var comment: String?
    var error: Error?
    
    func parser(_ parser: ADIParser, didStartDataSpecifier fieldName: String, dataLength: Int?, dataType: String?) {
        self.fieldName = fieldName
        self.dataLength = dataLength
        self.dataType = dataType
    }
    
    func parser(_ parser: ADIParser, foundData string: String) {
        row[fieldName!] = string
        data = string
    }
    
    func parserDidEndDocument(_ parser: ADIParser) {
        lineNumber = parser.lineNumber
    }
    
    func parser(_ parser: ADIParser, foundComment comment: String) {
        self.comment = comment
    }
    
    func parser(_ parser: ADIParser, parseErrorOccurred parseError: Error) {
        error = parseError
    }
    
    init() { }

}


final class ADIParserTest: XCTestCase {
    func testEOR() throws {
        let input = "<EOR>"
        let delegate = TestDelegate()
        let parser = ADIParser(string: input, ADIParserDelegate: delegate)
        let state = parser.parse()
        XCTAssertTrue(state)
        XCTAssertEqual(delegate.fieldName, "EOR")
        XCTAssertNil(delegate.dataLength)
        XCTAssertNil(delegate.dataType)
        XCTAssertNil(delegate.data)
    }
    
    func testFieldNameParsing() throws {
        let input = "<! \"#$%&'()*+-./;=?@\\^_`|~:4>test"
        let delegate = TestDelegate()
        let parser = ADIParser(string: input, ADIParserDelegate: delegate)
        let state = parser.parse()
        XCTAssertTrue(state)
        XCTAssertEqual(delegate.fieldName, "! \"#$%&'()*+-./;=?@\\^_`|~")
    }
    
    func testTagIncludedParsing() throws {
        let input = "<NOTES:13:M> \r\n<BAND:2>2M"
        let delegate = TestDelegate()
        let parser = ADIParser(string: input, ADIParserDelegate: delegate)
        let state = parser.parse()
        XCTAssertTrue(state)
        XCTAssertEqual(delegate.data, " \r\n<BAND:2>2M")
        XCTAssertEqual(delegate.lineNumber, 2)
    }
    
    func testSinglelineStr() throws {
        let input = "<USERDEF2:19:E>SweaterSize,{S,M,L}"
        let delegate = TestDelegate()
        let parser = ADIParser(string: input, ADIParserDelegate: delegate)
        let state = parser.parse()
        XCTAssertTrue(state)
        XCTAssertEqual(delegate.fieldName, "USERDEF2")
        XCTAssertEqual(delegate.dataLength, 19)
        XCTAssertEqual(delegate.dataType, "E")
        XCTAssertEqual(delegate.data, "SweaterSize,{S,M,L}")
    }
    
    func testMultilineStr() throws {
        let input = "<ADDRESS:12>Aichi\r\nJapan  "
        let delegate = TestDelegate()
        let parser = ADIParser(string: input, ADIParserDelegate: delegate)
        let state = parser.parse()
        XCTAssertTrue(state)
        XCTAssertEqual(delegate.data, "Aichi\r\nJapan")
    }
    
    func testReadADISingleRecord() throws {
        let input = """
            <CALL:6>JS2PBF
            <BAND:2>2M
            <EOR>
        """
        let expect = ["CALL": "JS2PBF", "BAND": "2M"]
        let delegate = TestDelegate()
        let parser = ADIParser(string: input, ADIParserDelegate: delegate)
        let state = parser.parse()
        XCTAssertTrue(state)
        XCTAssertEqual(delegate.row, expect)
        XCTAssertEqual(delegate.lineNumber, 3)
    }

    func testComment() throws {
        let input = """
                    Generated on 2011-11-22 at 02:15:23Z for WN4AZY

                    <ADIF_VER:5>3.0.5
                    """
        let delegate = TestDelegate()
        let parser = ADIParser(string: input, ADIParserDelegate: delegate)
        let state = parser.parse()
        XCTAssertTrue(state)
        XCTAssertEqual(delegate.comment, "Generated on 2011-11-22 at 02:15:23Z for WN4AZY\n\n")
        XCTAssertEqual(delegate.fieldName, "ADIF_VER")
    }
    
    func testParseFile() throws {
        guard let url = Bundle.module.url(forResource: "AdifOrg_ADISample", withExtension: "adi", subdirectory: "TestResources") else {
            return XCTFail()
        }
        let delegate = TestDelegate()
        guard let parser = ADIParser(contentsOf: url, ADIParserDelegate: delegate) else {
            return XCTFail()
        }
        let state = parser.parse()
        XCTAssertTrue(state)
        XCTAssertFalse(delegate.row.isEmpty)
    }
}
