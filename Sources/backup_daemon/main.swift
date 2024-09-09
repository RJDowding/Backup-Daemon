//
//  main.swift
//  backup_daemon
//
//  Created by Reece Dowding on 06/07/2024.
//

/** TODO:
1. Should i tarball the backup? Would make it easier to compare hashes for vailidity
2. Maybe delete log after every startup, to have a fresh log, or find some way to make it clearer in logs different start ups.
3. Delete log after every start up.
4. Figure out how to overwrite timestamped files.
5. Bug in error 11. FileNoWritePermission.
6. Make better way of managing folder names for backup, centralised get name or set name or something.
 **/

import Foundation

struct Files {
    let fileManager = FileManager.default
    lazy var mcLocation: URL = { return URL(fileURLWithPath: "/data/minecraft/") } () // MC install to backup folder, point to it in docker.
    lazy var backupLocation: URL = { return URL(fileURLWithPath: "/data/backups/") } () // These two will point to the app data folder in the container.
    lazy var logLocation: URL = { return URL(fileURLWithPath: "/data/logs/backup_daemon.log") } ()
    lazy var VERSION: String = "1.0.6"
    
    static var sharedFiles = Files()
}

struct FileMgr {
    private var backupCount: Int = 1
    private var files: Files
    private var art: Art
    var logger: Logger
    
    init(files: Files = .sharedFiles) {
        self.files = files
        self.logger = Logger()
        self.art = Art()
        checkLogFile()
        self.logger.appendToLog(message:"Starting file manager.")
    }
    
    mutating func getVersion() -> String { return files.VERSION }
    
    // To implement
    func getFileTimestamp() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }
    
    mutating func checkLogFile() -> Void {
        do {
            if (files.fileManager.fileExists(atPath: files.logLocation.path)) {
                // Append to log.
                logger.appendToLog(message: art.ascii)
                logger.appendToLog(message: "Logfile found :)")
                try checkDirs()
            } else {
                // Create log.
                try logger.createLog()
                logger.appendToLog(message: art.ascii)
            }
        } catch {
            print(error.localizedDescription)
            logger.errorHandling.handleError(error)
        }
    }
    
    mutating func checkDirs() throws -> Void {
        // Check minecraft directories
        if (!files.fileManager.fileExists(atPath: files.mcLocation.path)) {
            throw ErrorHandling.FileErrors.mcDirNotFound
        } else if (!files.fileManager.fileExists(atPath: files.backupLocation.path)) {
            throw ErrorHandling.FileErrors.backupDirNotFound
        } else {
            logger.appendToLog(message: "Backup & minecraft server install found")
        }
    }
    
    mutating func copyOnData() -> Void { // Mutate to show the function can change the struct, which is a value type, bascially replacing the instance of a struct with a new instance when a change in the struct occurs. To ensure wherever changed the struct data has the correct up to date data.
        if (backupCount > 30) {
            backupCount = 1
        }
        do {
            // Check if the directory we're copying exists.
            if (files.fileManager.fileExists(atPath: files.backupLocation.path + "backup\(backupCount)")) {
                try files.fileManager.removeItem(atPath: files.backupLocation.path + "backup\(backupCount)")
                logger.appendToLog(message: "Backup deleted at \(files.backupLocation.path)backup/\(String(backupCount))")
            }
            
            let contents = try files.fileManager.contentsOfDirectory(atPath: files.mcLocation.path)
            guard !contents.isEmpty else {
                throw ErrorHandling.FileErrors.contentsOfDirectoryIsEmpty
            }
            
            try files.fileManager.copyItem(atPath: files.mcLocation.path, toPath: files.backupLocation.path + "/backup_\(backupCount)") // does this work for all files in a dir? YES.
            backupCount += 1
            logger.appendToLog(message: "Backup has been created.")
            
            try files.fileManager.createFile(atPath: files.mcLocation.path + "backup", contents: <#T##Data?#>)
            
            // Checking if backup has been made.
            if !files.fileManager.fileExists(atPath: files.backupLocation.path + "backup\(backupCount)") { // Throws error here as it doesnt account for logger.getDateTime, so doesn't think one exists.
                throw ErrorHandling.FileErrors.backupNotMade
            }
        } catch {
            logger.errorHandling.handleError(error)
        }
    }
}

var fileMgr = FileMgr()
fileMgr.logger.appendToLog(message: "Initialisation finished VERSION: \(fileMgr.getVersion())")

while (1 > 0) {
    Thread.sleep(forTimeInterval: (60*60))
    var currentDate = Date()
    let calendar = Calendar.current
    var components: DateComponents = calendar.dateComponents([.hour], from: currentDate)
    
    if (components.hour == 4) {
        fileMgr.logger.appendToLog(message: "In window, copying data.")
        fileMgr.copyOnData()
    }
}
