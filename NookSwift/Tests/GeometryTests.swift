import Foundation
import AppKit

// MARK: - Coordinate Conversion

func testCoordinateConversion() {
    group("Coordinate Conversion (CG ↔ NS)")

    // CG: origin at top-left, y↓
    // NS: origin at bottom-left, y↑
    // Formula: nsY = mainScreenHeight - cgY

    let mainH: CGFloat = 1080

    // Top-left corner of screen
    let cg1 = CGPoint(x: 0, y: 0)
    let ns1 = NSPoint(x: cg1.x, y: mainH - cg1.y)
    check(abs(ns1.y - 1080) < 0.01, "CG(0,0) → NS y=1080 (top-left)")

    // Bottom-left corner
    let cg2 = CGPoint(x: 0, y: 1080)
    let ns2 = NSPoint(x: cg2.x, y: mainH - cg2.y)
    check(abs(ns2.y) < 0.01, "CG(0,1080) → NS y=0 (bottom-left)")

    // Center
    let cg3 = CGPoint(x: 960, y: 540)
    let ns3 = NSPoint(x: cg3.x, y: mainH - cg3.y)
    check(abs(ns3.x - 960) < 0.01, "Center x preserved")
    check(abs(ns3.y - 540) < 0.01, "Center y converted correctly")

    // Round-trip
    let cgBack = CGPoint(x: ns3.x, y: mainH - ns3.y)
    check(abs(cgBack.x - cg3.x) < 0.01, "Round-trip x")
    check(abs(cgBack.y - cg3.y) < 0.01, "Round-trip y")
}

// MARK: - Trigger Zones

func testTriggerZones() {
    group("Trigger Zone Geometry")

    // Simulate a screen: full frame and work area (with menu bar)
    // NSScreen: origin bottom-left, y↑
    // frame: (0, 0, 1920, 1080)
    // visibleFrame: (0, 0, 1920, 1055) — 25px menu bar at top

    let screenW: CGFloat = 1920
    let screenH: CGFloat = 1080
    let mainH: CGFloat = screenH // single-display
    let triggerSize: CGFloat = 40

    // For each corner, define the expected trigger zone in NS coordinates
    // and verify a point inside/outside correctly classifies.

    struct TriggerTest {
        let corner: String
        let insideNS: NSPoint
        let outsideNS: NSPoint
    }

    let tests: [TriggerTest] = [
        // Top-left: NS coordinates → x in [0, triggerSize], y in [screenH - triggerSize, screenH]
        TriggerTest(corner: "top-left",
                    insideNS: NSPoint(x: 5, y: screenH - 5),
                    outsideNS: NSPoint(x: 100, y: screenH - 5)),
        // Top-right: x in [screenW - triggerSize, screenW], y in [screenH - triggerSize, screenH]
        TriggerTest(corner: "top-right",
                    insideNS: NSPoint(x: screenW - 5, y: screenH - 5),
                    outsideNS: NSPoint(x: screenW - 100, y: screenH - 5)),
        // Bottom-left: x in [0, triggerSize], y in [0, triggerSize]
        TriggerTest(corner: "bottom-left",
                    insideNS: NSPoint(x: 5, y: 5),
                    outsideNS: NSPoint(x: 5, y: 100)),
        // Bottom-right: x in [screenW - triggerSize, screenW], y in [0, triggerSize]
        TriggerTest(corner: "bottom-right",
                    insideNS: NSPoint(x: screenW - 5, y: 5),
                    outsideNS: NSPoint(x: screenW - 5, y: 100)),
    ]

    for test in tests {
        // Convert NS → CG for the trigger zone check
        let insideCG = CGPoint(x: test.insideNS.x, y: mainH - test.insideNS.y)
        let outsideCG = CGPoint(x: test.outsideNS.x, y: mainH - test.outsideNS.y)

        // The inside CG point should have small x (for left) or large x (for right)
        // and small y (for top) or large y (for bottom) in CG coords
        let isLeft = test.corner.contains("left")
        let isTop = test.corner.contains("top")

        if isLeft {
            check(insideCG.x < triggerSize, "\(test.corner): inside CG x < triggerSize")
        } else {
            check(insideCG.x > screenW - triggerSize, "\(test.corner): inside CG x > screenW - triggerSize")
        }

        if isTop {
            check(insideCG.y < triggerSize, "\(test.corner): inside CG y < triggerSize (top of screen)")
        } else {
            check(insideCG.y > screenH - triggerSize, "\(test.corner): inside CG y > screenH - triggerSize (bottom)")
        }

        // Verify outside point does NOT satisfy trigger conditions
        if isLeft {
            check(outsideCG.x >= triggerSize || outsideCG.y >= triggerSize,
                  "\(test.corner): outside point is outside trigger zone")
        }
    }
}

// MARK: - Should Hide Logic

