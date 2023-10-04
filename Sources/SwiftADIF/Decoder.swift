import Foundation
import RegexBuilder

import SwiftADIParser
import ADIFValidator


enum DecodeError: Error, LocalizedError {
    case parseError
    case notDefienUserDefinedField
    
    public var errorDescription: String? {
        switch self {
            case .parseError:
                return String(describing: type(of: self)) + "Some error occur during parsing."
            case .notDefienUserDefinedField:
                return String(describing: type(of: self)) + "'User-defined field' is not defined."
        }
    }
}


protocol Decoder {
    // Return values
    var headerFields: [String: ADIF.Field] { get }
    var userdefs: [String: ADIF.Field] { get }
    var appdefs: [String: ADIF.Field] { get }
    var records: [ADIF.Record] { get }
    
    // Decoding
    func decode() throws
}


class ADIDecoder: Decoder, ADIParserDelegate {
    // Return values
    private(set) var headerFields: [String: ADIF.Field] = [:]
    private(set) var userdefs: [String: ADIF.Field] = [:]
    private(set) var appdefs: [String: ADIF.Field] = [:]
    private(set) var records: [ADIF.Record]  = []
    
    private var parser: ADIParser
    private var record = ADIF.Record(id: 0)
    
    init(string: String) {
        self.parser = ADIParser(string: string)
    }
    
    func parser(_ parser: ADIParser, foundDataSpecifier fieldName: String, dataLength: Int?, dataType: String?, data: String?) {
        var field: ADIF.Field
        
        // Convert CRLF to LF in the data
        let dataStr = data?.replacingOccurrences(of: "\r\n", with: "\n")
        
        // User-defined field in header
        if let match = fieldName.firstMatch(of: #/^(?:USERDEF|userdef)(\d+)/#) {
            field = ADIF.Field(name: "USERDEF", data: dataStr)
            field.FIELDID = String(match.1)
            if let _ = dataType {
                field.TYPE = dataType
            }
            
            // Parse RANGE or ENUM from data
            let userdefDataRe = Regex {
                Capture { ADIFRegexGen.DataSpecifier.fieldName }
                ","
                Capture { ADIFRegexGen.ADIFormat.userdefEnum }
            }
            if let match = dataStr!.firstMatch(of: userdefDataRe) {
                field.data = String(match.1)
                if let _ = match.2.wholeMatch(of: ADIFRegexGen.ADIFormat.userdefRange) {
                    field.RANGE = String(match.2)
                } else {
                    field.ENUM = String(match.2)
                }
            }
            
            userdefs[field.displayName] = field
        }
        // Application-defined field
        else if let match = fieldName.wholeMatch(of: ADIFRegexGen.ADIFormat.appdefFieldName) {
            field = ADIF.Field(name: "APP", data: dataStr)
            field.PROGRAMID = match.1
            field.FIELDNAME = match.2
            field.TYPE = dataType ?? "M"
            record.fields[field.displayName] = field
            
            if !appdefs.keys.contains(field.displayName) {
                appdefs[field.displayName] = field
                appdefs[field.displayName]!.data = nil
            }
        }
        // User-defined field in record
        else if userdefs.keys.contains(fieldName) {
            field = ADIF.Field(name: "USERDEF", data: dataStr)
            field.FIELDNAME = fieldName
            if let dataType = dataType {
                field.TYPE = dataType
            }
            record.fields[field.displayName] = field
        }
        // EOH
        else if fieldName.uppercased() == "EOH" {
            headerFields = record.fields
            record = ADIF.Record(id: 0)
        }
        // EOR
        else if fieldName.uppercased() == "EOR" {
            records.append(record)
            record = record.newRecord()
        }
        // Default
        else {
            field = ADIF.Field(name: fieldName, data: dataStr)
            if let dataType = dataType {
                field.TYPE = dataType
            }
            record.fields[field.displayName] = field
        }
    }
    
    // Decoding
    func decode() throws {
        parser.delegate = self
        let state = parser.parse()
        if !state {
            throw DecodeError.parseError
        }
    }
}


class ADXDecoder: NSObject, Decoder, XMLParserDelegate {
    // Return values
    private(set) var headerFields: [String: ADIF.Field] = [:]
    private(set) var userdefs: [String: ADIF.Field] = [:]
    private(set) var appdefs: [String: ADIF.Field] = [:]
    private(set) var records: [ADIF.Record]  = []
    
    private var parser: XMLParser
    private var record = ADIF.Record(id: 0)
    private var field = ADIF.Field(name: "")
    private var namespace: [String] = []

    init(string: String) {
        let data = Data(string.utf8)
        self.parser = XMLParser(data: data)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        namespace.append(elementName)
        
        switch elementName {
            case "ADX", "HEADER", "RECORDS", "RECORD":
                break
            case "APP":
                field = ADIF.Field(name: elementName, attr: attributeDict)
                if appdefs[field.displayName] == nil {
                    appdefs[field.displayName] = field
                }
            default:
                field = ADIF.Field(name: elementName, attr: attributeDict)
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // Convert CRLF to LF
        let str = string.replacingOccurrences(of: "\r\n", with: "\n")

        switch namespace.last {
            case "ADX", "HEADER", "RECORDS", "RECORD":
                break
            default:  // APP, USERDEF and other ADIF-difiend fields
                field.data = (field.data ?? "") + str
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        namespace.removeLast()
        
        switch elementName {
            case "ADX":
                break
            case "HEADER":
                headerFields = record.fields
                record = ADIF.Record(id: 0)
            case "RECORDS":
                break
            case "RECORD":
                records.append(record)
                record = record.newRecord()
            case "USERDEF":
                if namespace.contains("HEADER") {
                    userdefs[field.displayName] = field
                } else {
                    fallthrough
                }
            default:  // APP and other ADIF-difiend fields
                record.fields[field.displayName] = field
        }
    }

    // Decoding
    func decode() throws {
        parser.delegate = self
        let state = parser.parse()
        if !state {
            throw DecodeError.parseError
        }
    }

}
