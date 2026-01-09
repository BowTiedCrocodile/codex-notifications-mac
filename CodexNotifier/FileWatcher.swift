import Foundation

public final class FileWatcher {
    private let url: URL
    private let handler: () -> Void
    private var fileDescriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?

    public init(url: URL, handler: @escaping () -> Void) {
        self.url = url
        self.handler = handler
    }

    public func start() {
        guard source == nil else { return }
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.main
        )

        source.setEventHandler(handler: handler)
        source.setCancelHandler { [weak self] in
            if let descriptor = self?.fileDescriptor, descriptor >= 0 {
                close(descriptor)
                self?.fileDescriptor = -1
            }
        }
        self.source = source
        source.resume()
    }

    deinit {
        source?.cancel()
    }
}
