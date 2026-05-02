import Foundation

var passCount = 0
var failCount = 0
var currentGroup = ""

func group(_ name: String) {
    currentGroup = name
    print("\n━━━ \(name) ━━━")
}

func check(_ condition: Bool, _ message: String, file: String = #fileID, line: Int = #line) {
    if condition {
        passCount += 1
        print("  ✅ \(message)")
    } else {
        failCount += 1
        print("  ❌ \(message)  [\(file):\(line)]")
    }
}

func checkEqual<T: Equatable>(_ a: T, _ b: T, _ message: String, file: String = #fileID, line: Int = #line) {
    if a == b {
        passCount += 1
        print("  ✅ \(message)")
    } else {
        failCount += 1
        print("  ❌ \(message)  — got \(a), expected \(b)  [\(file):\(line)]")
    }
}

func checkNil<T>(_ a: T?, _ message: String, file: String = #fileID, line: Int = #line) {
    if a == nil {
        passCount += 1
        print("  ✅ \(message)")
    } else {
        failCount += 1
        print("  ❌ \(message)  — expected nil, got \(a!)  [\(file):\(line)]")
    }
}

func checkNotNil<T>(_ a: T?, _ message: String, file: String = #fileID, line: Int = #line) {
    if a != nil {
        passCount += 1
        print("  ✅ \(message)")
    } else {
        failCount += 1
        print("  ❌ \(message)  — expected non-nil  [\(file):\(line)]")
    }
}

@main
struct TestRunner {
    static func main() async {
        print("🧪 Nook Swift Unit Tests\n")

        testModelCodable()
        testElectronJSONCompat()
        testTaskPriority()
        testDateFormatting()
        testOverdueDetection()
        testSettingsCodable()
        testSnippetCodable()
        await testStoreCRUD()
        await testStoreSubtasks()
        await testStoreTags()
        await testStoreSnippets()
        await testStoreSettings()
        await testStoreReorder()
        testCoordinateConversion()
        testTriggerZones()
        testShouldHide()
        testPanelFrame()
        testColorHex()

        // Edge case tests
        testUnicodeHandling()
        await testEmptyInputHandling()
        testDateFormattingEdgeCases()
        testOverdueEdgeCases()
        await testStorePersistence()
        testCorruptedJSON()
        await testStoreRapidOperations()
        testMultiDisplayTriggerZones()
        testPanelFrameEdgeCases()
        testHideTimingEdgeCases()
        await testStoreUpdateIsolation()
        await testTagColorEdgeCases()
        await testReorderEdgeCases()
        testJSONOutputElectronCompat()
        testStoreDataInit()
        await testColorHexRobustness()

        print("\n━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Results: \(passCount) passed, \(failCount) failed")
        if failCount > 0 {
            print("⚠️  \(failCount) test(s) FAILED")
            exit(1)
        } else {
            print("🎉 All tests passed!")
        }
    }
}
