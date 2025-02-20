//
//  HyperLogManager.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//

import Foundation

final class HyperLogManager {
    private static var logsBatch: [Log] = []
    private static var publishableKey: String = ""
    private static var loggingEndPoint: String?
    private static let fileManager = LogFileManager()
    private static let queue = DispatchQueue(label: "hyperlog.queue")
    private static let debouncer = Debouncer(delayInMillis: 2000.0)
    
    private static func formatPayload(logs: [String]) -> String {
        return "[" + logs.joined(separator: ",")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "") + "]"
    }
    
    private static func getStringifiedLogs(_ logBatch: [Log]) -> [String] {
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
            Task {
                do {
                    let response = try await HyperNetworking.makeHttpRequest(
                        urlString: endpoint,
                        method: "POST",
                        headers: ["Content-Type": "application/json"],
                        body: payload)
                        if !response.isEmpty {
                            fileManager.clearFile()
                    }
                } catch {
                    print("Network error")
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
    
    static func saveLogsToFile(_ logsBatch: [Log]) {
        queue.async {
            let logs = getStringifiedLogs(logsBatch)
            fileManager.addLogs(logs: logs)
        }
    }
    
    static func addLog(_ log: Log) {
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
                copiedLogs[index].merchant_id = HyperLogManager.publishableKey
            }
            
            let logsToSend = getStringifiedLogs(copiedLogs)
        
            guard !logsToSend.isEmpty else { return }
            
            let payload = formatPayload(logs: logsToSend)
            
            Task {
                do {
                    let response = try await HyperNetworking.makeHttpRequest(
                        urlString: endpoint,
                        method: "POST",
                        headers: ["Content-Type": "application/json"],
                        body: payload)
                    
                    if response.isEmpty {
                        saveLogsToFile(copiedLogs)
                    }
                } catch {
                    saveLogsToFile(copiedLogs)
                }
            }
        } 
    }
}
