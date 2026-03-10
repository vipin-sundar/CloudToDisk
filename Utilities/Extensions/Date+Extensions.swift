//
//  Date+Extensions.swift
//  CloudToDisk
//
//  Extensions for Date
//

import Foundation

extension Date {
    var yearMonthPath: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: self)
        let month = calendar.component(.month, from: self)
        return String(format: "%04d/%02d", year, month)
    }

    var yearString: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: self)
        return String(format: "%04d", year)
    }

    var monthString: String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: self)
        return String(format: "%02d", month)
    }

    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}
