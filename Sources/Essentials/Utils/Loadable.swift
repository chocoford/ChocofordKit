//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/9/14.
//

import Foundation

public enum LoadableError: Error, LocalizedError {
    case cancelled
    case notFound
    case parameterError
    case unexpected(error: Error)
    
    public var errorDescription: String? {
        switch self {
            case .cancelled:
                return "Canceled by user."
            case .notFound:
                return "Entity not found."
            case .parameterError:
                return "Parameter error."
            case .unexpected(let error):
                return error.localizedDescription
        }
    }
    
    init(_ error: Error) {
        if let error = error as? LoadableError {
            self = error
        } else {
            self = .unexpected(error: error)
        }
    }
}

public enum Loadable<T> {
    case notRequested
    case isLoading(last: T?) //, cancelBag: CancelBag
    case loaded(data: T)
    case failed(data: T?, error: LoadableError)

    public var value: T? {
        get {
            switch self {
                case let .loaded(value): return value
                case let .isLoading(last): return last
                case .failed(let last, _): return last
                default: return nil
            }
        }
        
        set {
            guard let newValue else { return }
            switch self {
                case .loaded(let value):
                    self = .loaded(data: newValue)
                case let .isLoading(last):
                    self = .isLoading(last: newValue)
                case .failed(let last, let error):
                    self = .failed(data: newValue, error: error)
                default:
                    return
            }
        }
    }
    public var error: LoadableError? {
        switch self {
        case let .failed(_, error): return error
            default: return nil
        }
    }
    
    public enum State {
        case notRequested
        case isLoading
        case loaded
        case failed
    }
    
    public var state: State {
        switch self {
            case .notRequested:
                return .notRequested
            case .isLoading:
                return .isLoading
            case .loaded:
                return .loaded
            case .failed:
                return .failed
        }
    }
}

public extension Loadable {
    mutating func setIsLoading() { //cancelBag: CancelBag
        self = .isLoading(last: value) //, cancelBag: cancelBag
    }
    
    mutating func setAsFailed(_ error: Error) {
        self = .failed(data: value, error: .init(error))
    }
    
    mutating func setAsLoaded(_ data: T) {
        self = .loaded(data: data)
    }
    
    mutating func setAsLoaded(_ transform: (inout T?) throws -> Void) {
        do {
            var value = self.value
            try transform(&value)
            guard let value = value else { throw LoadableError.notFound }
            self = .loaded(data: value)
        } catch {
            self = .failed(data: self.value, error: .init(error))
        }
    }
    
    mutating func transform(_ transform: (inout T) throws -> Void) {
        self = self.map {
            var el = $0
            try transform(&el)
            return el
        }
    }
    
    mutating func cancelLoading() {
        switch self {
            case let .isLoading(last): //, cancelBag
//                cancelBag.cancel()
                if let last = last {
                    self = .loaded(data: last)
                } else {
                    let error = NSError(
                        domain: NSCocoaErrorDomain, code: NSUserCancelledError,
                        userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Canceled by user",
                                                                                comment: "")])
                    self = .failed(data: nil, error: .unexpected(error: error))
                }
            default: break
        }
    }
    
    func map<V>(_ transform: (T) throws -> V) -> Loadable<V> {
        do {
            switch self {
                case .notRequested: return .notRequested
                case let .failed(data, error): return .failed(data: data != nil ? try transform(data!) : nil, error: error)
                case let .isLoading(value):
                    return .isLoading(last: try value.map { try transform($0) })
                case let .loaded(value):
                    return .loaded(data: try transform(value))
            }
        } catch {
            return .failed(data: nil, error: .unexpected(error: error))
        }
    }
}

extension Loadable: Equatable where T: Equatable {
    public static func == (lhs: Loadable<T>, rhs: Loadable<T>) -> Bool {
        switch (lhs, rhs) {
            case (.notRequested, .notRequested): return true
            case let (.isLoading(lhsV), .isLoading(rhsV)): return lhsV == rhsV
            case let (.loaded(lhsV), .loaded(rhsV)): return lhsV == rhsV
            case let (.failed(lhsData, lhsE), .failed(rhsData, rhsE)):
                return lhsData == rhsData && lhsE.localizedDescription == rhsE.localizedDescription
            default: return false
        }
    }
}


