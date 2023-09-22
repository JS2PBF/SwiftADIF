import XCTest
@testable import ADIFValidator

final class ADIFRegexTest: XCTestCase {
    func testMultilineString() throws {
        let input = "Quo usque tandem abutere, Catilina, patientia nostra?\r\nQuam diu etiam furor iste tuus nos eludet?"
        let match = input.wholeMatch(of: ADIFRegexGen.DataTypes.multilineString)
        XCTAssertNotNil(match)
    }
    
}
