//
//  error.swift
//  backup_daemon
//
//  Created by Reece Dowding on 27/08/2024.
//
import Foundation

struct ErrorHandling {
    
    enum FileErrors: Error {
        case mcDirNotFound
        case failedToCreateLogfile
        case failedToMakeLogfileDir
        case backupDirNotFound
        case failedToBackupFiles
        case unableToDeleteBackup
        case contentsOfDirectoryIsEmpty
        case failedToAppendToLogfile
        case fileNotFound
        case fileNoPermission
        case fileWriteNoPermission
        case backupNotMade
        case unknown // Getting unknown error when files cant be found, folder x doesnt exist.
    }
    
    func printStackTrace() -> String {
        return Thread.callStackSymbols.joined(separator: "\n")
    }
    
    /** Manages errors by matching error types defined in enum. Matched errors set a message to print to the log & console, where the system will also exit the program with a specific code. Inputs a error of type error, and a logger instance. */
    func handleError(_ error: Error, logger: Logger) -> Void {
        var message: String
        let exitCode: Int32
        var logger: Logger = logger

        switch error {
            case FileErrors.mcDirNotFound:
                message = "MC directory not found! \(error.localizedDescription)"
                exitCode = -5
                
            case FileErrors.failedToCreateLogfile:
                message = "Cannot make logfile: \(error.localizedDescription)"
                exitCode = 10
                
            case FileErrors.failedToMakeLogfileDir:
                message = "Cannot make directory for logfile: \(error.localizedDescription)"
                exitCode = 15
                
            case FileErrors.backupDirNotFound:
                message = "Cannot locate backup directory: \(error.localizedDescription)"
                exitCode = 20
                
            case FileErrors.failedToBackupFiles:
                message = "Failed to copy files for backup: \(error.localizedDescription)"
                exitCode = 25
                
            case FileErrors.unableToDeleteBackup:
                message = "A backup exists, that cannot be overwritten: \(error.localizedDescription)"
                exitCode = 30
                
            case FileErrors.contentsOfDirectoryIsEmpty:
                message = "The contents of the MC dir is empty: \(error.localizedDescription)"
                exitCode = 35
                
            case FileErrors.backupNotMade:
                message = "Backup not made: \(error.localizedDescription)"
                exitCode = 101
                
            case let error as CocoaError where error.code == .fileNoSuchFile:
                message = "Some file cant be found \(error.localizedDescription)"
                exitCode = 36
                
            case let error as CocoaError where error.code == .fileReadNoPermission:
                message = "Dont have permission to access file"
                exitCode = 37
                
            case let error as CocoaError where error.code == .fileWriteNoPermission:
                message = "No permissions to write to file"
                exitCode = 38
                
            default:
                message = "An unknown error occured \(error.localizedDescription)"
                exitCode = 69
        }
        
        logger.appendToLog(message: "\(message) \n \(printStackTrace())")
        exit(exitCode)
    }
}
