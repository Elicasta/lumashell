import XCTest
@testable import LumaShellCore

final class ThemeCatalogTests: XCTestCase {
    func testCatalogContainsEveryThemeExactlyOnce() {
        let ids = ThemeCatalog.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ShellThemeID.allCases.count)
        XCTAssertEqual(Set(ids), Set(ShellThemeID.allCases))
    }

    func testEveryThemeUsesValidHexColors() {
        for theme in ThemeCatalog.all {
            for color in theme.colors.allHexValues {
                XCTAssertTrue(color.isSixDigitHexColor, "\(theme.name) contains invalid color \(color)")
            }
        }
    }

    func testThemeMetricsStayUsable() {
        for theme in ThemeCatalog.all {
            XCTAssertGreaterThanOrEqual(theme.panelHeight, 24)
            XCTAssertLessThanOrEqual(theme.panelHeight, 80)
            XCTAssertGreaterThanOrEqual(theme.cornerRadius, 0)
            XCTAssertFalse(theme.startLabel.isEmpty)
            XCTAssertFalse(theme.computerLabel.isEmpty)
            XCTAssertFalse(theme.trashLabel.isEmpty)
        }
    }

    func testCyberpunkThemeUsesCommandDeckLayout() {
        XCTAssertEqual(ThemeCatalog.theme(.cyberpunk).layout, .commandDeck)
    }
}
