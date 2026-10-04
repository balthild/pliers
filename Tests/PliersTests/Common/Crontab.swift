import PliersCommon
import Testing

@Test func testNormalizeReplacesLineBreaksWithSpaces() {
	#expect(Crontab.normalize(command: "a\nb\r\nc\rd") == "a b c d")
	#expect(Crontab.normalize(command: "  a\n b  ") == "a  b")
	#expect(Crontab.normalize(command: "") == "")
}

@Test func testEntryLineJoinsExpressionAndCommand() {
	let entry = Crontab.Entry(expr: "*/5 * * * *", command: "echo\nhi")
	#expect(entry.line == "*/5 * * * * echo hi")
}

@Test func testMergeAppendsBlockWhenAbsent() {
	let merged = Crontab.merge(
		into: "MAILTO=root\n",
		entries: [.init(expr: "*/5 * * * *", command: "echo hi")],
	)

	let expected = "MAILTO=root\n\n# pliers-start\n*/5 * * * * echo hi\n# pliers-end\n"
	#expect(merged == expected)
}

@Test func testMergeReplacesExistingBlock() {
	let existing = "A=1\n# pliers-start\nold\n# pliers-end\nB=2\n"
	let merged = Crontab.merge(
		into: existing,
		entries: [.init(expr: "* * * * *", command: "true")],
	)

	let expected = "A=1\n# pliers-start\n* * * * * true\n# pliers-end\nB=2\n"
	#expect(merged == expected)
}

@Test func testMergeKeepsMarkersWhenEmpty() {
	let merged = Crontab.merge(into: "", entries: [])
	#expect(merged == "# pliers-start\n# pliers-end\n")
}

@Test func testMergeIsIdempotent() {
	let entries = [Crontab.Entry(expr: "0 0 * * *", command: "backup")]
	let once = Crontab.merge(into: "A=1\n", entries: entries)
	let twice = Crontab.merge(into: once, entries: entries)
	#expect(once == twice)
}
