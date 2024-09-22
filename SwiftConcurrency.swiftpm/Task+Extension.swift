//
//  Task+Extension.swift
//  SwiftConcurrency
//
//  Created by Alejandro Aliaga on 21/9/24.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
