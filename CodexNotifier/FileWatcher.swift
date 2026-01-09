import Foundation

public final class FileWatcher {
    private let url: URL
    private let handler: () -> Void
    private let errorHandler: ((String) -> Void)?
    private var fileDescriptor: CInt = -1
    private var fileHandle: FileHandle?
    private var source: DispatchSourceFileSystemObject?

    public init(url: URL, handler: @escaping () -> Void, errorHandler: ((String) -> Void)? = nil) {
        self.url = url
        self.handler = handler
        self.errorHandler = errorHandler
    }

    public func start() {
        guard source == nil else { return }
        do {
            let handle = try FileHandle(forReadingFrom: url)
            fileHandle = handle
            fileDescriptor = handle.fileDescriptor
        } catch {
            errorHandler?("FileWatcher failed to open \(url.path): \(error.localizedDescription)")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.main
        )

        source.setEventHandler(handler: handler)
        source.setCancelHandler { [weak self] in
            if let handle = self?.fileHandle {
                try? handle.close()
                self?.fileHandle = nil
            }
            self?.fileDescriptor = -1
        }
        self.source = source
        source.resume()
    }

    deinit {
        source?.cancel()
    }
}
