//
//  DirectoryMonitor.swift
//
//
//  Created by Dove Zachary on 2023/12/11.
//
#if canImport(AppKit)
import Foundation
import AppKit

import ChocofordEssentials

public class DirectoryMonitor: NSObject, NSFilePresenter {
    public lazy var presentedItemOperationQueue = OperationQueue.main
    public var presentedItemURL: URL?
 
    public enum Event {
        case subitemDidAppear(_ directoryURL: URL, _ url: URL)
        case subitemDidChange(_ directoryURL: URL, _ url: URL)
        case subitemDidLose(_ directoryURL: URL, _ url: URL, _ version: NSFileVersion?)
    }
    
    private var eventsQueue: EventsQueue = EventsQueue()
    
    public init(url: URL, onEvents: @escaping (Event) async -> Void) {
        self.presentedItemURL = url
        super.init()
        self.start()
        Task {
            for await event in self.eventsQueue {
                await onEvents(event)
            }
        }
    }
    
    deinit {
        self.stop()
    }
    
    public func stop() {
        NSFileCoordinator.removeFilePresenter(self)
    }
    
    public func start() {
        if NSFileCoordinator.filePresenters.contains(where: {$0.presentedItemURL == self.presentedItemURL}) {
            return
        }
        print("start observe direcotry: \(self.presentedItemURL?.filePath ?? "")")
        NSFileCoordinator.addFilePresenter(self)
    }
    
    public func presentedSubitemDidAppear(at url: URL) {
        guard let directoryURL = self.presentedItemURL else { return }
        self.eventsQueue.elements.append(.subitemDidAppear(directoryURL, url))
    }
    
    public func presentedSubitemDidChange(at url: URL) {
        guard let directoryURL = self.presentedItemURL else { return }
        if let _ = try? FileManager.default.attributesOfItem(atPath: url.filePath) {
            self.eventsQueue.elements.append(.subitemDidChange(directoryURL, url))

        } else {
            self.eventsQueue.elements.append(.subitemDidLose(directoryURL, url, nil))
        }
    }
    
    public func presentedSubitem(at url: URL, didLose version: NSFileVersion) {
        guard let directoryURL = self.presentedItemURL else { return }
        self.eventsQueue.elements.append(.subitemDidLose(directoryURL, url, version))
    }
}


extension DirectoryMonitor {
    public typealias EventHandler = (Event) async -> Void
    
    public class EventsQueue: AsyncSequence, AsyncIteratorProtocol {
        var elements: [Element]
        
        init() {
            self.elements = []
        }
        
        public typealias Element = Event
        
        public func makeAsyncIterator() -> EventsQueue {
            self
        }
        
        public func next() async -> Element? {
            while true {
                do {
                    if elements.isEmpty {
                        try await Task.sleep(nanoseconds: 2 * UInt64(1e+9))
//                        print("[DirectoryMonitor] sleep: \(Date.now.formatted())")
                    } else {
                        break
                    }
                } catch {
                    print(error)
                }
            }
            
            let element = elements.removeFirst()
            
            return element
        }
        
    }
}
#endif
