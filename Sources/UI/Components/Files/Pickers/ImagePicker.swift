//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/6/21.
//

import SwiftUI
import PhotosUI
import ChocofordEssentials
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public struct ImageItem: Transferable {
#if os(iOS)
    public typealias Image = UIImage
#elseif os(macOS)
    public typealias Image = NSImage
#endif
    public var swiftUIImage: SwiftUI.Image?
    public var image: Image?
    public var data: Data
    public var name: String?
    public var `extension`: String
    

    init(swiftUIImage: SwiftUI.Image, image: Image, data: Data, name: String?, `extension`: String) {
        self.swiftUIImage = swiftUIImage
        self.image = image
        self.data = data
        self.`extension` = `extension`
    }
    
    init(data: Data, name: String?, extension: String?) {
        self.swiftUIImage = SwiftUI.Image(data: data)
        self.image = Image(data: data)
        self.data = data
        self.name = name
        self.`extension` = `extension` ?? data.fileExtension
    }
    
    enum TransferError: Error {
        case importFailed
    }
    
    @available(macOS 13.0, iOS 16.0, *)
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
        #if canImport(AppKit)
            guard let nsImage = NSImage(data: data) else {
                throw TransferError.importFailed
            }
            let image = SwiftUI.Image(nsImage: nsImage)
            return ImageItem(swiftUIImage: image, image: nsImage, data: data,
                             name: nil,
                             extension: data.fileExtension)
        #elseif canImport(UIKit)
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            let image = SwiftUI.Image(uiImage: uiImage)
            return ImageItem(swiftUIImage: image, image: uiImage, data: data,
                             name: nil, extension: data.fileExtension)
        #else
            throw TransferError.importFailed
        #endif
        }
    }
}

public enum ImagePickerPhase: Equatable {
    public static func == (lhs: ImagePickerPhase, rhs: ImagePickerPhase) -> Bool {
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

/// `ImagePicker` doesn't hold the image. It just transfer the image users picked.
@available(macOS 13.0, iOS 16.0, *)
public struct ImagePicker<L: View>: View {
#if os(iOS)
    public typealias Image = UIImage
#elseif os(macOS)
    public typealias Image = NSImage
#endif
    var label: () -> L
    
    var progress: Binding<Progress>?
    var multiple: Bool
    
    public init(progress: Binding<Progress>? = nil, multiple: Bool = false, @ViewBuilder label: @escaping ()-> L) {
        self.progress = progress
        self.multiple = multiple
        self.label = label
    }
    
    var config: Config = .init()
    
//    @State private var phase: ImagePickerPhase = .empty
    @State private var showPhotosPicker = false
    @State private var showFileImporter = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedItems: [PhotosPickerItem] = []

    public var body: some View {
        Menu {
            sourceMenuItems()
                .labelStyle(.titleAndIcon)
        } label: {
            label()
        }
        .if(multiple) { content in
            content
                .photosPicker(isPresented: $showPhotosPicker,
                              selection: $selectedItems,
                              matching: .images,
                              preferredItemEncoding: .automatic)
                .onChange(of: selectedItems) { items in
                    guard !items.isEmpty else { return }
                    self.loadTransferables(from: items)
                    selectedItems = []
                }
        } falseTransform: { content in
            content
                .photosPicker(isPresented: $showPhotosPicker,
                              selection: $selectedItem,
                              matching: .images,
                              preferredItemEncoding: .automatic)
                .onChange(of: selectedItem) { item in
                    guard let item = item else { return }
                    self.progress?.wrappedValue = loadTransferable(from: item)
                    selectedItem = nil
                }
        }
        .fileImporter(isPresented: $showFileImporter,
                      allowedContentTypes: [.image],
                      allowsMultipleSelection: multiple) { result in
            switch result {
                case .success(let success):
                    let images: [ImageItem] = success.compactMap { url in
                        if let data = try? Data(contentsOf: url) {
                            return .init(data: data, name: url.lastPathComponent, extension: url.pathExtension)
                        } else {
                            return nil
                        }
                    }
                    DispatchQueue.main.async { config.onPickImages?(images) }
                    
                    
                case .failure(let failure):
                    config.onError?(failure)
            }
        }
    }
    
    @ViewBuilder
    private func sourceMenuItems() -> some View {
        Group {
            Button {
                showPhotosPicker.toggle()
            } label: {
                Label("Choose from library", systemImage: "photo.stack")
            }
            Button {
                showFileImporter.toggle()
            } label: {
                Label("Choose from disk", systemImage: "opticaldiscdrive")
            }
        }
    }
    
    func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: ImageItem.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.selectedItem else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                    case .success(let imageItem?):
                        DispatchQueue.main.async { config.onPickImages?([imageItem]) }
                    case .success(nil):
                        break
                    case .failure(let error):
                        config.onError?(error)
                }
            }
        }
    }
    
    func loadTransferables(from imagesSelection: [PhotosPickerItem]) {
        Task {
            do {
                var images: [ImageItem] = []
                for imageSelection in imagesSelection {
                    let result = try await imageSelection.loadTransferable(type: ImageItem.self)
                    if let imageItem = result {
                        images.append(imageItem)
                    }
                }
                DispatchQueue.main.async { [images] in self.config.onPickImages?(images) }
            } catch {
                self.config.onError?(error)
            }
        }
    }
}

//MARK: - Config
@available(macOS 13.0, iOS 16.0, *)
extension ImagePicker {
    class Config: ObservableObject {
        var onPickImages: (([ImageItem]) -> Void)? = nil
        var onError: ((Error) -> Void)? = nil
        
        var customMenuItems: [ImagePickerPhase.State : () -> any View] = [:]
    }
    
    public func onPickImages(_ callback: @escaping (_ images: [ImageItem]) -> Void) -> ImagePicker {
        self.config.onPickImages = callback
        return self
    }
    
    public func onError(_ callback: @escaping (_ error: Error) -> Void) -> ImagePicker {
        self.config.onError = callback
        return self
    }
    
    func customMenuItems<Content: View>(for phase: ImagePickerPhase.State,
                                        @ViewBuilder content: @escaping () -> Content) -> ImagePicker {
        return self
    }
}
