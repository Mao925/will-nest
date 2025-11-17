import Vapor

// Decode helpers that accept numeric strings and doubles where the client might send them.
extension KeyedDecodingContainer {
    func decodeFlexibleInt(forKey key: Key, min: Int? = nil) throws -> Int {
        if let intValue = try? decode(Int.self, forKey: key) {
            if let min, intValue < min {
                throw Abort(.badRequest, reason: "\(key.stringValue) must be >= \(min)")
            }
            return intValue
        }
        if let doubleValue = try? decode(Double.self, forKey: key) {
            let intValue = Int(doubleValue)
            if let min, intValue < min {
                throw Abort(.badRequest, reason: "\(key.stringValue) must be >= \(min)")
            }
            return intValue
        }
        if let stringValue = try? decode(String.self, forKey: key), let intValue = Int(stringValue) {
            if let min, intValue < min {
                throw Abort(.badRequest, reason: "\(key.stringValue) must be >= \(min)")
            }
            return intValue
        }
        throw Abort(.badRequest, reason: "\(key.stringValue) must be a number")
    }

    func decodeIfPresentFlexibleInt(forKey key: Key, min: Int? = nil) throws -> Int? {
        guard contains(key) else { return nil }
        return try decodeFlexibleInt(forKey: key, min: min)
    }

    func decodeFlexibleDouble(forKey key: Key, min: Double? = nil) throws -> Double {
        if let doubleValue = try? decode(Double.self, forKey: key) {
            if let min, doubleValue < min {
                throw Abort(.badRequest, reason: "\(key.stringValue) must be >= \(min)")
            }
            return doubleValue
        }
        if let intValue = try? decode(Int.self, forKey: key) {
            if let min, Double(intValue) < min {
                throw Abort(.badRequest, reason: "\(key.stringValue) must be >= \(min)")
            }
            return Double(intValue)
        }
        if let stringValue = try? decode(String.self, forKey: key), let doubleValue = Double(stringValue) {
            if let min, doubleValue < min {
                throw Abort(.badRequest, reason: "\(key.stringValue) must be >= \(min)")
            }
            return doubleValue
        }
        throw Abort(.badRequest, reason: "\(key.stringValue) must be a number")
    }
}
