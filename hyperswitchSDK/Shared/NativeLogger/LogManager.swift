//
//  HyperLogManager.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//

import Foundation

final class LogManager {
    private static var logsBatch: [LogPayload] = []
    private static var publishableKey: String = ""
    private static var loggingEndPoint: String?
    private static let fileManager = LogFileManager()
    private static let queue = DispatchQueue(label: "hyperlog.queue")
    private static let debouncer = Debouncer(delayInMillis: 2000.0)
    
    private static func formatPayload(logs: [String]) -> String {
        return "[" + logs.joined(separator: ",")
            .replacingOccurrences(of: "\n", with: " ") + "]"
    }
    
    private static func getStringifiedLogs(_ logBatch: [LogPayload]) -> [String] {
        return logBatch.compactMap { $0.toJson() }
    }
    
    static func initialize(publishableKey: String) {
        queue.async {
            self.publishableKey = publishableKey
            self.loggingEndPoint = SDKEnvironment.loggingURL(for: publishableKey)
        }
        if !publishableKey.isEmpty {
            sendLogsFromFile()
        }
    }
    
    static func sendLogsFromFile() {
        queue.async {
            guard let endpoint = loggingEndPoint else { return }
            let logs = fileManager.getStoredLogsInArray()
            let payload = formatPayload(logs: logs)
            
            let data = payload.data(using: .utf8)
            
            let logRequest = HTTPRequestService(host: endpoint, path: "", endpoint: "", method: .post)
            logRequest.headers = ["Content-Type": "application/json"]
            logRequest.bodyData = data
            
            logRequest.request(type: Data.self) { (result, statusCode) in
                switch (result, statusCode) {
                case (.success(_), 200..<300):
                    fileManager.clearFile()
                default:
                    break;
                }
            }
        }
    }
    
    static func saveLogsToFile() {
        queue.async {
            let logs = getStringifiedLogs(logsBatch)
            fileManager.addLogs(logs: logs)
        }
    }
    
    static func saveLogsToFile(_ logsBatch: [LogPayload]) {
        queue.async {
            let logs = getStringifiedLogs(logsBatch)
            fileManager.addLogs(logs: logs)
        }
    }
    
    static func addLog(_ log: LogPayload) {
        queue.async {
            logsBatch.append(log)
            debouncer.debounce {
                sendLogsOverNetwork()
            }
        }
    }
    
    private static func sendLogsOverNetwork() {
        queue.async {
            guard !logsBatch.isEmpty, let endpoint = loggingEndPoint else { return }
            var copiedLogs = logsBatch
            logsBatch.removeAll()
            
            for index in copiedLogs.indices {
                copiedLogs[index].merchant_id = LogManager.publishableKey
            }
            
            let logsToSend = getStringifiedLogs(copiedLogs)
            guard !logsToSend.isEmpty else { return }
            
            let payload = formatPayload(logs: logsToSend)
            let data = payload.data(using: .utf8)
            let logRequest = HTTPRequestService(host: endpoint, path: "", endpoint: "", method: .post)
            
            logRequest.headers = ["Content-Type": "application/json"]
            logRequest.bodyData = data
            logRequest.request(type: Data.self) { (result, statusCode) in
                switch (result, statusCode) {
                case (.success(_), 200..<300):
                    break;
                default:
                    saveLogsToFile(copiedLogs)
                }
            }
        }
    }
}
