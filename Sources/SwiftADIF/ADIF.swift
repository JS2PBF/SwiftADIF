import Foundation
import TabularData

/// Simple Amateur Data Interchange Format (ADIF) parser.
open class ADIF {
    /// ADIF header contents.
    public var header: Header
    /// ADIF record contents.
    public var records: Records
    
    private static let minField = ["QSO_DATE", "TIME_ON", "CALL", "BAND", "FREQ", "MODE"]
    
    /// Initialize a ADIF with ADI document.
    /// - Parameter adiString: String of an ADI document.
    public init?(adiString: String) {
        let decoder = ADIDecoder(adiString: adiString)
        do {
            (header, records) = try Self.getContents(decoder: decoder)
        } catch {
            return nil
        }
    }
    
    /// Initialize a ADIF with ADX document.
    /// - Parameter adxString: String of an ADX document.
    public init?(adxString: String) {
        let decoder = ADXDecoder(adxString: adxString)
        do {
            (header, records) = try Self.getContents(decoder: decoder)
        } catch {
            return nil
        }
    }
    
    private static func getContents(decoder: any Decoder) throws -> (Header, Records) {
        // Decode
        try decoder.decode()
        
        // Initialize Header
        let header = Header(fields: decoder.headerFields, userdefs: decoder.userdefs, appdefs: decoder.appdefs)
        
        // Initialize Records
        var fieldNames = minField
        var names: Set<String> = []
        decoder.records.forEach { names.formUnion($0.keys) }
        names.subtract(Set(minField))
        fieldNames += Array(names)
        
        var records = Records()
        fieldNames.forEach { name in
            var col = Column<String>(name: name, capacity: 0)
            decoder.records.forEach { col.append(contentsOf: [$0[name] ?? ""]) }
            records.append(column: col)
        }
        
        return (header, records)
    }
    
    /// ADIF header contens that contains header fields, user-defined field definitions, and application-defined field definitions.
    @dynamicMemberLookup public struct Header {
        /// Dictionary of header field  data with their field name.
        public var fields: [String: String] = [:]
        /// Dictionary of user-defined fields with  their display name.
        public var userdefs: [String: FieldType] = [:]
        /// Dictioanry of application-defined fields with their display name.
        public var appdefs: [String: FieldType] = [:]
        
        public subscript(dynamicMember key: String) -> String? {
            get { fields[key] }
            set { fields[key] = newValue }
        }
        
        /// Array of header field names stored in Header.fields.
        public var fieldNames: [String] {
            Array(fields.keys)
        }
    }
    
    
    public typealias Records = DataFrame
    
    
    /// Field definition.
    public struct FieldType: Equatable {
        /// ADIF field name including "APP" and "USERDEF".
        public let name: String
        /// Data type indicator.
        public let type: String?
        
        /// Application- or User-defiend field name.
        public var fieldname: String? {
            didSet { fieldname = fieldname?.uppercased() }
        }
        
        // For application-defined fields
        /// Name of application will process the ADIF file in which the application-defined field appears.
        public var programid: String? {
            didSet { programid = programid?.uppercased() }
        }
        
        // For user-defined fields
        /// User-defined field index
        public var fieldid: Int64?
        /// User-defined field data enumeration which is a comma-delimited list of string enclosed in curly brackets.
        public var enum_: String? {
            didSet { enum_ = enum_?.uppercased() }
        }
        /// User-defined field data range which is a lower bound and a larger upper bound separated by a colon enclosed in curly brackets.
        public var range: String?
        
        /// Display name of the field which is same as the ADI data-specifier field name.
        ///
        /// The display name is same as their field name except application- and user-defined fields.
        /// In the case of application-defined field, their display name 'APP_*PROGRAMID_FIELDNAME*'.
        /// The display name of user-defined fieid is same as their field name.
        public var displayName: String {
            switch name {
                case "APP":
                    // Return "APP_PROGRAMID_FIELDNAME"
                    return [name, programid!, fieldname!].joined(separator: "_")
                case "USERDEF":
                    return fieldname!
                default:
                    return name.uppercased()
            }
            
        }
        
        init(APP name: String = "APP", programid: String, fieldname: String, type: String? = nil) {
            self.init(name: "APP", type: type, fieldname: fieldname, programid: programid, fieldid: nil, enum_: nil,
                      range: nil)
        }
        
        init(USERDEF name: String = "USERDEF", fieldid: Int64, type: String? = nil, fieldname: String? = nil, enum_: String? = nil, range: String? = nil) {
            self.init(name: "USERDEF", type: type, fieldname: fieldname, programid: nil, fieldid: fieldid, enum_: enum_,
                      range: range)
        }
        
        init(name: String, type: String? = nil, fieldname: String? = nil, programid: String? = nil, fieldid: Int64? = nil, enum_: String? = nil, range: String? = nil) {
            self.name = name.uppercased()
            self.type = type?.uppercased()
            self.programid = programid?.uppercased()
            self.fieldname = fieldname?.uppercased()
            self.fieldid = fieldid
            self.enum_ = enum_?.uppercased()
            self.range = range
        }
    }
}
