//
//  LogFileManager.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//
import Foundation

class LogFileManager {
    private let logFileName = "crash_logs.json"
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "logfile.queue", attributes: .concurrent)

    private func getLogFileName() -> URL? {
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
//            print("Failed to get document directory")
            return nil
        }
        return documentDirectory.appendingPathComponent(logFileName)
    }
    
    func addLogs(logs: [String]) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self, let fileURL = self.getLogFileName() else { return }

            do {
                var existingLogs = self.getStoredLogs() ?? "[]"
                var logsArray = self.parseLogs(existingLogs)

                logsArray.append(contentsOf: logs)

                let jsonData = try JSONSerialization.data(withJSONObject: logsArray, options: .prettyPrinted)
                
                try jsonData.write(to: fileURL, options: .atomic)
            } catch {
//                print("Failed to write logs: \(error.localizedDescription)")
            }
        }
    }

    func getStoredLogs() -> String? {
        guard let fileURL = getLogFileName(), fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            if let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            } else {
                return nil
            }
    
        } catch {
//            print("Error reading logs: \(error.localizedDescription)")
            return nil
        }
    }
    

    private func parseLogs(_ logs: String) -> [String] {
        if let data = logs.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] {
            return json
        }
        return []
    }
    
    func getStoredLogsInArray() -> [String] {
        return self.parseLogs(self.getStoredLogs() ?? "")
    }

    func clearFile() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self, let fileURL = self.getLogFileName() else { return }
            do {
                if self.fileManager.fileExists(atPath: fileURL.path) {
                    try self.fileManager.removeItem(at: fileURL)
                }
            } catch {
//                print("Error clearing crash log file: \(error.description)")
            }
        }
    }
}
