//
//  HyperLogManager.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//

import Foundation

final class HyperLogManager {
    private static let debounceTimeInMillis = 10000.0
    private static var logsBatch: [Log] = []
    private static var publishableKey: String = ""
    private static var loggingEndPoint: String?
    private static let fileManager: LogFileManager = LogFileManager()
    private static let queue = DispatchQueue(label: "hyperlog.queue", attributes: .concurrent)
    private static let debouncer = Debouncer(delayInMillis: debounceTimeInMillis)
    
    static func sendLogsFromFile() {
        queue.async{
            guard let endpoint = loggingEndPoint else { return }
            let logs = fileManager.getStoredLogsInArray()
            let payload = "[" + logs.joined(separator: ",")
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "\n", with: "") + "]"
            Task {
                do {
                    let response = try await HyperNetworking.makePostRequest(endpoint, payload)
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
        let logs = getStringifiedLogs(logBatch : logsBatch)
        DispatchQueue.global(qos: .background).async {
            fileManager.addLogs(logs: logs)
        }
    }
    
    static func saveLogsToFile(_ logs: [Log]) {
        let logs = getStringifiedLogs(logBatch: logs)
        DispatchQueue.global(qos: .background).async {
            fileManager.addLogs(logs: logs)
        }
    }
    
    static func initialise(publishableKey: String) {
        self.publishableKey = publishableKey
        let env = SDKEnvironment.checkEnvironment(publishableKey: publishableKey)
        loggingEndPoint = (env == .PROD) ? "https://api.hyperswitch.io/logs/sdk" : "https://sandbox.hyperswitch.io/logs/sdk"
        if !publishableKey.isEmpty {
            sendLogsFromFile()
        }
    }
    
    static func addLog(_ log: Log) {
        logsBatch.append(log)
        debouncer.debounce {
            sendLogsOverNetwork()
        }
    }
    
    private static func getStringifiedLogs(logBatch: [Log]) -> [String] {
        return logBatch.compactMap { $0.toJson() }
    }
    
    
    private static func sendLogsOverNetwork() {
        guard !logsBatch.isEmpty, let endpoint = loggingEndPoint else { return }
        var copiedLogs = logsBatch
        logsBatch.removeAll()
        
        for index in copiedLogs.indices {
            copiedLogs[index].merchant_id = self.publishableKey
        }
        
        let logsToSend = getStringifiedLogs(logBatch: copiedLogs)
        
        guard !logsToSend.isEmpty else { return }
        
        let payload = "[" + logsToSend.joined(separator: ",")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "") + "]"
        
        Task {
            do {
                let response = try await HyperNetworking.makePostRequest(endpoint, payload)
                if response.isEmpty {
                    saveLogsToFile(copiedLogs)
                }
            } catch {
                saveLogsToFile(copiedLogs)
            }
        }
    }
}
