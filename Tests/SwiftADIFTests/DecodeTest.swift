import XCTest
@testable import SwiftADIF


final class ADIDecoderTest: XCTestCase {
    func testReadADISingleRecord() throws {
        let input = """
            <CALL:6>JS2PBF
            <BAND:2>2M
            <EOR>
        """
        let decoder = ADIDecoder(string: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        
        XCTAssertTrue(decoder.headerFields.isEmpty)
        XCTAssertTrue(decoder.userdefs.isEmpty)
        XCTAssertTrue(decoder.appdefs.isEmpty)
        XCTAssertEqual(decoder.records.count, 1)
        
        let rec = decoder.records.first!
        XCTAssertEqual(Set(rec.fields.keys), Set(["CALL", "BAND"]))
        XCTAssertEqual(rec.CALL?.data, "JS2PBF")
        XCTAssertEqual(rec.BAND?.data, "2M")
    }
    
    func testMultilineField() throws {
        let input = "<ADDRESS:20>Nagoya\r\nAichi\r\nJapan\r\n<EOR>"
        let decoder = ADIDecoder(string: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        let answer = decoder.records.first!.ADDRESS
        XCTAssertEqual(answer?.data, "Nagoya\nAichi\nJapan")
    }
    
    func testAppdefField() throws {
        let input = """
            <app_monolog_compression:3>off
            <eor>
        """
        let decoder = ADIDecoder(string: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        XCTAssertEqual(Set(decoder.appdefs.keys), Set(["APP_MONOLOG_COMPRESSION"]))
        
        let answer = decoder.records.first!.APP_MONOLOG_COMPRESSION!
        XCTAssertEqual(answer.data, "off")
        XCTAssertEqual(answer.PROGRAMID, "monolog")
        XCTAssertEqual(answer.FIELDNAME, "compression")
    }
    
    func testHeaderField() throws {
        let input = """
            Generated on 2011-11-22 at 02:15:23Z for WN4AZY

            <adif_ver:5>3.0.5
            <programid:7>monolog
            <USERDEF1:3:N>EPC
            <USERDEF2:19:E>SweaterSize,{S,M,L}
            <USERDEF3:15:N>ShoeSize,{5:20}

            <EOH>
        """
        let decoder = ADIDecoder(string: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        XCTAssertEqual(Set(decoder.headerFields.keys), Set(["ADIF_VER", "PROGRAMID"]))
        XCTAssertEqual(Set(decoder.userdefs.keys), Set(["EPC", "SWEATERSIZE", "SHOESIZE"]))
        
        var field = decoder.userdefs["EPC"]!
        XCTAssertEqual(field.name, "USERDEF")
        XCTAssertEqual(field.data, "EPC")
        XCTAssertEqual(field.FIELDID, "1")
        XCTAssertEqual(field.TYPE, "N")
        
        field = decoder.userdefs["SWEATERSIZE"]!
        XCTAssertEqual(field.ENUM, "{S,M,L}")
        
        field = decoder.userdefs["SHOESIZE"]!
        XCTAssertEqual(field.RANGE, "{5:20}")
    }
 
    func testReadAdiFileWithHeader() throws {
        guard let url = Bundle.module.url(forResource: "AdifOrg_ADISample", withExtension: "adi", subdirectory: "TestResources") else {
            return XCTFail()
        }
        guard let input = try? String(contentsOf: url, encoding: .utf8) else {
            return XCTFail()
        }

        let decoder = ADIDecoder(string: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        XCTAssertEqual(decoder.headerFields.count, 2)
        XCTAssertEqual(decoder.userdefs.count, 3)
        XCTAssertEqual(decoder.records.count, 2)
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
        let decoder = ADXDecoder(string: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        
        XCTAssertTrue(decoder.headerFields.isEmpty)
        XCTAssertTrue(decoder.userdefs.isEmpty)
        XCTAssertTrue(decoder.appdefs.isEmpty)
        XCTAssertEqual(decoder.records.count, 1)
        
        let rec = decoder.records.first!
        XCTAssertEqual(Set(rec.fields.keys), Set(["CALL", "BAND"]))
        XCTAssertEqual(rec.CALL?.data, "JS2PBF")
        XCTAssertEqual(rec.BAND?.data, "2M")
    }
    
    func testMultilineField() throws {
        let input = "<ADX><RECORDS><RECORD><ADDRESS>Nagoya\r\nAichi\r\nJapan</ADDRESS></RECORD></RECORDS></ADX>"
        let decoder = ADXDecoder(string: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        let answer = decoder.records.first!.ADDRESS
        XCTAssertEqual(answer?.data, "Nagoya\nAichi\nJapan")
    }
    
    func testAppdefField() throws {
        let input = #"""
            <ADX><RECORDS><RECORD>
                <APP PROGRAMID="MONOLOG" FIELDNAME="BIRTHDAY" TYPE="d">19470726</APP>
            </RECORD></RECORDS></ADX>
        """#
        let decoder = ADXDecoder(string: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        XCTAssertEqual(Set(decoder.appdefs.keys), Set(["APP_MONOLOG_BIRTHDAY"]))
        
        let answer = decoder.records.first!.APP_MONOLOG_BIRTHDAY!
        XCTAssertEqual(answer.data, "19470726")
        XCTAssertEqual(answer.PROGRAMID, "MONOLOG")
        XCTAssertEqual(answer.FIELDNAME, "BIRTHDAY")
        XCTAssertEqual(answer.TYPE, "D")
    }
    
    func testHeaderField() throws {
        let input = """
            <ADX><HEADER>
                <!--Generated on 2011-11-22 at 02:15:23Z for WN4AZY-->
                <ADIF_VER>3.0.5</ADIF_VER>
                <PROGRAMID>monolog</PROGRAMID>
                <USERDEF FIELDID="1" TYPE="N">EPC</USERDEF>
                <USERDEF FIELDID="2" TYPE="E" ENUM="{S,M,L}">SWEATERSIZE</USERDEF>
                <USERDEF FIELDID="3" TYPE="N" RANGE="{5:20}">SHOESIZE</USERDEF>
            </HEADER></ADX>
        """
        let decoder = ADXDecoder(string: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        XCTAssertEqual(Set(decoder.headerFields.keys), Set(["ADIF_VER", "PROGRAMID"]))
        XCTAssertEqual(Set(decoder.userdefs.keys), Set(["EPC", "SWEATERSIZE", "SHOESIZE"]))
        
        var field = decoder.userdefs["EPC"]!
        XCTAssertEqual(field.name, "USERDEF")
        XCTAssertEqual(field.data, "EPC")
        XCTAssertEqual(field.FIELDID, "1")
        XCTAssertEqual(field.TYPE, "N")
        
        field = decoder.userdefs["SWEATERSIZE"]!
        XCTAssertEqual(field.ENUM, "{S,M,L}")
        
        field = decoder.userdefs["SHOESIZE"]!
        XCTAssertEqual(field.RANGE, "{5:20}")
    }
    
    func testReadAdxFileWithHeader() throws {
        guard let url = Bundle.module.url(forResource: "AdifOrg_ADXSample", withExtension: "adx", subdirectory: "TestResources") else {
            return XCTFail()
        }
        guard let input = try? String(contentsOf: url, encoding: .utf8) else {
            return XCTFail()
        }

        let decoder = ADXDecoder(string: input)
        do {
            try decoder.decode()
        } catch {
            XCTFail()
        }
        XCTAssertEqual(decoder.headerFields.count, 2)
        XCTAssertEqual(decoder.userdefs.count, 3)
        XCTAssertEqual(decoder.records.count, 2)
    }
}
