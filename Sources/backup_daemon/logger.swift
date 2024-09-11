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
    public var errorHandling: ErrorHandling
    private var files: Files
    private var art: Art
    
    init(files: Files = .sharedFiles) {
        self.files = files
        self.errorHandling = ErrorHandling()
        self.art = Art()
    }
    
    func getDateTime() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HH:mm:ss"
        return df.string(from: Date())
    }
    
    func strToData(_ input: [String]) -> Data {
        return input.joined(separator: " ").data(using: .utf8) ?? Data()
    }
    
    mutating func createLog() -> Void {
        do {
            try files.fileManager.createDirectory(at: files.logLocation.deletingLastPathComponent(), withIntermediateDirectories: true)
            if files.fileManager.createFile(atPath: files.logLocation.path, contents: strToData([])) {
                appendToLog(message: art.ascii)
            } else {
                throw ErrorHandling.FileErrors.failedToCreateLogfile
            }
        } catch {
            errorHandling.handleError(error, logger: self) // Does this create circular loops, if error occurs?
        }
    }
    
    /** Prints timestamped message to the logfine and to the system console. */
    mutating func appendToLog(message: String) -> Void {
        let message = "\(getDateTime()): \(message) \n"
        print("\n" + message)
        if let data = message.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
        do {
            let info = Data(strToData([message]))
            let fileHandler = try FileHandle(forWritingTo: files.logLocation)
            defer { fileHandler.closeFile() }
            try fileHandler.seekToEnd()
            fileHandler.write(info)
        } catch {
            errorHandling.handleError(error, logger: self)
        }
    }
}
