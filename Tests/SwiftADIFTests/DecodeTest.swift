import XCTest
@testable import SwiftADIF


final class ADIDecoderTest: XCTestCase {
    func testReadADISingleRecord() throws {
        let input = """
            <CALL:6>JS2PBF
            <BAND:2>2M
            <EOR>
        """
        let expect = [[
            "CALL": "JS2PBF",
            "BAND": "2M",
        ]]
        let decoder = ADIDecoder(adiString: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        XCTAssertTrue(decoder.headerFields.isEmpty)
        XCTAssertTrue(decoder.userdefs.isEmpty)
        XCTAssertTrue(decoder.appdefs.isEmpty)
        XCTAssertEqual(decoder.records, expect)
    }
    
    func testMultilineField() throws {
        let input = "<ADDRESS:20>Nagoya\r\nAichi\r\nJapan\r\n<EOR>"
        let decoder = ADIDecoder(adiString: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        let answer = decoder.records.first!["ADDRESS"]
        XCTAssertEqual(answer!, "Nagoya\nAichi\nJapan")
    }
 
    func testReadAdiFileWithHeader() throws {
        guard let url = Bundle.module.url(forResource: "AdifOrg_ADISample", withExtension: "adi", subdirectory: "TestResources") else {
            return XCTFail()
        }
        guard let input = try? String(contentsOf: url, encoding: .utf8) else {
            return XCTFail()
        }

        let expectHeader = [
            "ADIF_VER": "3.0.5",
            "PROGRAMID": "monolog",
        ]
        let expectUserDefs = [
            "EPC": ADIF.FieldType(USERDEF: "USERDEF", fieldid: 1, type: "N", fieldname: "EPC"),
            "SWEATERSIZE": ADIF.FieldType(USERDEF: "USERDEF", fieldid: 2, type: "E", fieldname: "SweaterSize", enum_: "{S,M,L}"),
            "SHOESIZE": ADIF.FieldType(USERDEF: "USERDEF", fieldid: 3, type: "N", fieldname: "ShoeSize", range: "{5:20}"),
        ]
        let expectAppDefs = [
            "APP_MONOLOG_COMPRESSION": ADIF.FieldType(APP: "APP", programid: "monolog", fieldname: "compression", type: "M"),
        ]

        let expectRecs = [
            [
                "QSO_DATE": "19900620",
                "TIME_ON": "1523",
                "CALL": "VK9NS",
                "BAND": "20M",
                "MODE": "RTTY",
                "SWEATERSIZE": "M",
                "SHOESIZE": "11",
                "APP_MONOLOG_COMPRESSION": "off",
            ], [
                "QSO_DATE": "20101022",
                "TIME_ON": "0111",
                "CALL": "ON4UN",
                "BAND": "40M",
                "MODE": "PSK",
                "SUBMODE": "PSK63",
                "EPC": "32123",
                "APP_MONOLOG_COMPRESSION": "off",
            ]
        ]

        let decoder = ADIDecoder(adiString: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        XCTAssertEqual(decoder.headerFields, expectHeader)
        XCTAssertEqual(decoder.userdefs, expectUserDefs)
        XCTAssertEqual(decoder.appdefs, expectAppDefs)
        XCTAssertEqual(decoder.records, expectRecs)
    }
}

final class ADXDecoderTest: XCTestCase {
    func testReadADISingleRecord() throws {
        let input = """
            <ADX>
                <RECORDS>
                    <RECORD>
                        <CALL>JS2PBF</CALL>
                        <BAND>2M</BAND>
                    </RECORD>
                </RECORDS>
            </ADX>
        """
        let expect = [[
            "CALL": "JS2PBF",
            "BAND": "2M",
        ]]
        let decoder = ADXDecoder(adxString: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        XCTAssertTrue(decoder.headerFields.isEmpty)
        XCTAssertTrue(decoder.userdefs.isEmpty)
        XCTAssertTrue(decoder.appdefs.isEmpty)
        XCTAssertEqual(decoder.records, expect)
    }
    
    func testMultilineField() throws {
        let input = "<ADX><RECORDS><RECORD><ADDRESS>Nagoya\r\nAichi\r\nJapan</ADDRESS></RECORD></RECORDS></ADX>"
        let decoder = ADXDecoder(adxString: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        let answer = decoder.records.first!["ADDRESS"]
        XCTAssertEqual(answer!, "Nagoya\nAichi\nJapan")
    }
    
    func testReadAdxFileWithHeader() throws {
        guard let url = Bundle.module.url(forResource: "AdifOrg_ADXSample", withExtension: "adx", subdirectory: "TestResources") else {
            return XCTFail()
        }
        guard let input = try? String(contentsOf: url, encoding: .utf8) else {
            return XCTFail()
        }

        let expectHeader = [
            "ADIF_VER": "3.0.5",
            "PROGRAMID": "monolog",
        ]
        let expectUserDefs = [
            "EPC": ADIF.FieldType(USERDEF: "USERDEF", fieldid: 1, type: "N", fieldname: "EPC"),
            "SWEATERSIZE": ADIF.FieldType(USERDEF: "USERDEF", fieldid: 2, type: "E", fieldname: "SweaterSize", enum_: "{S,M,L}"),
            "SHOESIZE": ADIF.FieldType(USERDEF: "USERDEF", fieldid: 3, type: "N", fieldname: "ShoeSize", range: "{5:20}"),
        ]
        let expectAppDefs = [
            "APP_MONOLOG_COMPRESSION": ADIF.FieldType(APP: "APP", programid: "monolog", fieldname: "compression", type: "S"),
        ]

        let expectRecs = [
            [
                "QSO_DATE": "19900620",
                "TIME_ON": "1523",
                "CALL": "VK9NS",
                "BAND": "20M",
                "MODE": "RTTY",
                "SWEATERSIZE": "M",
                "SHOESIZE": "11",
                "APP_MONOLOG_COMPRESSION": "off",
            ], [
                "QSO_DATE": "20101022",
                "TIME_ON": "0111",
                "CALL": "ON4UN",
                "BAND": "40M",
                "MODE": "PSK",
                "SUBMODE": "PSK63",
                "EPC": "32123",
                "APP_MONOLOG_COMPRESSION": "off",
            ]
        ]

        let decoder = ADXDecoder(adxString: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        XCTAssertEqual(decoder.headerFields, expectHeader)
        XCTAssertEqual(decoder.userdefs, expectUserDefs)
        XCTAssertEqual(decoder.appdefs, expectAppDefs)
        XCTAssertEqual(decoder.records, expectRecs)
    }
}
