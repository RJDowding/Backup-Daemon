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
 7. Where do we print to docker console?
 8. Where are our timestamps for printing?
 **/

import Foundation

struct Files {
    let fileManager = FileManager.default
    lazy var mcLocation: URL = { return URL(fileURLWithPath: "/data/minecraft/") } () // MC install to backup folder, point to it in docker.
    lazy var backupLocation: URL = { return URL(fileURLWithPath: "/data/backups/") } () // These two will point to the app data folder in the container.
    lazy var logLocation: URL = { return URL(fileURLWithPath: "/data/logs/backup_daemon.log") } ()
    lazy var VERSION: String = "1.0.7"
    
    static var sharedFiles = Files()
}

struct FileMgr {
    public var logger: Logger
    private var backupCount: Int = 1
    private var files: Files
    mutating func getVersion() -> String { return files.VERSION }
    
    init(files: Files = .sharedFiles) {
        self.files = files
        self.logger = Logger()
        logger.createLog()
        self.checkDirectories()
    }
    
    // To implement
    func getFileTimestamp() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }
    
    func compareDates(_ dates: [String]) -> [String] {
        var dates = dates
        for (index, date) in dates.enumerated() {
            if dates.endIndex >= index + 1 && date > dates[index + 1] {
                dates.swapAt(index, index + 1)
            } else if dates[dates.endIndex] < dates[dates.startIndex] {
                dates.swapAt(dates.endIndex, dates.startIndex)
            }
        }
        return dates
    }
        
    // Checking directories if install & backup location exists.
    mutating func checkDirectories() -> Void {
        do {
            guard files.fileManager.fileExists(atPath: files.mcLocation.path) else {
                throw ErrorHandling.FileErrors.mcDirNotFound
            }
            guard files.fileManager.fileExists(atPath: files.backupLocation.path) else {
                throw ErrorHandling.FileErrors.backupDirNotFound
            }
            
            logger.appendToLog(message: "Backup & minecraft server install found")
            // Count the amount of backups located in the backup folder.
            let backupsExisting: Int = try files.fileManager.contentsOfDirectory(at: files.backupLocation, includingPropertiesForKeys: []).count
            backupCount = max(1, backupsExisting)
            
        } catch {
            logger.errorHandling.handleError(error, logger: self.logger)
        }
    }
    
    mutating func copyOnData() -> Void { // Mutate to show the function can change the struct, which is a value type, bascially replacing the instance of a struct with a new instance when a change in the struct occurs. To ensure wherever changed the struct data has the correct up to date data.
        if (backupCount > 30) {backupCount = 1}
        let fullPath: String = files.backupLocation.appendingPathComponent("backup\(backupCount)").path()
        
        do {
            // Check if the directory we're copying exists.
            if (files.fileManager.fileExists(atPath: fullPath)) {
                try files.fileManager.removeItem(atPath: fullPath)
                logger.appendToLog(message: "Backup deleted at: \(fullPath)")
            }
            
            let contents = try files.fileManager.contentsOfDirectory(atPath: files.mcLocation.path)
            guard !contents.isEmpty else {
                throw ErrorHandling.FileErrors.contentsOfDirectoryIsEmpty
            }
            
            try files.fileManager.copyItem(atPath: files.mcLocation.path, toPath: files.backupLocation.path + "/backup_\(backupCount)") // does this work for all files in a dir? YES.
            backupCount += 1
            logger.appendToLog(message: "Backup has been created.")
            
            // Checking if backup has been made.
            guard files.fileManager.fileExists(atPath: files.backupLocation.path + "backup\(backupCount)") else { // Throws error here as it doesnt account for logger.getDateTime, so doesn't think one exists.
                throw ErrorHandling.FileErrors.backupNotMade
            }
            
        } catch {
            ErrorHandling().handleError(error, logger: self.logger)
        }
    }
}

var dates = ["2024-05-24", "2002-09-12", "2024-05-26"]

func compareDates(_ dates: [String]) -> [String] {
    var dates = dates
    for (index, date) in dates.enumerated() {
        print(dates.endIndex, dates.startIndex)
        if dates.endIndex - 1 >= index + 1 {
            if date > dates[index + 1] {
            dates.swapAt(index, index + 1)
            }
        } else if dates[dates.endIndex - 1] > dates[dates.startIndex] { // Issue with index on this line. End index starts count from 1 not 0. Start index starts from 0.
            dates.swapAt(dates.endIndex - 1, dates.startIndex)
        }
    }
    return dates
}

print(compareDates(dates))

print(FileMgr().compareDates(["2024-05-26", "2024-05-24", "2002-09-12"]))
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
