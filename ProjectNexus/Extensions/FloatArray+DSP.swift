import Accelerate

extension Array where Element == Float {
    func rms() -> Float {
        guard !isEmpty else { return 0 }
        var result: Float = 0
        vDSP_measqv(self, 1, &result, vDSP_Length(count))
        return sqrtf(result)
    }

    func peak() -> Float {
        guard !isEmpty else { return 0 }
        var result: Float = 0
        vDSP_maxmgv(self, 1, &result, vDSP_Length(count))
        return result
    }

    func scaled(by factor: Float) -> [Float] {
        var result = [Float](repeating: 0, count: count)
        var f = factor
        vDSP_vsmul(self, 1, &f, &result, 1, vDSP_Length(count))
        return result
    }

    func added(to other: [Float]) -> [Float] {
        let n = min(count, other.count)
        var result = [Float](repeating: 0, count: n)
        vDSP_vadd(self, 1, other, 1, &result, 1, vDSP_Length(n))
        return result
    }

    func multiplied(by other: [Float]) -> [Float] {
        let n = min(count, other.count)
        var result = [Float](repeating: 0, count: n)
        vDSP_vmul(self, 1, other, 1, &result, 1, vDSP_Length(n))
        return result
    }

    func toDecibels(reference: Float = 1.0) -> [Float] {
        var ref = reference
        var result = [Float](repeating: 0, count: count)
        vDSP_vdbcon(self, 1, &ref, &result, 1, vDSP_Length(count), 1)
        return result
    }

    func hannWindowed() -> [Float] {
        var window = [Float](repeating: 0, count: count)
        vDSP_hann_window(&window, vDSP_Length(count), Int32(vDSP_HANN_NORM))
        return multiplied(by: window)
    }
}
