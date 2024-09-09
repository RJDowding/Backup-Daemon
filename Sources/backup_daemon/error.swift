//
//  error.swift
//  backup_daemon
//
//  Created by Reece Dowding on 27/08/2024.
//
import Foundation

struct ErrorHandling {
    
    func printStackTrace() -> String {
        return Thread.callStackSymbols.joined(separator: "\n")
    }
    
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
    
    // Should maybe make all error related stuff in own file, singleton paradigm if so.
    func handleError(_ error: Error, logger: Logger) -> Void {
        var message: String
        let exitCode: UInt8
        let logger: Logger

        switch error {
        case FileErrors.mcDirNotFound:
            message = "MC directory not found! \(error.localizedDescription)"
            exitCode = 5
            
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
            
        case FileErrors.failedToAppendToLogfile:
            return // Not thrown anywhere
            // One of these might possible be cyclic. Causing issues with writing to log, but also being raised trying to write to log.
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
            // If logger fails to write to log it will default to this, should consider writing own case
        }
        
        logger.appendToLog(message: "\(message) \n \(printStackTrace())")
        exit(Int32(exitCode))
    }
}
