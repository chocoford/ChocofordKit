//
//  TextAreaTrigger.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 2026/05/06.
//

import SwiftUI

// MARK: - Token

/// An atomic, styled inline unit inside a `TextArea`.
///
/// Conforming types define their own visual representation via `body` and
/// a plain-text fallback via `plainText`. Identity is provided through
/// `Identifiable.id`; two tokens with the same id are considered equal.
public protocol TextAreaToken: Identifiable {
    associatedtype Body: View

    /// Plain-text representation used for clipboard, programmatic reading,
    /// or fallback rendering.
    var plainText: String { get }

    /// SwiftUI view rendered inline in the editor for this token.
    @ViewBuilder var body: Body { get }
}

/// Type-erased `TextAreaToken` for storage in heterogeneous collections.
public struct AnyTextAreaToken: Identifiable, Hashable {
    public let id: AnyHashable
    public let plainText: String
    public let body: AnyView

    public init<T: TextAreaToken>(_ token: T) {
        self.id = AnyHashable(token.id)
        self.plainText = token.plainText
        self.body = AnyView(token.body)
    }

    public static func == (lhs: AnyTextAreaToken, rhs: AnyTextAreaToken) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Element

/// A single piece of `TextArea` content — either a run of text or a token.
public enum TextAreaElement: Hashable {
    case text(String)
    case token(AnyTextAreaToken)
}

extension Array where Element == TextAreaElement {
    /// Flatten the elements into plain text. Tokens contribute their
    /// `plainText` representation.
    public var plainText: String {
        map { el in
            switch el {
            case .text(let s): return s
            case .token(let t): return t.plainText
            }
        }
        .joined()
    }

    /// All tokens in order of appearance.
    public var tokens: [AnyTextAreaToken] {
        compactMap {
            if case .token(let t) = $0 { return t }
            return nil
        }
    }
}

// MARK: - Insertion

/// What happens to the editor (and the menu) when the user picks an item.
public enum TextAreaInsertion {
    /// Replace `[trigger..caret]` with plain text.
    case text(String)
    /// Replace `[trigger..caret]` with a styled atomic token.
    case token(AnyTextAreaToken)
    /// Remove `[trigger..caret]` and run an action (slash-command pattern).
    case action(() -> Void)
    /// Replace the current menu with another one (submenu / drill-down).
    /// The trigger range stays in the editor; user can keep typing to filter.
    case submenu(AnyTextAreaMenuSource)
    /// Close the menu, leave the editor untouched.
    case dismiss
}

extension TextAreaInsertion {
    /// Convenience for wrapping a concrete `TextAreaToken` value.
    public static func token<T: TextAreaToken>(_ token: T) -> TextAreaInsertion {
        .token(AnyTextAreaToken(token))
    }

    /// Convenience for wrapping a concrete `TextAreaMenuSource` value.
    public static func submenu<M: TextAreaMenuSource>(_ menu: M) -> TextAreaInsertion {
        .submenu(AnyTextAreaMenuSource(menu))
    }
}

// MARK: - MenuSource (protocol)

/// A source of menu items — produces items for a query, knows how to render
/// each row, and decides what happens when one is selected.
///
/// This protocol is shared between top-level triggers and submenus. A submenu
/// is just a `TextAreaMenuSource` returned from another menu source's `resolve`.
public protocol TextAreaMenuSource {
    associatedtype Item: Identifiable
    associatedtype Row: View

    /// Search items based on the query string.
    func search(_ query: String) async -> [Item]

    /// Build the view for a single menu row.
    @ViewBuilder func row(_ item: Item, isSelected: Bool) -> Row

    /// Decide what happens when the user picks an item.
    func resolve(_ item: Item) -> TextAreaInsertion
}

// MARK: - Trigger protocol

/// A `TextAreaMenuSource` activated by a specific character typed in the editor.
///
/// Conforming types only add the trigger `character` on top of the menu-source
/// contract.
public protocol TextAreaTrigger: TextAreaMenuSource {
    /// The character that activates the menu (e.g. `"@"`, `"/"`).
    var character: Character { get }
}

// MARK: - TextAreaMenu (default closure-based MenuSource)

/// Default `TextAreaMenuSource` built from closures. Use to construct
/// submenus inline:
///
///     .submenu(TextAreaMenu(
///         search: { ... },
///         resolve: { ... }
///     ) { item, selected in ... })
public struct TextAreaMenu<Item: Identifiable, Row: View>: TextAreaMenuSource {
    private let _search: (String) async -> [Item]
    private let _row: (Item, Bool) -> Row
    private let _resolve: (Item) -> TextAreaInsertion

