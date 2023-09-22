import Foundation
import RegexBuilder

import ADIFValidator


/// The errors will occor during ADI parsering.
public enum ADIParseError: Error, LocalizedError {
    case noDelegate
    
    public var errorDescription: String? {
        switch self {
            case .noDelegate:
                return String(describing: type(of: self)) + ": 'ADIRegex.delegate' is not defined."
        }
    }
}


/// An event driven parser of ADI documents.
open class ADIParser {
    private let rawString: String
    
    /// Initializes a parser with the URL of an ADI document.
    /// - Parameters:
    ///   - url: URL of an ADI document.
    ///   - delegate: Delegate object that receives messages about the parsing process.
    public convenience init?(contentsOf url: URL, ADIParserDelegate delegate: (any ADIParserDelegate)? = nil) {
        guard let string = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        self.init(string: string, ADIParserDelegate: delegate)
    }
    
    /// Initializes a parser with the ADI string.
    /// - Parameters:
    ///   - string: String with ADI format.
    ///   - delegate: Delegate object that receives messages about the parsing process.
    public init(string: String, ADIParserDelegate delegate: (any ADIParserDelegate)? = nil) {
        self.rawString = string
        self.delegate = delegate
    }
    
    /// Delegate object that receives messages about the parsing process.
    public var delegate: ADIParserDelegate?
    
    /// Start the event-driven parsing operation.
    /// - Returns: 'true' if the parsing operation succeeds; 'false' if an error occurs.
    public func parse() -> Bool {
        guard let _ = delegate else {
            parserError = ADIParseError.noDelegate
            return false
        }
        
        // Start parsing
        lineNumber = 1
        delegate!.parserDidStartDocument(self)
        
        // Parse contents
        var str = rawString
        let tagRe = Regex {
            #/^([\s\S]*?)/#
            ADIFRegexGen.ADIFormat.tag
        }
        while let match = str.firstMatch(of: tagRe) {
            lineNumber += match.0.matches(of: #/\R/#).count
            
            // Check non-data-specifier charactors
            let comment = String(match.1)
            if let _ = comment.firstMatch(of: #/\S+/#) {
                delegate!.parser(self, foundComment: String(comment))
            }
            
            // Parse data-specifier tag
            let fieldName = match.2
            let dataLength: Int? = match.3
            let dataType: String? = match.4 as? String
            delegate!.parser(self, didStartDataSpecifier: fieldName, dataLength: dataLength, dataType: dataType)
            str.removeSubrange(..<match.range.upperBound)
            
            // Parse data
            // Use UTF8View to treat CRLF as two characters.
            if dataLength ?? 0 > 0 {
                let utf = str.utf8
                let data = String(decoding: utf.prefix(dataLength!), as: UTF8.self)
                lineNumber += data.matches(of: #/\R/#).count
                delegate!.parser(self, foundData: data)
                str = String(decoding: utf.dropFirst(dataLength!), as: UTF8.self)
            }
            
            delegate!.parser(self, didEndDataSpecifier: fieldName)
        }
        
        // End parsing
        delegate!.parserDidEndDocument(self)
        
        return true
    }
    
    /// Line number of the ADI document being processed by the parser.
    private(set) public var lineNumber: Int = 0
    
    /// ADIParseError object from which you can obtain information about a parsing error.
    private(set) public var parserError: Error?
}


/// The interface an ADI parser uses to inform its delegate about the content of the parsed document.
public protocol ADIParserDelegate {
    /// Sent by the parser object to the delegate when it begins parsing a document.
    /// - Parameter parser: Parser object.
    func parserDidStartDocument(_ parser: ADIParser)
    
    /// Sent by the parser object to the delegate when it has successfully completed parsing.
    /// - Parameter parser: Parser object.
    func parserDidEndDocument(_ parser: ADIParser)
    
    /// Sent by a parser object to its delegate when it encounters a given ADI data-specifier.
    /// - Parameters:
    ///   - parser: Parser object.
    ///   - fieldName: Field name of the data-specifier.
    ///   - dataLength: Data length of the data-specifier.
    ///   - dataType: data type indicator of the data-specifier.
    func parser(_ parser: ADIParser, didStartDataSpecifier fieldName: String, dataLength: Int?, dataType: String?)
    
    /// Sent by a parser object to its delegate after parsing the given data-specifier.
    /// - Parameters:
    ///   - parser: Parser object.
    ///   - fieldName: Field name of the current data-specifier.
    func parser(_ parser: ADIParser, didEndDataSpecifier fieldName: String)
    
    /// Sent by a parser object to provide its delegate with a string representing all of the data of the current data-specifier.
    /// - Parameters:
    ///   - parser: Parser object.
    ///   - string: String that is a complete textual content of the current data-specifier.
    func parser(_ parser: ADIParser, foundData string: String)
    
    /// Sent by a parser object to its delegate when it encounters non-white-space charactors that doesn't belogn to data-specifiers.
    /// - Parameters:
    ///   - parser: Parser object
    ///   - comment: String that is a non-data-specifier text in the ADI document.
    func parser(_ parser: ADIParser, foundComment comment: String)
    
    /// Sent by a parser object to its delegate when it encounters a fatal error.
    /// - Parameters:
    ///   - parser: Parser object.
    ///   - parseError: ADIParseError object describing the parsing error that occurred.
    func parser(_ parser: ADIParser, parseErrorOccurred parseError: Error)
}

public extension ADIParserDelegate {
    func parserDidStartDocument(_ parser: ADIParser) { }
    func parserDidEndDocument(_ parser: ADIParser) { }
    func parser(_ parser: ADIParser, didStartDataSpecifier fieldName: String, dataLength: Int?, dataType: String?) { }
    func parser(_ parser: ADIParser, didEndDataSpecifier fieldName: String) { }
    func parser(_ parser: ADIParser, foundData string: String) { }
    func parser(_ parser: ADIParser, foundComment comment: String) { }
    func parser(_ parser: ADIParser, parseErrorOccurred parseError: Error) { }
}
