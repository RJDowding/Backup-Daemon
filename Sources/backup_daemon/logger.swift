//
//  logger.swift
//  
//
//  Created by Reece Dowding on 29/08/2024.
//
import Foundation

protocol Logging {
    func getDateTime() -> String
    func strToData(_ input: [String]) -> Data
    mutating func createLog() throws -> Void
    mutating func appendToLog(message: String) -> Void
}

struct Logger: Logging {
    private var files: Files
    var errorHandling: ErrorHandling
    
    init(files: Files = .sharedFiles) {
        self.files = files
        self.errorHandling = ErrorHandling()
    }
    
    func getDateTime() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HH:mm:ss"
        return df.string(from: Date())
    }
    
    func strToData(_ input: [String]) -> Data {
        return input.joined(separator: " ").data(using: .utf8) ?? Data() // Genius...
    }
    
    mutating func createLog() throws -> Void {
        try files.fileManager.createDirectory(at: files.logLocation.deletingLastPathComponent(), withIntermediateDirectories: true)
        if files.fileManager.createFile(atPath: files.logLocation.path, contents: strToData([getDateTime(), "Creating log! \n"])) {
            appendToLog(message: "Made logfile in " + files.logLocation.path)
            return
        } else {
            throw ErrorHandling.FileErrors.failedToCreateLogfile
        }
    }
    
    mutating func appendToLog(message: String) -> Void {
        print("\n" + message)
        if let data = message.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
        do {
            let info = Data(strToData([getDateTime(), message + "\n"]))
            let fileHandler = try FileHandle(forWritingTo: files.logLocation)
            defer { fileHandler.closeFile() }
            try fileHandler.seekToEnd()
            fileHandler.write(info)
        } catch {
            errorHandling.handleError(error, logger: self)
        }
    }
}
