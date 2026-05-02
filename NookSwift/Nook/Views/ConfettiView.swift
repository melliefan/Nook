import SwiftUI

/// Natural firework burst at panel center — random angular distribution,
/// decelerating sparks with glowing tails and a brief central flash.
struct ConfettiBurst: View {
    let token: UUID?

    @State private var sparks: [Spark] = []
    @State private var startTime: Date = .distantPast
    @State private var cleanupItem: DispatchWorkItem?

    private let duration: TimeInterval = 1.3
    private let gravity: Double = 90        // gentle droop after expansion
    private let flashDuration: TimeInterval = 0.18
    private let tailDuration: TimeInterval = 0.11

    private static let palette: [Color] = [
        Color(red: 1.00, green: 0.42, blue: 0.42),  // #FF6B6B
        Color(red: 0.31, green: 0.76, blue: 0.97),  // #4FC3F7
        Color(red: 0.51, green: 0.78, blue: 0.52),  // #81C784
        Color(red: 1.00, green: 0.84, blue: 0.31),  // #FFD54F
        Color(red: 0.73, green: 0.41, blue: 0.78),  // #BA68C8
        Color(red: 1.00, green: 0.54, blue: 0.40),  // #FF8A65
        Color(red: 0.00, green: 0.40, blue: 1.00),  // #0066FF
    ]

    var body: some View {
        // GeometryReader locks the actual panel-sized frame as the source of truth.
        // Canvas's own `size` parameter is unreliable when TimelineView toggles
        // paused/unpaused or layout re-computes mid-render — that's why bursts started
        // shrinking. Use geo.size, never the Canvas size.
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0/60.0, paused: sparks.isEmpty)) { context in
                Canvas { ctx, _ in
                    guard !sparks.isEmpty else { return }
                    let elapsed = context.date.timeIntervalSince(startTime)
                    if elapsed >= duration { return }

                    let originX = geo.size.width * 0.5
                    let originY = geo.size.height * 0.5

                // Initial bright flash at burst center
                if elapsed < flashDuration {
                    let p = elapsed / flashDuration
                    let radius = 5 + p * 22
                    let flashAlpha = (1 - p) * 0.9
                    let rect = CGRect(x: originX - radius, y: originY - radius,
                                      width: radius * 2, height: radius * 2)
                    ctx.fill(Path(ellipseIn: rect),
                             with: .color(.white.opacity(flashAlpha)))
                }

                for s in sparks {
                    let lifeProgress = min(1.0, elapsed / s.life)
                    if lifeProgress >= 1.0 { continue }

                    // Decelerating spark — distance integral of (1 - progress) over life.
                    let head = position(s, t: elapsed, ox: originX, oy: originY)
                    let tail = position(s, t: max(0, elapsed - tailDuration),
                                        ox: originX, oy: originY)

                    // Fade: hold full for first half, ease out over second half + slight twinkle.
                    let baseAlpha: Double
                    if lifeProgress < 0.4 {
                        baseAlpha = 1.0
                    } else {
                        let t = (lifeProgress - 0.4) / 0.6
                        baseAlpha = max(0, 1 - t * t)   // ease-out quad
                    }
                    let twinkle = 0.85 + 0.15 * sin(elapsed * 28 + s.twinklePhase)
                    let alpha = baseAlpha * twinkle

                    // Glow tail — colored, semi-transparent
                    var line = Path()
                    line.move(to: tail)
                    line.addLine(to: head)
                    ctx.stroke(line,
                               with: .color(s.color.opacity(alpha * 0.55)),
                               style: StrokeStyle(lineWidth: 2.6, lineCap: .round))

                    // Inner colored core along the streak
                    ctx.stroke(line,
                               with: .color(s.color.opacity(alpha)),
                               style: StrokeStyle(lineWidth: 1.2, lineCap: .round))

                    // White-hot leading tip
                    let tipR: CGFloat = 1.6
                    let tipRect = CGRect(x: head.x - tipR, y: head.y - tipR,
                                         width: tipR * 2, height: tipR * 2)
                    ctx.fill(Path(ellipseIn: tipRect),
                             with: .color(.white.opacity(min(1.0, alpha + 0.15))))
                }
            }
        }
        }
        .allowsHitTesting(false)
        .onChange(of: token) { _, _ in
            startBurst()
        }
    }

    /// Decelerating motion: speed falls off linearly with progress, plus light gravity.
    private func position(_ s: Spark, t: TimeInterval, ox: CGFloat, oy: CGFloat) -> CGPoint {
        let p = min(1.0, t / s.life)
        // Distance traveled = v0 * life * (p - p²/2)
        let dist = s.speed * s.life * (p - 0.5 * p * p)
        let dx = dist * cos(s.angle)
        let dy = dist * sin(s.angle) + 0.5 * gravity * t * t
        return CGPoint(x: ox + dx, y: oy + dy)
    }

    private func startBurst() {
        guard token != nil else { return }
        startTime = Date()
        sparks = (0..<Self.sparkCount).map { i in
            Spark.deterministic(index: i, total: Self.sparkCount, palette: Self.palette)
        }
        // Cancel any pending cleanup from a previous burst — otherwise it fires mid-way
        // through this new burst and clears `sparks` early, killing the animation.
        cleanupItem?.cancel()
        let item = DispatchWorkItem { sparks = [] }
        cleanupItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1, execute: item)
    }

    private static let sparkCount = 90

    fileprivate struct Spark {
        var angle: Double
        var speed: Double
        var life: TimeInterval
        var color: Color
        var twinklePhase: Double

        /// All values derived from `index` — every burst renders identically.
        /// Uses sin/cos with prime-ish multipliers as deterministic "noise": the angles,
        /// speeds, and lifetimes drift in a way that looks organic but is 100% reproducible.
        static func deterministic(index: Int, total: Int, palette: [Color]) -> Spark {
            let i = Double(index)

            // Even spread + sine-based angular jitter (~±7°) so rays don't sit on a perfect grid.
            let baseAngle = i / Double(total) * 2 * .pi
            let angleJitter = sin(i * 2.7 + 1.3) * 0.12
            let angle = baseAngle + angleJitter

            // Speed: most sparks ~230 pts/s, some "stragglers" up to ~310 / down to ~150
            // — gives the natural ring-with-flares look.
            let speed = 230 + sin(i * 1.9 + 0.4) * 70 + cos(i * 0.7) * 12

            // Lifetime varies ±0.12s so sparks don't all die at the same instant.
            let life = 1.0 + sin(i * 3.1 + 0.7) * 0.12

            let color = palette[index % palette.count]
            let twinklePhase = i * 0.41
            return Spark(angle: angle, speed: speed, life: life, color: color, twinklePhase: twinklePhase)
        }
    }
}
