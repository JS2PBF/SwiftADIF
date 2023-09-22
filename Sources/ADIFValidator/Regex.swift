import Foundation
import RegexBuilder


/// ADIF version unspecified regular expressions
public enum ADIFRegexGen {
    public enum DataTypes {
        public static let awardList = #/.*/#    // no check
        
        public static let creditList = #/.*/#    // no check
        
        public static let sponsoredAwardList = #/.*/#    // no check
        
        public static let boolean = #/[YyNn]/#
        
        public static let digit = #/[0-9]/#
        
        public static let integer = #/-?[0-9]+/#
        
        public static let number = #/-?[0-9]*\.?[0-9]+/#
        
        public static let positiveInteger = #/[0-9]+/#
        
        public static let character = #/[\u{20}-\u{7E}]/#
        
        public static let intlCharacter = #/[^\u{A}\u{D}]/#
        
        // Data (ver. 1.0)
        public static let date = #/(?:19[3-9][0-9]|[2-9][0-9]{3})(?:0[1-9]|1[0-2])(?:[0-2][0-9]|3[0-1])/#
        
        // Time (ver. 1.0)
        public static let time = #/(?:[0-1][0-9]|2[0-3])(?:[0-5][0-9]){2}/#
        
        public static let iotaRefNo = #/(?:[Nn][Aa]|[Ss][Aa]|[Ee][Uu]|[Aa][Ff]|[Oo][Cc]|[Aa][Ss]|[Aa][Nn])-[0-9]{3}/#
        
        public static let string = Regex {
            OneOrMore(character)
        }
        
        public static let intlString = Regex {
            OneOrMore(intlCharacter)
        }
        
        public static let multilineString = #/(?:[\u{20}-\u{7E}]*(?:\u{D}\u{A})?)+/#
       
        public static let intlMultilineString = #/.*/#
        
        public static let enumeration = #/.*/#    // no check
        
        public static let gridSquare = #/[A-Ra-r]{2}(?:[0-9]{2}(?:[A-Xa-x]{2}(?:[0-9]{2})?)?)?/#
        
        public static let gridSquareExt = #/[A-Xa-x]{2}(?:[0-9]{2})?/#
        
        public static let gridSquareList = Regex {
            One(gridSquare)
            ZeroOrMore {
                ","
                gridSquare
            }
        }
        
        public static let location = #/[EeWwNnSs](?:0[0-9]{2}|1[0-7][0-9]|180) [0-5][0-9]\.[0-9]{3}/#
        
        public static let potaRef = #/[A-Za-z]{1,4}-[0-9]{4,5}(?:@[A-Za-z]{2}-[A-Za-z0-9]{1,3})?/#
        
        public static let potaRefList = Regex {
            One(potaRef)
            ZeroOrMore {
                ","
                potaRef
            }
        }
        
        public static let secondarySubdivisionList = #/.*/#    // no check
        
        public static let sotaRef = #/[A-Za-z0-9]{1,8}\/[A-Za-z]{2}-[0-9]{3}/#
        
        public static let wwffRef = #/[A-Za-z0-9]{1,4}[Ff]{2}-[0-9]{4}/#
        
    }
    
    
    public enum DataSpecifier {
        // field name
        // ADIF 'Character's except comma, colon, angle-brackets, curly-brackets
        public static let fieldName = #/[\x21-\x2B\x2D-\x39\x3B\x3D\x3F-\x7A\x7C\x7E](?:[\x20-\x2B\x2D-\x39\x3B\x3D\x3F-\x7A\x7C\x7E]*[\x21-\x2B\x2D-\x39\x3B\x3D\x3F-\x7A\x7C\x7E])?/#
        
        // data length
        public static let dataLength = #/[0-9]+/#
        
        // data type indicator
        public static let dataType = #/[A-Za-z]/#
    }
    
    
    public enum ADIFormat {
        private static let lenTypeRe = Regex {
            ":"
            TryCapture {
                DataSpecifier.dataLength
            } transform: { str -> Int? in
                return Int(str)
            }
            Optionally {
                Regex {
                    ":"
                    TryCapture {
                        DataSpecifier.dataType
                    } transform: { str -> String in
                        return String(str)
                    }
                }
            }
        }
        public static let tag = Regex {
            "<"
            TryCapture {
                DataSpecifier.fieldName
            } transform: { str -> String in
                return String(str)
            }
            Optionally {
                lenTypeRe
            }
            ">"
        }
        
        public static let appdefFieldName = Regex {
            ChoiceOf {
                "APP"
                "app"
            }
            "_"
            TryCapture {
                ADIFRegexGen.DataSpecifier.fieldName
            } transform: { str -> String in
                return String(str)
            }
            "_"
            TryCapture {
                ADIFRegexGen.DataSpecifier.fieldName
            } transform: { str -> String in
                return String(str)
            }
        }
        
        public static let userdefRange = Regex {
            "{"
            TryCapture {
                ADIFRegexGen.DataTypes.number
            } transform: { str -> Double? in
                return Double(str)
            }
            ":"
            TryCapture {
                ADIFRegexGen.DataTypes.number
            } transform: { str -> Double? in
                return Double(str)
            }
            "}"
        }
        
        public static let userdefEnum = Regex {
            "{"
            TryCapture {
                ADIFRegexGen.DataTypes.string
            } transform: { str -> String in
                return String(str)
            }
            "}"
        }
        
    }
}


//public enum ADIFRegex3_1_4 {
//    public enum DataTypes  {
//
//    }
//
//
//    public enum DataSpecifier {
//        // Data Type Indicator
//        public static let dataType = #/[BbNnDdTtSsIiMmGgEeLl]/#
//    }
//}

