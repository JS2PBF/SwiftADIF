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
    var headerFields: [String: ADIF.Field] { get }
    var userdefs: [String: ADIF.Field] { get }
    var records: [ADIF.Record] { get }
    
    // Decoding
    func decode() throws
}


class ADIDecoder: Decoder, ADIParserDelegate {
    // Return values
    private(set) var headerFields: [String: ADIF.Field] = [:]
    private(set) var userdefs: [String: ADIF.Field] = [:]
    private(set) var records: [ADIF.Record]  = []
    
    private var parser: ADIParser
    private var record = ADIF.Record(id: 0)
    private var field = ADIF.Field(name: "")
    private var inHead: Bool = false
    
    init(adiString: String) {
        self.parser = ADIParser(string: adiString)
    }
    
    func parser(_ parser: ADIParser, didStartDataSpecifier fieldName: String, dataLength: Int?, dataType: String?) {
        self.field = ADIF.Field(name: fieldName)
        if let _ = dataType {
            field.TYPE = dataType
        }
        
        // Application-defined field
        if let match = fieldName.wholeMatch(of: ADIFRegexGen.ADIFormat.appdefFieldName) {
            field = ADIF.Field(name: "APP")
            field.PROGRAMID = match.1
            field.FIELDNAME = match.2
            field.TYPE = dataType ?? "M"
        }
        
        // User-defined field in header
        if let match = fieldName.firstMatch(of: #/^(?:USERDEF|userdef)(\d+)/#) {
            inHead = true
            field = ADIF.Field(name: "USERDEF")
            field.FIELDID = String(match.1)
            if let _ = dataType {
                field.TYPE = dataType
            }
        }
        
        // User-defined field in record
        if userdefs.keys.contains(fieldName) {
            field = ADIF.Field(name: "USERDEF")
            field.FIELDNAME = fieldName
        }
    }
    
    func parser(_ parser: ADIParser, foundData string: String) {
        // Convert CRLF to LF
        let str = string.replacingOccurrences(of: "\r\n", with: "\n")
        field.data = str
        
        switch field.name {
            // User-defiend field
            case "USERDEF":
                if inHead {
                    let userdefDataRe = Regex {
                        Capture { ADIFRegexGen.DataSpecifier.fieldName }
                        ","
                        Capture { ADIFRegexGen.ADIFormat.userdefEnum }
                    }
                    if let match = str.firstMatch(of: userdefDataRe) {
                        field.data = String(match.1)
                        if let _ = match.2.wholeMatch(of: ADIFRegexGen.ADIFormat.userdefRange) {
                            field.RANGE = String(match.2)
                        } else {
                            field.ENUM = String(match.2)
                        }
                    }
                } else {
                    fallthrough
                }
            default:
                record.fields[field.displayName] = field
        }
    }
    
    func parser(_ parser: ADIParser, didEndDataSpecifier fieldName: String) {
        switch field.name {
            case "USERDEF":
                if inHead {
                    userdefs[field.displayName] = field
                }
            case "EOH":
                headerFields = record.fields
                inHead = false
                record = ADIF.Record(id: 0)
            case "EOR":
                records.append(record)
                record = record.newRecord()
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
    private(set) var headerFields: [String: ADIF.Field] = [:]
    private(set) var userdefs: [String: ADIF.Field] = [:]
    private(set) var records: [ADIF.Record]  = []
    
    private var parser: XMLParser
    private var record = ADIF.Record(id: 0)
    private var field = ADIF.Field(name: "")
    private var namespace: [String] = []

    init(adxString: String) {
        let data = Data(adxString.utf8)
        self.parser = XMLParser(data: data)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        namespace.append(elementName)
        
        switch elementName {
            case "ADX", "HEADER", "RECORDS", "RECORD":
                break
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
                if let _ = field.data {
                    field.data! += str
                } else {
                    field.data = str
                }
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
