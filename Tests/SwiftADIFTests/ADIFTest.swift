import XCTest
@testable import SwiftADIF


final class RecordTest: XCTestCase {
    func testNewRecord() throws {
        let oldRec = ADIF.Record(id: 0)
        let newRec = oldRec.newRecord()
        XCTAssertEqual(newRec.id, 1)
    }
}


final class FieldTest: XCTestCase {
    func testInitAppdef() throws {
        let field = ADIF.Field(name: "app", attr: ["programid": "monolog", "fieldname": "test", "type": "m"])
        XCTAssertEqual(field.name, "APP")
        XCTAssertEqual(Set(field.attr.keys), Set(["PROGRAMID", "FIELDNAME", "TYPE"]))
        XCTAssertEqual(field.PROGRAMID, "monolog")
        XCTAssertEqual(field.FIELDNAME, "test")
        XCTAssertEqual(field.TYPE, "M")
        XCTAssertEqual(field.displayName, "APP_MONOLOG_TEST")
    }
    
    func testAttr() throws {
        var field = ADIF.Field(name: "test")
        field.attr = ["programid": "monolog", "enum": "{s,m,l}"]
        field.TYPE = "m"
        XCTAssertEqual(Set(field.attr.keys), Set(["PROGRAMID", "ENUM", "TYPE"]))
        XCTAssertEqual(field.ENUM, "{S,M,L}")
        XCTAssertEqual(field.TYPE, "M")
    }
}
