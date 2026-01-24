import Foundation

class ChunkingManager {
    let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Reads a chunk of data from the file at a given offset and length.
    ///
    /// - Parameters:
    ///   - offset: The position in the file to start reading from.
    ///   - length: The number of bytes to read.
    ///   - completionHandler: A closure to call with the result.
    func getNextChunk(offset: UInt64, length: UInt64, completionHandler: @escaping (Result<Data, Error>) -> Void) {
        DispatchQueue.global().async {
            do {
                let fileHandle = try FileHandle(forReadingFrom: self.fileURL)
                defer {
                    try? fileHandle.close()
                }

                try fileHandle.seek(toOffset: offset)
                let data = try fileHandle.read(bytes: length)
                completionHandler(.success(data ?? Data()))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
}