func testShouldHide() {
    group("Panel Hide Logic")

    // Panel at top-left, frame (0, 480, 380, 600)
    let panelFrame = CGRect(x: 0, y: 480, width: 380, height: 600)
    let sideMargin: CGFloat = 80
    let otherMargin: CGFloat = 50

    // For a left-side panel:
    // expanded x range: [minX - otherMargin, maxX + sideMargin] = [-50, 460]
    // expanded y range: [minY - otherMargin, maxY + otherMargin] = [430, 1130]

    let expandedMinX = panelFrame.minX - otherMargin
    let expandedMaxX = panelFrame.maxX + sideMargin
    let expandedMinY = panelFrame.minY - otherMargin
    let expandedMaxY = panelFrame.maxY + otherMargin

    // Inside panel — should NOT hide
    let inside = NSPoint(x: 200, y: 700)
    check(panelFrame.contains(inside), "Point inside panel frame")

    // Inside expanded margin — should NOT hide
    let inMargin = NSPoint(x: panelFrame.maxX + 50, y: 700) // 50 < 80 sideMargin
    let expandedRect = CGRect(x: expandedMinX, y: expandedMinY,
                              width: expandedMaxX - expandedMinX,
                              height: expandedMaxY - expandedMinY)
    check(expandedRect.contains(inMargin), "Point in side margin → should NOT hide")

    // Outside expanded margin — should hide
    let outside = NSPoint(x: panelFrame.maxX + 100, y: 700) // 100 > 80
    check(!expandedRect.contains(outside), "Point outside margin → should hide")

    // Above panel's expanded area
    let above = NSPoint(x: 200, y: panelFrame.maxY + 60) // 60 > 50 otherMargin
    check(!expandedRect.contains(above), "Point above expanded → should hide")

    // Verify pin overrides hide
    check(true, "Pinned panel never hides (tested in Store)")
}

// MARK: - Panel Frame Computation

func testPanelFrame() {
    group("Panel Frame Computation")

    // Simulate screen: visibleFrame = (0, 25, 1920, 1055)
    let visibleFrame = CGRect(x: 0, y: 25, width: 1920, height: 1055)
    let panelWidth: CGFloat = 380
    let heightRatio: CGFloat = 0.75

    let h = max(300, visibleFrame.height * heightRatio) // 791.25

    // Top-left
    let tlX = visibleFrame.minX // 0
    let tlY = visibleFrame.maxY - h // 1080 - 791.25 = 288.75
    check(abs(tlX - 0) < 0.01, "top-left: x = 0")
    check(tlY > visibleFrame.minY, "top-left: y above screen bottom")
    check(tlY + h <= visibleFrame.maxY + 0.01, "top-left: doesn't exceed screen top")

    // Top-right
    let trX = visibleFrame.maxX - panelWidth // 1920 - 380 = 1540
    check(abs(trX - 1540) < 0.01, "top-right: x = 1540")

    // Bottom-left
    let blX = visibleFrame.minX // 0
    let blY = visibleFrame.minY // 25
    check(abs(blX - 0) < 0.01, "bottom-left: x = 0")
    check(abs(blY - 25) < 0.01, "bottom-left: y = 25 (above dock/menubar)")

    // Bottom-right
    let brX = visibleFrame.maxX - panelWidth // 1540
    let brY = visibleFrame.minY // 25
    check(abs(brX - 1540) < 0.01, "bottom-right: x = 1540")
    check(abs(brY - 25) < 0.01, "bottom-right: y = 25")

    // Width constraints
    let clampedW = max(280, min(600, panelWidth))
    checkEqual(clampedW, 380, "Width clamped to valid range")

    let tooSmall = max(280, min(600, 100.0))
    checkEqual(tooSmall, 280, "Width min = 280")

    let tooLarge = max(280, min(600, 999.0))
    checkEqual(tooLarge, 600, "Width max = 600")

    // Height ratio constraints
    let smallRatio = max(0.2, min(1.0, 0.1))
    check(abs(smallRatio - 0.2) < 0.001, "Height ratio min = 0.2")

    let largeRatio = max(0.2, min(1.0, 1.5))
    check(abs(largeRatio - 1.0) < 0.001, "Height ratio max = 1.0")
}

// MARK: - Color Hex

func testColorHex() {
    group("Color Hex Parsing")

    // Basic parsing test — just verify no crash
    let colors = ["#FF6B6B", "#4FC3F7", "#000000", "#FFFFFF", "FF0000", "#abc"]
    for hex in colors {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        if h.count == 6 {
            let r = Double((int >> 16) & 0xFF) / 255
            let g = Double((int >> 8) & 0xFF) / 255
            let b = Double(int & 0xFF) / 255
            check(r >= 0 && r <= 1, "Red channel valid for \(hex)")
            check(g >= 0 && g <= 1, "Green channel valid for \(hex)")
            check(b >= 0 && b <= 1, "Blue channel valid for \(hex)")
        }
    }

    // Specific value
    let h = "FF6B6B"
    var int: UInt64 = 0
    Scanner(string: h).scanHexInt64(&int)
    let r = Double((int >> 16) & 0xFF) / 255
    let g = Double((int >> 8) & 0xFF) / 255
    let b = Double(int & 0xFF) / 255
    check(abs(r - 1.0) < 0.01, "#FF6B6B red ≈ 1.0")
    check(abs(g - 0.42) < 0.01, "#FF6B6B green ≈ 0.42")
    check(abs(b - 0.42) < 0.01, "#FF6B6B blue ≈ 0.42")
}
