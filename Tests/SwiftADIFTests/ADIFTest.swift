import XCTest
@testable import SwiftADIF


final class ADIFTest: XCTestCase {
    func testSortByDate() throws {
        var adif = ADIF()
        adif.records = [
            ADIF.Record(id: 0, fields: [
                "QSO_DATE": ADIF.Field(name: "QSO_DATE", data: "20230103"),
                "TIME_ON": ADIF.Field(name: "TIME_ON", data: "0103"),
            ]),
            ADIF.Record(id: 1, fields: [
                "QSO_DATE": ADIF.Field(name: "QSO_DATE", data: "20230101"),
                "TIME_ON": ADIF.Field(name: "TIME_ON", data: "0103"),
            ]),
            ADIF.Record(id: 2, fields: [
                "QSO_DATE": ADIF.Field(name: "QSO_DATE", data: "20230103"),
                "TIME_ON": ADIF.Field(name: "TIME_ON", data: "0003"),
            ]),
        ]
        
        adif.sortByDatetime()
        var ids: [Int] = adif.records.map { $0.id }
        XCTAssertEqual(ids, [1, 2, 0])
        
        adif.sortByDatetime(reverse: true)
        ids = adif.records.map { $0.id }
        XCTAssertEqual(ids, [0, 2, 1])
    }
    
    func testSortById() throws {
        var adif = ADIF()
        adif.records = [
            ADIF.Record(id: 0, fields: [
                "QSO_DATE": ADIF.Field(name: "QSO_DATE", data: "20230103"),
                "TIME_ON": ADIF.Field(name: "TIME_ON", data: "0103"),
            ]),
            ADIF.Record(id: 1, fields: [
                "QSO_DATE": ADIF.Field(name: "QSO_DATE", data: "20230101"),
                "TIME_ON": ADIF.Field(name: "TIME_ON", data: "0103"),
            ]),
            ADIF.Record(id: 2, fields: [
                "QSO_DATE": ADIF.Field(name: "QSO_DATE", data: "20230103"),
                "TIME_ON": ADIF.Field(name: "TIME_ON", data: "0003"),
            ]),
        ]
        
        adif.sortById(reverse: true)
        var ids: [Int] = adif.records.map { $0.id }
        XCTAssertEqual(ids, [2, 1, 0])
        
        adif.sortById()
        ids = adif.records.map { $0.id }
        XCTAssertEqual(ids, [0, 1, 2])
    }
    
    func testSortByCall() throws {
        var adif = ADIF()
        adif.records = [
            ADIF.Record(id: 0, fields: [
                "CALL": ADIF.Field(name: "CALL", data: "JA1CBC"),
            ]),
            ADIF.Record(id: 1, fields: [
                "CALL": ADIF.Field(name: "CALL", data: "JA1ABC"),
            ]),
            ADIF.Record(id: 2, fields: [
                "CALL": ADIF.Field(name: "CALL", data: "JS7ABC"),
            ]),
        ]
        
        adif.sortByCall()
        var ids: [Int] = adif.records.map { $0.id }
        XCTAssertEqual(ids, [1, 0, 2])
        
        adif.sortByCall(reverse: true)
        ids = adif.records.map { $0.id }
        XCTAssertEqual(ids, [2, 0, 1])
    }
}


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
