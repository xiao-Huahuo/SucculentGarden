// App与Widget共享木鱼进度；扩展自动迁移旧私有文件，文件锁防止跨进程点击丢失。
import Foundation
import OSLog
import Darwin

actor MuyuStore {
    static let shared = MuyuStore()

    private let suppliedURL: URL?
    private let suppliedLegacyURL: URL?
    private(set) var lastError: String?
    private let logger = Logger(subsystem: "local.littlecomponent.app.widget", category: "MuyuStore")

    init(fileURL: URL? = nil, legacyFileURL: URL? = nil) {
        suppliedURL = fileURL
        suppliedLegacyURL = legacyFileURL
    }

    func read() throws -> MuyuProgress {
        let url = try storageURL()
        return try withFileLock(at: url) { try readUnlocked(from: url) }
    }

    private func readUnlocked(from url: URL) throws -> MuyuProgress {
        guard FileManager.default.fileExists(atPath: url.path) else {
            let legacy = try legacyStorageURL()
            if let legacy, FileManager.default.fileExists(atPath: legacy.path) {
                let data = try Data(contentsOf: legacy)
                let progress = try decode(data)
                try data.write(to: url, options: .atomic)
                logger.info("木鱼旧进度已迁入共享目录，原文件保留")
                return progress
            }
            // 主应用不能先创建零进度，覆盖仍在扩展私有目录中的旧存档。
            guard suppliedURL != nil || Bundle.main.bundleIdentifier == "local.littlecomponent.app.widget" else {
                throw StorageError.notPrepared
            }
            let initial = MuyuProgress()
            try save(initial, to: url)
            return initial
        }
        return try decode(Data(contentsOf: url))
    }

    private func decode(_ data: Data) throws -> MuyuProgress {
        let progress = try JSONDecoder().decode(MuyuProgress.self, from: data)
        guard progress.version == 1,
              progress.merit >= 0,
              progress.fortune >= progress.merit,
              (progress.fortune / 3 < progress.merit ||
               (progress.fortune / 3 == progress.merit && progress.fortune % 3 == 0)) else {
            throw StorageError.invalidData
        }
        return progress
    }

    @discardableResult
    func tap(at date: Date = .now) throws -> MuyuProgress {
        let url = try storageURL()
        return try withFileLock(at: url) {
            var progress = try readUnlocked(from: url)
            guard progress.merit < Int.max, progress.fortune <= Int.max - 3 else {
                throw StorageError.limitReached
            }
            progress.merit += 1
            progress.fortune += Int.random(in: 1...3)
            progress.popupX = Double.random(in: -18...18)
            progress.popupY = (Bool.random() ? -49.0 : 49.0) + Double.random(in: -3...3)
            progress.lastTap = date
            try save(progress, to: url)
            lastError = nil
            logger.info("木鱼点击已保存")
            return progress
        }
    }

    func recordFailure(_ error: Error) {
        lastError = "保存失败，请重试"
        logger.error("木鱼球状态写入失败：\(error.localizedDescription, privacy: .public)")
    }

    private func storageURL() throws -> URL {
        if let suppliedURL { return suppliedURL }
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SucculentStore.groupID) else {
            throw StorageError.sharedContainerUnavailable
        }
        let directory = container.appendingPathComponent("Library/Application Support/MuyuBall", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("progress.json")
    }

    private func legacyStorageURL() throws -> URL? {
        if let suppliedLegacyURL { return suppliedLegacyURL }
        guard suppliedURL == nil, Bundle.main.bundleIdentifier == "local.littlecomponent.app.widget" else { return nil }
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = support.appendingPathComponent("MuyuBall", isDirectory: true)
        return directory.appendingPathComponent("progress.json")
    }

    private func withFileLock<T>(at url: URL, action: () throws -> T) throws -> T {
        let descriptor = open(url.appendingPathExtension("lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX) == 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
        defer { flock(descriptor, LOCK_UN) }
        return try action()
    }

    private func save(_ progress: MuyuProgress, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(progress).write(to: url, options: .atomic)
    }

    enum StorageError: LocalizedError {
        case invalidData
        case limitReached
        case notPrepared
        case sharedContainerUnavailable

        var errorDescription: String? {
            switch self {
            case .invalidData: "保存的数据无法读取，请保留原文件。"
            case .limitReached: "累计数值已达到可保存的上限。"
            case .notPrepared: "木鱼进度正在迁移，请稍后再试。"
            case .sharedContainerUnavailable: "无法访问共享木鱼进度，请检查应用签名。"
            }
        }
    }
}
