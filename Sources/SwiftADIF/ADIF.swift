import Foundation
import TabularData

/// An Amateur Data Interchange Format (ADIF) object.
public struct ADIF {
    /*
     * Properties
     */
    /// An ADIF header object.
    public var header: Header = Header()
    /// ADIF records.
    public var records: [Record] = []
    /// The maximun number of the reicords 'id'.
    var maxRecordId: Int? = nil
    
    
    /*
     * Initializers
     */
    /// Creates a new empty instance of an ADIF.
    public init() { }
    
    /// Creates a new instance of an ADIF from an ADI string.
    /// - Parameter adiString: A string of an ADI document.
    public init?(adiString: String) {
        let decoder = ADIDecoder(string: adiString)
        do {
            try decoder.decode()
            header = Header(fields: decoder.headerFields, userdefs: decoder.userdefs)
            records = decoder.records
            maxRecordId = records.last?.id
        } catch {
            return nil
        }
    }
    
    /// Creates a new instance of an ADIF from an ADX string.
    /// - Parameter adxString: A string of an ADX document.
    public init?(adxString: String) {
        let decoder = ADXDecoder(string: adxString)
        do {
            try decoder.decode()
            header = Header(fields: decoder.headerFields, userdefs: decoder.userdefs)
            records = decoder.records
            maxRecordId = records.last?.id
        } catch {
            return nil
        }
    }
        
        
    /*
     * Methods
     */
    /// Sort the records in order of appearance in the file.
    /// - Parameter reverse: If true, sort records in decreasing order. If false, sort them in increasing order.
    mutating public func sortById(reverse: Bool = false) {
        records.sort { (lRec, rRec) in
            return reverse ? lRec.id > rRec.id : lRec.id < rRec.id
        }
    }
    
    /// Sort the records by "QSO\_DATE" and "TIME\_ON".
    /// - Parameter reverse: If true, sort records in decreasing order. If false, sort them in increasing order.
    mutating public func sortByDatetime(reverse: Bool = false) {
        records.sort { (lRec, rRec) in
            let lval = (lRec.fields["QSO_DATE"]?.data ?? "00000000") + (lRec.fields["TIME_ON"]?.data ?? "000000")
            let rval = (rRec.fields["QSO_DATE"]?.data ?? "00000000") + (rRec.fields["TIME_ON"]?.data ?? "000000")
            return reverse ? lval > rval : lval < rval
        }
    }

    /// Sort the records by "CALL".
    /// - Parameter reverse: If true, sort records in decreasing order. If false, sort them in increasing order.
    mutating public func sortByCall(reverse: Bool = false) {
        records.sort { (lRec, rRec) in
            let lval = (lRec.fields["CALL"]?.data ?? "").uppercased()
            let rval = (rRec.fields["CALL"]?.data ?? "").uppercased()
            return reverse ? lval > rval : lval < rval
        }
    }
        
    
    /*
     * Child objects
     */
    /// An ADIF header object that contains header fields and user-defined field definitions.
    @dynamicMemberLookup public struct Header {
        /// A dictionary of header fields with their field names.
        public var fields: [String: Field] = [:]
        
        /// A dictionary of user-defined fields with  their display names.
        public var userdefs: [String: Field] = [:]
        
        public subscript(dynamicMember key: String) -> Field? {
            get { fields[key] }
            set { fields[key] = newValue }
        }
    }
    
    
    /// An ADIF record object.
    @dynamicMemberLookup public struct Record {
        let id: Int
        
        /// A dictionary of QSO fields with their field names.
        public var fields: [String: Field] = [:]
        
        public subscript(dynamicMember key: String) -> Field? {
            get { fields[key] }
            set { fields[key] = newValue }
        }
        
        func newRecord() -> Self {
            return Self(id: id + 1)
        }
    }
    
    
    /// An ADIF field object.
    @dynamicMemberLookup public struct Field: Identifiable {
        public let id = UUID()
        
        /// The field name including "APP" and "USERDEF" (i.e. element name of ADX).
        public let name: String
        
        /// A data value.
        public var data: String? = nil
        
        /// Optional attributes, especially for application- and user-defined fields (e.g. TYPE, FIELDNAME, PROGRAMID, FIELDID, ENUM, RANGE).
        public var attr: [String: String] {
            get {
                return _attr
            }
            set {
                let keys = newValue.keys
                keys.forEach { key in
                    let upperKey = key.uppercased()
                    switch upperKey {
                        case "TYPE", "ENUM":
                            _attr[upperKey] = newValue[key]!.uppercased()
                        default:
                            _attr[upperKey] = newValue[key]
                    }
                }
            }
        }
        
        private var _attr: [String: String] = [:]
        
        public subscript(dynamicMember key: String) -> String? {
            get { attr[key] }
            set { attr[key] = newValue }
        }
        
        /// Creates a new instance of a field.
        /// - Parameters:
        ///   - name: The field name.
        ///   - data: A string of the field data value.
        ///   - attr: Attributes for the field.
        public init(name: String, data: String? = nil, attr: [String : String] = [:]) {
            self.name = name.uppercased()
            self.data = data
            self.attr = attr
        }
        
        /// The display name of the field which is same as the ADI data-specifier field name.
        ///
        /// The display name is same as their field name except application- and user-defined fields.
        /// In the case of application-defined field, their display name is 'APP\_*PROGRAMID*\_*FIELDNAME*'.
        /// The display name of user-defined fieid is same as their FIELDNAME.
        public var displayName: String {
            switch name {
                case "APP":
                    // Return "APP_PROGRAMID_FIELDNAME"
                    return [name, attr["PROGRAMID"]!, attr["FIELDNAME"]!].joined(separator: "_").uppercased()
                case "USERDEF":
                    if let fieldname = attr["FIELDNAME"] {
                        return fieldname.uppercased()
                    } else {
                        return data!.uppercased()
                    }
                default:
                    return name.uppercased()
            }
        }
    }
    
}
