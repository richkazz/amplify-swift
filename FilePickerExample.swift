
import UIKit
import UniformTypeIdentifiers
import PhotosUI

// This UIViewController demonstrates how to pick files and media from the user's device.
class FilePickerViewController: UIViewController {

    // MARK: - UI Elements

    private lazy var pickFileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Pick a File", for: .normal)
        button.addTarget(self, action: #selector(pickFileButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var pickMediaButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Pick Media (Photo/Video)", for: .normal)
        button.addTarget(self, action: #selector(pickMediaButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var resultLabel: UILabel = {
        let label = UILabel()
        label.text = "No file selected"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        let stackView = UIStackView(arrangedSubviews: [pickFileButton, pickMediaButton, resultLabel])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    // MARK: - Actions

    /// Presents the UIDocumentPickerViewController to pick a document.
    @objc private func pickFileButtonTapped() {
        // For iOS 14+, UTType is preferred. For older versions, you'd use kUTType... strings.
        let supportedTypes: [UTType] = [
            .item, // Represents a generic base type for most things
            .content,
            .data,
            .directory,
            .resolvable,
            .symbolicLink,
            .executable,
            .mountPoint,
            .aliasFile,
            .urlBookmarkData,
            .url,
            .fileURL,
            .text,
            .plainText,
            .utf8PlainText,
            .utf16ExternalPlainText,
            .utf16PlainText,
            .rtf,
            .html,
            .xml,
            .yaml,
            .sourceCode,
            .assemblyLanguageSource,
            .cSource,
            .objectiveCSource,
            .swiftSource,
            .cPlusPlusSource,
            .objectiveCPlusPlusSource,
            .cHeader,
            .cPlusPlusHeader,
            .image,
            .jpeg,
            .tiff,
            .gif,
            .png,
            .icns,
            .bmp,
            .ico,
            .rawImage,
            .svg,
            .livePhoto,
            .audiovisualContent,
            .movie,
            .video,
            .audio,
            .quickTimeMovie,
            .mpeg,
            .mpeg4Movie,
            .mp3,
            .mpeg4Audio,
            .wav,
            .aiff,
            .archive,
            .gzip,
            .bz2,
            .zip,
            .appleArchive,
            .spreadsheet,
            .commaSeparatedText,
            .tabSeparatedText,
            .stylesheet,
            .presentation,
            .pdf,
            .vCard,
            .toDoItem,
            .calendarEvent,
            .emailMessage,
            .internetLocation,
            .internetShortcut,
            .font,
            .bookmark,
            .pkcs12,
            .x509Certificate,
            .epub,
            .log,
        ]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false // Change to true to allow multiple files
        present(documentPicker, animated: true, completion: nil)
    }

    /// Presents the PHPickerViewController for media selection.
    @objc private func pickMediaButtonTapped() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1 // 0 means no limit
        configuration.filter = .any(of: [.images, .videos]) // You can filter for just images or videos

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
}

// MARK: - UIDocumentPickerDelegate

extension FilePickerViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            resultLabel.text = "No URL found for selected document."
            return
        }

        // IMPORTANT: The document picker provides a temporary, secure URL.
        // To access the file persistently, you must move it to a permanent location in your app's sandbox.
        // For large files, you can use `startAccessingSecurityScopedResource()` to read the file directly
        // without moving it. This is crucial for performance and memory management.

        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Now you have the URL, you can pass it to the ChunkingManager
        // For example:
        // let chunkingManager = ChunkingManager(fileURL: url)
        // chunkingManager.getNextChunk(...)

        resultLabel.text = "Picked file: \(url.lastPathComponent)"
        print("Selected file URL: \(url)")
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        resultLabel.text = "File picking was cancelled."
        print("Document picker was cancelled.")
    }
}

// MARK: - PHPickerViewControllerDelegate

extension FilePickerViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)

        guard let result = results.first else {
            resultLabel.text = "No media was selected."
            return
        }

        let itemProvider = result.itemProvider

        // Request the file URL for the picked asset
        // This is an asynchronous operation
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                self?.handlePickedURL(url, error: error)
            }
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] url, error in
                self?.handlePickedURL(url, error: error)
            }
        } else {
             DispatchQueue.main.async {
                self.resultLabel.text = "Unsupported media type."
            }
        }
    }

    private func handlePickedURL(_ url: URL?, error: Error?) {
        if let error = error {
            print("Error getting file URL: \(error)")
            DispatchQueue.main.async {
                self.resultLabel.text = "Error picking media."
            }
            return
        }

        guard let url = url else {
            DispatchQueue.main.async {
                self.resultLabel.text = "Could not retrieve URL for media."
            }
            return
        }

        // IMPORTANT: The PHPicker also provides a temporary URL.
        // You should copy the file to your app's directory for persistent access.
        // For large files, you can read from this URL directly before it's gone.

        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)

        do {
            // If a file already exists, remove it.
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            // Copy the file to the temporary directory.
            try FileManager.default.copyItem(at: url, to: destinationURL)

            DispatchQueue.main.async {
                self.resultLabel.text = "Picked media: \(destinationURL.lastPathComponent)"
                print("Selected media URL (copied to temp): \(destinationURL)")
            }

            // Now you can use `destinationURL` with the ChunkingManager
        } catch {
            print("Error copying file: \(error)")
            DispatchQueue.main.async {
                 self.resultLabel.text = "Error processing media."
            }
        }
    }
}
