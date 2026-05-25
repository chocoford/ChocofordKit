//
//  TextAreaMenu.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 2026/05/06.
//

import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

// MARK: - State

public struct TextAreaMenuState {
    public var trigger: AnyTextAreaTrigger
    public var triggerLocation: Int        // utf16 offset of the trigger character
    public var queryStartLocation: Int     // utf16 offset where the current menu's query begins
    public var query: String
    public var menu: AnyTextAreaMenuSource // current menu source (root trigger or a submenu)
    public var items: [AnyTextAreaMenuSource.Resolved]
    public var selectedIndex: Int
    public var anchorRect: CGRect          // rect (top-left coords) used to position the menu UI
}

// MARK: - Controller

@MainActor
final class TextAreaController: ObservableObject {
    @Published var menuState: TextAreaMenuState?

    var triggers: [Character: AnyTextAreaTrigger] = [:]
    var pasteHandler: ((TextAreaPasteItem) -> TextAreaInsertion?)?
    var isProgrammaticEdit: Bool = false

#if canImport(AppKit)
    weak var textView: AutoGrowNSTextView?
#endif

    private var searchTaskID = UUID()

    // MARK: Detection

    func detectAfterTextChange() {
#if canImport(AppKit)
        guard !isProgrammaticEdit, let textView else { return }
        let str = textView.string
        let nsStr = str as NSString
        let caret = textView.selectedRange().location
        guard caret <= nsStr.length else { return }

        if let state = menuState {
            updateExistingMenu(state: state, nsStr: nsStr, caret: caret, textView: textView)
        } else {
            scanForTrigger(nsStr: nsStr, caret: caret, textView: textView)
        }
#endif
    }

#if canImport(AppKit)
    private func updateExistingMenu(
        state: TextAreaMenuState,
        nsStr: NSString,
        caret: Int,
        textView: AutoGrowNSTextView
    ) {
        guard caret >= state.queryStartLocation else {
            menuState = nil
            return
        }
        let length = caret - state.queryStartLocation
        guard state.queryStartLocation + length <= nsStr.length else {
            menuState = nil
            return
        }
        let query = nsStr.substring(
            with: NSRange(location: state.queryStartLocation, length: length)
        )
        if query.contains(where: { $0.isWhitespace || $0.isNewline }) {
            menuState = nil
            return
        }
        var newState = state
        newState.anchorRect = textView.menuAnchorRect(forUTF16Offset: state.triggerLocation)
        guard query != state.query else {
            menuState = newState
            return
        }
        newState.query = query
        menuState = newState
        runSearch()
    }

    private func scanForTrigger(
        nsStr: NSString,
        caret: Int,
        textView: AutoGrowNSTextView
    ) {
        guard caret > 0, !triggers.isEmpty else { return }
        var i = caret - 1
        while i >= 0 {
            let unit = nsStr.character(at: i)
            guard let scalar = Unicode.Scalar(unit) else { return }
            let ch = Character(scalar)
            if ch.isWhitespace || ch.isNewline { return }
            if let trigger = triggers[ch] {
                let isAtBoundary: Bool = {
                    if i == 0 { return true }
                    let prevUnit = nsStr.character(at: i - 1)
                    guard let prevScalar = Unicode.Scalar(prevUnit) else { return false }
                    let prevCh = Character(prevScalar)
                    return prevCh.isWhitespace || prevCh.isNewline
                }()
                guard isAtBoundary else { return }

                let triggerLoc = i
                let queryStart = i + 1
                let query = nsStr.substring(
                    with: NSRange(location: queryStart, length: caret - queryStart)
                )
                let state = TextAreaMenuState(
                    trigger: trigger,
                    triggerLocation: triggerLoc,
                    queryStartLocation: queryStart,
                    query: query,
                    menu: trigger.menu,
                    items: [],
                    selectedIndex: 0,
                    anchorRect: textView.menuAnchorRect(forUTF16Offset: triggerLoc)
                )
                menuState = state
                runSearch()
                return
            }
            i -= 1
        }
    }
#endif

    // MARK: Search

    private func runSearch() {
        guard let state = menuState else { return }
        let id = UUID()
        searchTaskID = id
        let menu = state.menu
        let query = state.query
        Task { [weak self] in
            let items = await menu.search(query)
            await MainActor.run {
                guard let self, self.searchTaskID == id, var current = self.menuState else { return }
                current.items = items
                current.selectedIndex = min(current.selectedIndex, max(0, items.count - 1))
                self.menuState = current
            }
        }
    }

    // MARK: Navigation

    func selectNext() {
        guard var state = menuState, !state.items.isEmpty else { return }
        state.selectedIndex = min(state.items.count - 1, state.selectedIndex + 1)
        menuState = state
    }

    func selectPrevious() {
        guard var state = menuState, !state.items.isEmpty else { return }
        state.selectedIndex = max(0, state.selectedIndex - 1)
        menuState = state
    }

    func commitSelection() {
        guard let state = menuState,
              state.items.indices.contains(state.selectedIndex) else { return }
        applyInsertion(state.items[state.selectedIndex].resolve())
    }

    func dismiss() {
        menuState = nil
    }

