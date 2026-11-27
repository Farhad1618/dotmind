import Foundation

enum Grid {
    static let side = 8
    static let cells = 64
    static let center = 3.5
}

let tau = Double.pi * 2

@inline(__always)
func cell(_ x: Int, _ y: Int) -> Int {
    y * Grid.side + x
}

@inline(__always)
func clamp<Value: Comparable>(_ value: Value, _ lower: Value, _ upper: Value) -> Value {
    value < lower ? lower : (value > upper ? upper : value)
}

@inline(__always)
func roundHalfUp(_ value: Double) -> Int {
    Int(floor(value + 0.5))
}

@inline(__always)
func floorInt(_ value: Double) -> Int {
    Int(floor(value))
}

@inline(__always)
func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
    ((value % divisor) + divisor) % divisor
}

@inline(__always)
func wrapAngle(_ angle: Double) -> Double {
    (angle.truncatingRemainder(dividingBy: tau) + tau).truncatingRemainder(dividingBy: tau)
}

@inline(__always)
func dotHash(_ index: Int, _ seed: Double) -> Double {
    let x = sin(Double(index) * 127.1 + seed * 311.7) * 43758.5453
    return x - floor(x)
}

@inline(__always)
func fill(_ out: inout [Double], _ cells: [Int], _ value: Double) {
    for index in cells { out[index] = max(out[index], value) }
}

@inline(__always)
func clear(_ out: inout [Double]) {
    for index in 0..<Grid.cells { out[index] = 0 }
}

func trail(_ out: inout [Double], _ path: [Int], head: Double, length: Int, decay: Double) {
    let count = path.count
    let start = floorInt(head)
    for k in 0..<length {
        let index = path[positiveModulo(start - k, count)]
        let value = k == 0 ? 1.4 : pow(decay, Double(k)) * 1.05
        out[index] = max(out[index], value)
    }
}
