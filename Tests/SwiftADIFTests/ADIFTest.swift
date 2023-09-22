import XCTest
@testable import SwiftADIF


final class ADIFTest: XCTestCase {
    func test() throws {
        let input = """
            <CALL:6>JS2PBF
            <BAND:2>2M
            <EOR>
        """
        guard let adif = ADIF(adiString: input) else {
            XCTFail()
            return
        }
        adif.records.CALL[0] = "JA6OTC"
        adif.header.ADIF_VER = "3.1.4"
        XCTAssertEqual(adif.records.CALL[0]! as! String, "JA6OTC")
        XCTAssertEqual(adif.header.ADIF_VER, "3.1.4")
    }
}