    /// Programmatically insert `character` at the current caret and open its
    /// trigger menu (if registered). Boundary checks are skipped — the menu
    /// opens regardless of surrounding whitespace.
    func programmaticOpenTrigger(_ character: Character) {
#if canImport(AppKit)
        guard let textView else { return }
        let caret = textView.selectedRange().location
        let charStr = String(character)
        let insertRange = NSRange(location: caret, length: 0)

        // Insert mimicking user typing, but suppress auto-detection so we
        // don't run boundary-check logic on this character.
        guard textView.shouldChangeText(in: insertRange, replacementString: charStr) else { return }
        isProgrammaticEdit = true
        textView.textStorage?.replaceCharacters(in: insertRange, with: charStr)
        textView.didChangeText()
        isProgrammaticEdit = false

        guard let trigger = triggers[character] else { return }

        let triggerLoc = caret
        let queryStart = caret + 1
        let state = TextAreaMenuState(
            trigger: trigger,
            triggerLocation: triggerLoc,
            queryStartLocation: queryStart,
            query: "",
            menu: trigger.menu,
            items: [],
            selectedIndex: 0,
            anchorRect: textView.menuAnchorRect(forUTF16Offset: triggerLoc)
        )
        menuState = state
        runSearch()
#endif
    }

    // MARK: Insertion

    func applyInsertion(_ insertion: TextAreaInsertion) {
#if canImport(AppKit)
        guard let textView, let state = menuState else {
            if case .action(let perform) = insertion { perform() }
            return
        }
        let caret = textView.selectedRange().location
        let range = NSRange(
            location: state.triggerLocation,
            length: max(0, caret - state.triggerLocation)
        )

        switch insertion {
        case .text(let str):
            replace(range: range, with: str, in: textView)
            menuState = nil
        case .token(let token):
            replaceWithAttachment(range: range, token: token, in: textView)
            menuState = nil
        case .action(let perform):
            replace(range: range, with: "", in: textView)
            menuState = nil
            perform()
        case .submenu(let menuSource):
            var newState = state
            newState.menu = menuSource
            newState.queryStartLocation = textView.selectedRange().location
            newState.query = ""
            newState.items = []
            newState.selectedIndex = 0
            menuState = newState
            runSearch()
        case .dismiss:
            menuState = nil
        }
#endif
    }

    // MARK: Paste

    /// Handle a sequence of pasteboard items: ask the user's `pasteHandler`
    /// for each, fall back to default for `nil` (text inserted, others ignored).
    /// Returns `true` if any item was handled (caller should suppress system paste).
    @discardableResult
    func handlePaste(_ items: [TextAreaPasteItem]) -> Bool {
#if canImport(AppKit)
        guard let textView else { return false }
        var handledAny = false
        for item in items {
            let result = pasteHandler?(item)
            if let result {
                handledAny = true
                applyAtCaret(result, in: textView)
            } else {
                // Default: text inserts, others ignored
                if case .text(let s) = item {
                    handledAny = true
                    insertText(s, in: textView)
                }
            }
        }
        return handledAny
#else
        return false
#endif
    }

#if canImport(AppKit)
    private func applyAtCaret(
        _ insertion: TextAreaInsertion,
        in textView: AutoGrowNSTextView
    ) {
        let caret = textView.selectedRange()
        switch insertion {
        case .text(let s):
            replace(range: caret, with: s, in: textView)
        case .token(let token):
            replaceWithAttachment(range: caret, token: token, in: textView)
        case .action(let perform):
            perform()
        case .submenu, .dismiss:
            break
        }
    }

    private func insertText(_ s: String, in textView: AutoGrowNSTextView) {
        replace(range: textView.selectedRange(), with: s, in: textView)
    }

    private func replace(range: NSRange, with string: String, in textView: NSTextView) {
        guard textView.shouldChangeText(in: range, replacementString: string) else { return }
        isProgrammaticEdit = true
        textView.textStorage?.replaceCharacters(in: range, with: string)
        textView.didChangeText()
        isProgrammaticEdit = false
    }

    private func replaceWithAttachment(
        range: NSRange,
        token: AnyTextAreaToken,
        in textView: NSTextView
    ) {
        let font = textView.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let attrStr = makeTokenAttributedString(token: token, font: font)
        guard textView.shouldChangeText(in: range, replacementString: attrStr.string) else { return }
        isProgrammaticEdit = true
        textView.textStorage?.replaceCharacters(in: range, with: attrStr)
        textView.didChangeText()
        isProgrammaticEdit = false
    }
#endif
}

// MARK: - Menu UI

struct TextAreaMenuView: View {
    let state: TextAreaMenuState
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(state.items.enumerated()), id: \.element.id) { index, item in
                item.row(isSelected: index == state.selectedIndex)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        index == state.selectedIndex
                            ? Color.accentColor.opacity(0.15)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 4)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(index) }
            }
        }
        .padding(4)
        .frame(minWidth: 180, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6).strokeBorder(.separator)
        }
        .shadow(radius: 8, y: 4)
    }
}

// MARK: - AppKit anchor rect

#if canImport(AppKit)
extension AutoGrowNSTextView {
    /// Rect at the given UTF-16 offset, expressed in the enclosing scroll
    /// view's SwiftUI-friendly coordinate space (top-left origin).
    ///
    /// Uses `firstRect(forCharacterRange:)` so the same code path works on
    /// both TextKit 1 and TextKit 2.
    func menuAnchorRect(forUTF16Offset offset: Int) -> CGRect {
        guard let scrollView = enclosingScrollView,
              let window else { return .zero }
        let screenRect = firstRect(
            forCharacterRange: NSRange(location: offset, length: 1),
            actualRange: nil
        )
        guard !screenRect.isEmpty else { return .zero }
        let windowRect = window.convertFromScreen(screenRect)
        let inScroll = scrollView.convert(windowRect, from: nil)
        // SwiftUI overlay anchors top-left; NSScrollView coords are bottom-left.
        let mirroredY = scrollView.bounds.height - inScroll.maxY
        return CGRect(
            x: inScroll.minX,
            y: mirroredY,
            width: max(inScroll.width, 1),
            height: inScroll.height
        )
    }
}
#endif
