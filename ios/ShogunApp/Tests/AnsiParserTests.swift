import XCTest
import SwiftUI
@testable import ShogunApp

final class AnsiParserTests: XCTestCase {

    // MARK: - Basic Foreground Colors (8 tests)

    func testBasicForegroundBlack() {
        let input = "\u{001B}[30mDark\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Dark")
    }

    func testBasicForegroundRed() {
        let input = "\u{001B}[31mHello\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Hello")
        // Verify color attribute exists on the run
        let run = result.runs.first!
        XCTAssertNotNil(run.foregroundColor)
    }

    func testBasicForegroundGreen() {
        let input = "\u{001B}[32mOK\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "OK")
        XCTAssertNotNil(result.runs.first?.foregroundColor)
    }

    func testBasicForegroundYellow() {
        let input = "\u{001B}[33mWarn\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Warn")
        XCTAssertNotNil(result.runs.first?.foregroundColor)
    }

    func testBasicForegroundBlue() {
        let input = "\u{001B}[34mInfo\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Info")
        XCTAssertNotNil(result.runs.first?.foregroundColor)
    }

    func testBasicForegroundMagenta() {
        let input = "\u{001B}[35mDebug\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Debug")
        XCTAssertNotNil(result.runs.first?.foregroundColor)
    }

    func testBasicForegroundCyan() {
        let input = "\u{001B}[36mTrace\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Trace")
        XCTAssertNotNil(result.runs.first?.foregroundColor)
    }

    func testBasicForegroundWhite() {
        let input = "\u{001B}[37mLight\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Light")
        XCTAssertNotNil(result.runs.first?.foregroundColor)
    }

    // MARK: - Bright Foreground Colors (8 tests)

    func testBrightForegroundBlack() {
        let input = "\u{001B}[90mGray\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Gray")
        XCTAssertNotNil(result.runs.first?.foregroundColor)
    }

    func testBrightForegroundRed() {
        let input = "\u{001B}[91mError!\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Error!")
        XCTAssertNotNil(result.runs.first?.foregroundColor)
    }

    func testBrightForegroundGreen() {
        let input = "\u{001B}[92mSuccess\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Success")
    }

    func testBrightForegroundYellow() {
        let input = "\u{001B}[93mCaution\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Caution")
    }

    func testBrightForegroundBlue() {
        let input = "\u{001B}[94mLink\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Link")
    }

    func testBrightForegroundMagenta() {
        let input = "\u{001B}[95mSpecial\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Special")
    }

    func testBrightForegroundCyan() {
        let input = "\u{001B}[96mHighlight\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Highlight")
    }

    func testBrightForegroundWhite() {
        let input = "\u{001B}[97mBright\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Bright")
    }

    // MARK: - 256 Color

    func testForeground256Color() {
        // Color 196 = bright red in 256-color palette (6x6x6 cube)
        let input = "\u{001B}[38;5;196mRed256\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Red256")
        XCTAssertNotNil(result.runs.first?.foregroundColor)
    }

    // MARK: - Truecolor

    func testForegroundTruecolor() {
        let input = "\u{001B}[38;2;255;128;0mOrange\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Orange")
        XCTAssertNotNil(result.runs.first?.foregroundColor)
    }

    // MARK: - Bold

    func testBold() {
        let input = "\u{001B}[1mStrong\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Strong")
        let run = result.runs.first!
        XCTAssertNotNil(run.font)
    }

    // MARK: - Reset

    func testReset() {
        let input = "\u{001B}[31mRed\u{001B}[0mNormal"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "RedNormal")
        let runs = Array(result.runs)
        XCTAssertEqual(runs.count, 2)
        // First run has color, second run does not
        XCTAssertNotNil(runs[0].foregroundColor)
        XCTAssertNil(runs[1].foregroundColor)
    }

    // MARK: - Compound (color + bold)

    func testCompoundColorAndBold() {
        let input = "\u{001B}[1;33mBoldYellow\u{001B}[0m"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "BoldYellow")
        let run = result.runs.first!
        XCTAssertNotNil(run.foregroundColor)
        XCTAssertNotNil(run.font)
    }

    // MARK: - Plain text (no ANSI)

    func testPlainText() {
        let input = "Hello, world!"
        let result = AnsiParser.parse(input)
        XCTAssertEqual(String(result.characters), "Hello, world!")
        let runs = Array(result.runs)
        XCTAssertEqual(runs.count, 1)
        XCTAssertNil(runs[0].foregroundColor)
    }

    // MARK: - Empty string

    func testEmptyString() {
        let result = AnsiParser.parse("")
        XCTAssertEqual(String(result.characters), "")
    }

    // MARK: - stripAnsi

    func testStripAnsi() {
        let input = "\u{001B}[31mRed\u{001B}[0m Normal \u{001B}[1;34mBoldBlue\u{001B}[0m"
        let result = AnsiParser.stripAnsi(input)
        XCTAssertEqual(result, "Red Normal BoldBlue")
    }
}