    public init(
        search: @escaping (String) async -> [Item],
        resolve: @escaping (Item) -> TextAreaInsertion,
        @ViewBuilder row: @escaping (Item, _ isSelected: Bool) -> Row
    ) {
        self._search = search
        self._row = row
        self._resolve = resolve
    }

    public func search(_ query: String) async -> [Item] {
        await _search(query)
    }

    public func row(_ item: Item, isSelected: Bool) -> Row {
        _row(item, isSelected)
    }

    public func resolve(_ item: Item) -> TextAreaInsertion {
        _resolve(item)
    }
}

// MARK: - MenuTrigger (default closure-based Trigger)

/// Default `TextAreaTrigger` built from closures.
/// Covers the common case; conform to `TextAreaTrigger` directly for
/// custom needs.
public struct MenuTrigger<Item: Identifiable, Row: View>: TextAreaTrigger {
    public let character: Character
    private let _search: (String) async -> [Item]
    private let _row: (Item, Bool) -> Row
    private let _resolve: (Item) -> TextAreaInsertion

    public init(
        _ character: Character,
        search: @escaping (String) async -> [Item],
        resolve: @escaping (Item) -> TextAreaInsertion,
        @ViewBuilder row: @escaping (Item, _ isSelected: Bool) -> Row
    ) {
        self.character = character
        self._search = search
        self._row = row
        self._resolve = resolve
    }

    public func search(_ query: String) async -> [Item] {
        await _search(query)
    }

    public func row(_ item: Item, isSelected: Bool) -> Row {
        _row(item, isSelected)
    }

    public func resolve(_ item: Item) -> TextAreaInsertion {
        _resolve(item)
    }
}

// MARK: - Type-erased menu source

/// Type-erased `TextAreaMenuSource` used internally to store menus and
/// submenus behind a uniform interface.
public struct AnyTextAreaMenuSource {
    private let _search: (String) async -> [Resolved]

    /// A menu item resolved to its row builder and selection action.
    public struct Resolved: Identifiable {
        public let id: AnyHashable
        private let _row: (Bool) -> AnyView
        private let _resolve: () -> TextAreaInsertion

        init(
            id: AnyHashable,
            row: @escaping (Bool) -> AnyView,
            resolve: @escaping () -> TextAreaInsertion
        ) {
            self.id = id
            self._row = row
            self._resolve = resolve
        }

        public func row(isSelected: Bool) -> AnyView {
            _row(isSelected)
        }

        public func resolve() -> TextAreaInsertion {
            _resolve()
        }
    }

    public init<M: TextAreaMenuSource>(_ menu: M) {
        self._search = { query in
            let items = await menu.search(query)
            return items.map { item in
                Resolved(
                    id: AnyHashable(item.id),
                    row: { selected in AnyView(menu.row(item, isSelected: selected)) },
                    resolve: { menu.resolve(item) }
                )
            }
        }
    }

    public func search(_ query: String) async -> [Resolved] {
        await _search(query)
    }
}

// MARK: - Type-erased trigger

/// Type-erased `TextAreaTrigger` used by the component to store an arbitrary
/// number of triggers behind a uniform interface.
public struct AnyTextAreaTrigger {
    public let character: Character
    public let menu: AnyTextAreaMenuSource

    /// `Resolved` is shared with `AnyTextAreaMenuSource`.
    public typealias Resolved = AnyTextAreaMenuSource.Resolved

    public init<T: TextAreaTrigger>(_ trigger: T) {
        self.character = trigger.character
        self.menu = AnyTextAreaMenuSource(trigger)
    }

    public func search(_ query: String) async -> [Resolved] {
        await menu.search(query)
    }
}
