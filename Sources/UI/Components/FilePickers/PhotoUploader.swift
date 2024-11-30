//
//  SwiftUIView.swift
//  
//
//  Created by Chocoford on 2023/4/13.
//

import SwiftUI
import PhotosUI
import CoreTransferable

struct ProfileImage: Transferable {
    let image: Image
    let data: Data
    
    enum TransferError: Error {
        case importFailed
    }
    
    @available(macOS 13.0, iOS 16.0, *)
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
        #if canImport(AppKit)
            guard let nsImage = NSImage(data: data) else {
                throw TransferError.importFailed
            }
            let image = Image(nsImage: nsImage)
            return ProfileImage(image: image, data: data)
        #elseif canImport(UIKit)
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            let image = Image(uiImage: uiImage)
            return ProfileImage(image: image, data: data)
        #else
            throw TransferError.importFailed
        #endif
        }
    }
}

public enum PhotoUploaderPhase: Equatable {
    public static func == (lhs: PhotoUploaderPhase, rhs: PhotoUploaderPhase) -> Bool {
        lhs.state == rhs.state
    }
    
    case empty
    case loading(Progress)
    case uploading(Image)
    case success(Image)
    case failure(Error)
    
    public enum State {
        case empty
        case loading
        case uploading
        case success
        case failure
    }
    
    public var state: State {
        switch self {
            case .empty:
                return .empty
            case .loading:
                return .loading
            case .uploading:
                return .uploading
            case .success:
                return .success
            case .failure:
                return .failure
        }
    }
    
    public var image: Image? {
        switch self {
            case .empty:
                return nil
            case .loading:
                return nil
            case .uploading(let image):
                return image
            case .success(let image):
                return image
            case .failure:
                return nil
        }
    }
}

public enum PhotoUploaderError: Error {
    case uploadingFailed(Error)
    case loadImageFailed
}

@available(macOS 13.0, iOS 16.0, *)
public struct PhotoUploader<V: View>: View {
    var content: (_ phase: PhotoUploaderPhase) -> V
    var config = Config()

//    public init(_ phase: Binding<PhotoUploaderPhase>, @ViewBuilder content: @escaping () -> V)  {
//        self.content = { _ in
//            content()
//        }
//    }
    
    public init(_ initialImage: URL? = nil,
                @ViewBuilder content: @escaping (_ phase: PhotoUploaderPhase) -> V) {
        
        self.content = content

        if let url = initialImage,
           let image = try? Image(data: .init(contentsOf: url)) {
            phase = .success(image)
        }
    }
    
//    public init<I: View, P: View>(@ViewBuilder content: @escaping (Image) -> I,
//                                   @ViewBuilder placeholder: @escaping () -> P) where V == _ConditionalContent<I, P> {
//        self.content = { phase in
//            if let image = phase.image {
//                content(image)
//            } else {
//                placeholder()
//            }
//        }
//    }
    
    @State private var phase: PhotoUploaderPhase = .empty
    
    @State private var showPhotosPicker = false
    @State private var showFileImporter = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedItems: [PhotosPickerItem] = []
    
    public var body: some View {
        Menu {
            if phase.state == .empty || phase.state == .failure  {
                Button {
                    showPhotosPicker.toggle()
                } label: {
                    Label("Chose from library", systemImage: "photo.stack")
                }
                Button {
                    showFileImporter.toggle()
                } label: {
                    Label("Choose from disk", systemImage: "opticaldiscdrive")
                }
            } else if case .loading(let progress) = phase {
                Button(role: .destructive) {
                    progress.cancel()
                    selectedItem = nil
                    phase = .empty
                } label: {
                    Label("cancel", systemImage: "xmark")
                }
            } else if case .uploading = phase {
                Button(role: .destructive) {
                    selectedItem = nil
                    phase = .empty
                } label: {
                    Label("cancel", systemImage: "xmark")
                }
            } else if phase.state == .success {
                Button {
                    showPhotosPicker.toggle()
                } label: {
                    Label("Chose from library", systemImage: "photo.stack")
                }
                Button {
                    showFileImporter.toggle()
                } label: {
                    Label("Choose from disk", systemImage: "opticaldiscdrive")
                }
                Button(role: .destructive) {
                    let backupItem = selectedItem
                    let backupPhase = phase
                    selectedItem = nil
                    phase = .empty
                    if let removeAction = config.removeAction {
                        Task {
                            do {
                                try await removeAction()
                            } catch {
                                selectedItem = backupItem
                                phase = backupPhase
                            }
                        }
                    }
                } label: {
                    Label("remove", systemImage: "trash")
                }
            }
        } label: {
            content(phase)
        }
        .buttonStyle(.plain)
        .labelStyle(.titleAndIcon)
        .menuIndicator(.hidden)
        .fixedSize()
        .photosPicker(isPresented: $showPhotosPicker,
                      selection: $selectedItem,
                      matching: .images,
                      preferredItemEncoding: .automatic,
                      photoLibrary: .shared())
        .onChange(of: selectedItem) { item in
            if let item = item {
                phase = .loading(loadTransferable(from: item))
            } else {
                phase = .empty
            }
        }
        .fileImporter(isPresented: $showFileImporter,
                      allowedContentTypes: [.image],
                      allowsMultipleSelection: false) { result in
            switch result {
                case .success(let success):
                    guard let url = success.first,
                            let data = try? Data(contentsOf: url) else {
                        phase = .failure(URLError.init(.badURL))
                        return
                    }
                    guard let image = Image(data: data) else {
                        phase = .failure(PhotoUploaderError.loadImageFailed)
                        return
                    }
                    if let uploadAction = config.uploadAction {
                        phase = .uploading(image)
                        Task {
                            do {
                                try await uploadAction(.init(data: data, filename: url.lastPathComponent))
                                phase = .success(image)
                            } catch {
                                phase = .failure(PhotoUploaderError.uploadingFailed(error))
                            }
                        }
                    } else {
                        phase = .success(image)
                    }

                    
                case .failure(let failure):
                    phase = .failure(failure)
            }
        }
    }
}

