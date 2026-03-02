import XCTest
@testable import ShogunApp

final class RateLimitParserTests: XCTestCase {

    // MARK: - 正常系

    func testNormalOutput() {
        // ratelimit_check.sh 実際の出力形式に合わせたサンプル
        let output = """

══ レートリミット状況 (2026-03-02) ══

── Claude Max ────────────────────────
  Agents: shogun(Opus), karo(Sonnet)
  ── Quota ──
  5h window:  19.0% used  (resets 2026-03-02T02:59)
  7d window:  18.0% used  (resets 2026-03-06)
  Status: OK
"""
        let result = RateLimitParser.parse(output)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.percentage, 0.19, accuracy: 0.001)
        XCTAssertEqual(result?.label, "19.0% (5h)")
        XCTAssertEqual(result?.level, .green)
    }

    func testYellowLevel() {
        // 61〜85% → yellow
        let output = "  5h window:  72.5% used  (resets 2026-03-02T10:00)\n"
        let result = RateLimitParser.parse(output)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.percentage, 0.725, accuracy: 0.001)
        XCTAssertEqual(result?.label, "72.5% (5h)")
        XCTAssertEqual(result?.level, .yellow)
    }

    func testRedLevel() {
        // 86〜100% → red
        let output = "  5h window:  92.0% used  (resets 2026-03-02T14:00)\n"
        let result = RateLimitParser.parse(output)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.percentage, 0.92, accuracy: 0.001)
        XCTAssertEqual(result?.level, .red)
    }

    // MARK: - 境界値

    func testBoundary60Percent() {
        // 60.0% → green (< 61)
        let output = "  5h window:  60.0% used  (resets 2026-03-02T05:00)\n"
        let result = RateLimitParser.parse(output)
        XCTAssertEqual(result?.level, .green)
    }

    func testBoundary61Percent() {
        // 61.0% → yellow
        let output = "  5h window:  61.0% used  (resets 2026-03-02T05:00)\n"
        let result = RateLimitParser.parse(output)
        XCTAssertEqual(result?.level, .yellow)
    }

    func testBoundary85Percent() {
        // 85.0% → yellow (< 86)
        let output = "  5h window:  85.0% used  (resets 2026-03-02T05:00)\n"
        let result = RateLimitParser.parse(output)
        XCTAssertEqual(result?.level, .yellow)
    }

    func testBoundary86Percent() {
        // 86.0% → red
        let output = "  5h window:  86.0% used  (resets 2026-03-02T05:00)\n"
        let result = RateLimitParser.parse(output)
        XCTAssertEqual(result?.level, .red)
    }

    // MARK: - 異常系

    func testEmptyString() {
        XCTAssertNil(RateLimitParser.parse(""))
    }

    func testInvalidFormat() {
        XCTAssertNil(RateLimitParser.parse("No rate limit info here"))
    }

    func testOnlyNewline() {
        XCTAssertNil(RateLimitParser.parse("\n\n\n"))
    }

    func testWith7dWindowOnly() {
        // 7d window のみ → 5h がないのでnil
        let output = "  7d window:  30.0% used  (resets 2026-03-06)\n"
        XCTAssertNil(RateLimitParser.parse(output))
    }
}
