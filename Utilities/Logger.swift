//
//  Logger.swift
//  CloudToDisk
//
//  Logging utility using OSLog
//

import Foundation
import os.log

class Logger {
    static let shared = Logger()

    private let log: OSLog

    private init() {
        log = OSLog(subsystem: "com.cloudtodisk.app", category: "general")
    }

    func info(_ message: String) {
        os_log("%{public}@", log: log, type: .info, message)
    }

    func debug(_ message: String) {
        os_log("%{public}@", log: log, type: .debug, message)
    }

    func error(_ message: String) {
        os_log("%{public}@", log: log, type: .error, message)
    }

    func fault(_ message: String) {
        os_log("%{public}@", log: log, type: .fault, message)
    }
}