public struct PhotoUploaderImageFile {
    public var data: Data
    public var filename: String?
    public var fileExtension: String {
        filename?.components(separatedBy: ".").last ?? ""
    }
    
    init(data: Data, filename: String? = nil) {
        self.data = data
        self.filename = filename
    }
    
    init(data: Data, preferredFilenameExtension: String) {
        self.data = data
        self.filename = ".\(preferredFilenameExtension)"
    }
}

@available(macOS 13.0, iOS 16.0, *)
extension PhotoUploader {
    class Config: ObservableObject {
        var uploadAction: ((PhotoUploaderImageFile) async throws -> Void)? = nil
        var removeAction: (() async throws -> Void)? = nil
    }
    
    public func uploadProcess(callback: @escaping (PhotoUploaderImageFile) async throws -> Void) -> PhotoUploader {
        self.config.uploadAction = callback
        return self
    }
    
    public func onRemove(callback: @escaping () async throws -> Void) -> PhotoUploader {
        self.config.removeAction = callback
        return self
    }
}

@available(macOS 13.0, iOS 16.0, *)
private extension PhotoUploader {
    func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: ProfileImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.selectedItem else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                    case .success(let image?):
                        if let uploadAction = self.config.uploadAction {
                            self.phase = .uploading(image.image)
                            Task {
                                do {
                                    try await uploadAction(.init(data: image.data, preferredFilenameExtension: imageSelection.supportedContentTypes.first?.preferredFilenameExtension ?? ""))
                                    self.phase = .success(image.image)
                                } catch {
                                    self.phase = .failure(PhotoUploaderError.uploadingFailed(error))
                                }
                            }
                        } else {
                            self.phase = .success(image.image)
                        }
                    case .success(nil):
                        self.phase = .empty
                    case .failure(let error):
                        self.phase = .failure(error)
                }
            }
        }
    }
}

// MARK: - Wrapper
protocol PhotoUploaderStatusWrapperable: View {
    associatedtype Content
    var phase: PhotoUploaderPhase { get set }
    var content: (Image?) -> Content { get set }
}

extension PhotoUploaderStatusWrapperable {
    @ViewBuilder
    func defaultStatusWrapper<C: View>(phase: PhotoUploaderPhase,
                                       @ViewBuilder content: @escaping (Image?) -> C) -> some View {
        switch phase {
            case .empty:
                content(nil)
            case .loading(let progress):
                content(nil)
                    .overlay(
                        CircularProgressView()
                            .stroke(.accentColor)
                            .size(14)
                            .lineWidth(4)
                            .progress(progress.fractionCompleted),
                        alignment: .bottomTrailing)
            case .uploading(let image):
                content(image)
                    .overlay(
                        CircularProgressView()
                            .stroke(.accentColor)
                            .size(14)
                            .lineWidth(2),
                        alignment: .bottomTrailing)
            case .success(let image):
                content(image)
                
            case .failure(let error):
                content(nil)
                    .overlay(
                        Image(systemName: "exclamationmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 20)
                            .foregroundColor(.red)
                            .background(Color.white.clipShape(Circle()).padding(2))
                            .popover { _ in
                                VStack {
                                    Text(String(describing: error))
                                        .lineLimit(nil)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                            },
                        alignment: .bottomTrailing
                    )
        }
    }
}

public struct DefaultPhotoUploaderStatusWrapper<Content: View>: PhotoUploaderStatusWrapperable {
    var phase: PhotoUploaderPhase
    var content: (Image?) -> Content
    
    public init(phase: PhotoUploaderPhase, @ViewBuilder content: @escaping (Image?) -> Content) {
        self.phase = phase
        self.content = content
    }
    
    public var body: some View {
        defaultStatusWrapper(phase: phase, content: content)
    }
}

#if DEBUG
@available(macOS 13.0, iOS 16.0, *)
struct PhotoUploader_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            PhotoUploader { phase in
                DefaultPhotoUploaderStatusWrapper(phase: phase) { image in
                    if let image = image {
                        AvatarView {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                        .size(50)
                    } else {
                        AvatarView(urlString: nil, fallbackText: "T")
                            .size(50)
                    }
                }
            }
            .uploadProcess { imageFile in
                try await Task.sleep(for: .seconds(2))
            }
        }
        .frame(width: 500, height: 500)
        .previewLayout(.fixed(width: 500, height: 500))
    }
}
#endif
