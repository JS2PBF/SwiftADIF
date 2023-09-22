import Foundation
import RegexBuilder

import ADIParser
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
    var headerFields: [String: String] { get }
    var userdefs: [String: ADIF.FieldType] { get }
    var appdefs: [String: ADIF.FieldType] { get }
    var records: [[String: String]] { get }
    
    // Decoding
    func decode() throws
}


class ADIDecoder: Decoder, ADIParserDelegate {
    // Return values
    private(set) var headerFields: [String: String] = [:]
    private(set) var userdefs: [String: ADIF.FieldType] = [:]
    private(set) var appdefs: [String: ADIF.FieldType] = [:]
    private(set) var records: [[String: String]]  = []
    
    private var parser: ADIParser
    private var record: [String: String] = [:]
    private var field = ADIF.FieldType(name: "")
    
    init(adiString: String) {
        self.parser = ADIParser(string: adiString)
    }
    
    func parser(_ parser: ADIParser, didStartDataSpecifier fieldName: String, dataLength: Int?, dataType: String?) {
        self.field = ADIF.FieldType(name: fieldName, type: dataType)
        
        // Application-defined field
        if let match = fieldName.wholeMatch(of: ADIFRegexGen.ADIFormat.appdefFieldName) {
            let type: String = dataType ?? "M"
            field = ADIF.FieldType(APP: "APP", programid: match.1, fieldname: match.2, type: type)
            if !appdefs.keys.contains(field.displayName) {
                appdefs[field.displayName] = field
            }
        }
        
        // User-defined field in header
        if let match = fieldName.firstMatch(of: #/^(?:USERDEF|userdef)(\d+)/#) {
            field = ADIF.FieldType(USERDEF: "USERDEF", fieldid: Int64(match.1)!, type: dataType)
        }

    }
    
    func parser(_ parser: ADIParser, foundData string: String) {
        // Convert CRLF to LF
        let str = string.replacingOccurrences(of: "\r\n", with: "\n")
        
        switch field.name {
            // User-defiend field in header
            case "USERDEF":
                let userdefDataRe = Regex {
                    Capture { ADIFRegexGen.DataSpecifier.fieldName }
                    ","
                    Capture { ADIFRegexGen.ADIFormat.userdefEnum }
                }
                if let match = str.firstMatch(of: userdefDataRe) {
                    field.fieldname = String(match.1)
                    if let _ = match.2.wholeMatch(of: ADIFRegexGen.ADIFormat.userdefRange) {
                        field.range = String(match.2)
                    } else {
                        field.enum_ = String(match.2)
                    }
                } else {
                    field.fieldname = str
                }
            default:
                record[field.displayName] = str
        }
    }
    
    func parser(_ parser: ADIParser, didEndDataSpecifier fieldName: String) {
        switch field.name {
            case "USERDEF":
                userdefs[field.displayName] = field
            case "EOH":
                headerFields = record
                record = [:]
            case "EOR":
                records.append(record)
                record = [:]
            default:
                break
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
    private(set) var headerFields: [String: String] = [:]
    private(set) var userdefs: [String: ADIF.FieldType] = [:]
    private(set) var appdefs: [String: ADIF.FieldType] = [:]
    private(set) var records: [[String: String]]  = []

    private var namespace: [String] = []
    private var parser: XMLParser
    private var record: [String: String] = [:]
    private var field = ADIF.FieldType(name: "")

    init(adxString: String) {
        let data = Data(adxString.utf8)
        self.parser = XMLParser(data: data)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        namespace.append(elementName)
        
        switch elementName {
            case "ADX", "HEADER", "RECORDS", "RECORD":
                break
            case "APP":
                field = ADIF.FieldType(APP: "APP", programid: attributeDict["PROGRAMID"]!, fieldname: attributeDict["FIELDNAME"]!, type: attributeDict["TYPE"]!)
                if !appdefs.keys.contains(field.displayName) {
                    appdefs[field.displayName] = field
                }
            case "USERDEF":
                if namespace.contains("HEADER") {
                    field = ADIF.FieldType(USERDEF: "USERDEF", fieldid: Int64(attributeDict["FIELDID"]!)!, type: attributeDict["TYPE"]!, enum_: attributeDict["ENUM"], range: attributeDict["RANGE"])
                } else {
                    field = ADIF.FieldType(name: "USERDEF", fieldname: attributeDict["FIELDNAME"]!)
                }
            default:
                field = ADIF.FieldType(name: elementName)
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // Convert CRLF to LF
        let str = string.replacingOccurrences(of: "\r\n", with: "\n")

        switch namespace.last {
            case "ADX", "HEADER", "RECORDS", "RECORD":
                break
            case "USERDEF":
                if namespace.contains("HEADER") {
                    field.fieldname = str
                } else {
                    record[field.displayName] = str
                }
            default:  // APP and other ADIF-difiend fields
                if let _ = record[field.displayName] {
                    record[field.displayName]! += str
                } else {
                    record[field.displayName] = str
                }
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        namespace.removeLast()
        
        switch elementName {
            case "ADX":
                break
            case "HEADER":
                headerFields = record
                record = [:]
            case "RECORDS":
                break
            case "RECORD":
                records.append(record)
                record = [:]
            case "APP":
                break
            case "USERDEF":
                if namespace.contains("HEADER") {
                    userdefs[field.displayName] = field
                }
            default:
                break
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
