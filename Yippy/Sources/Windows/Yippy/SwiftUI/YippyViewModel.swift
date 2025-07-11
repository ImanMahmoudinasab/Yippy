//
//  YippyViewModel.swift
//  Yippy
//
//  Created by v.prusakov on 2/13/24.
//  Copyright © 2024 MatthewDavidson. All rights reserved.
//

import Cocoa
import HotKey
import RxSwift
import RxRelay
import RxCocoa
import SwiftUI
import Observation

struct Results {
    let items: [HistoryItem]
    let isSearchResult: Bool
}

@Observable
class YippyViewModel {
    
    var searchBarValue: String = ""
    var itemCountLabel: String = ""
    var isSearchBarFocused: Bool = false
    var showBookmarks: Bool = false
    
    var yippyHistory = YippyHistory(history: State.main.history, items: [])
    
    private var searchEngine = SearchEngine(data: [])
    private let disposeBag = DisposeBag()
    
    var isPreviewShowing = false
    
    var panelPosition: Axis.Set = .vertical
    
    var itemGroups = BehaviorRelay<[String]>(value: ["Clipboard", "Favourites", "Clipboard", "Favourites", "Clipboard", "Favourites"])
    
    var isRichText = Settings.main.showsRichText
    
    private(set) var selectedItem: HistoryItem?
    var scrollToSelectedItem: UUID?
    
    private let results = BehaviorRelay(value: Results(items: [], isSearchResult: false))
    private let selected = BehaviorRelay<Int?>(value: nil)
    
    func onAppear() {
        State.main.history.subscribe(onNext: onHistoryChange)
        
        State.main.panelPosition.subscribe(onNext: onWindowPanelPositionChanged).disposed(by: disposeBag)
        
        State.main.showsRichText.distinctUntilChanged().subscribe(onNext: onShowsRichText).disposed(by: disposeBag)
        
        Observable.combineLatest(
            results,
            selected.distinctUntilChanged().withPrevious(startWith: nil)
        )
        .observe(on: MainScheduler.instance)
        .subscribe(onNext: onAllChange)
        .disposed(by: disposeBag)
        
        // TODO: Fix hack to make onAllChange run initially
        selected.accept(1)
        resetSelected()
        
        YippyHotKeys.downArrow.onDown(goToNextItem)
        YippyHotKeys.downArrow.onLong(goToNextItem)
        YippyHotKeys.pageDown.onDown(goToNextItem)
        YippyHotKeys.pageDown.onLong(goToNextItem)
        YippyHotKeys.upArrow.onDown(goToPreviousItem)
        YippyHotKeys.upArrow.onLong(goToPreviousItem)
        YippyHotKeys.pageUp.onDown(goToPreviousItem)
        YippyHotKeys.pageUp.onLong(goToPreviousItem)
        YippyHotKeys.escape.onDown(close)
        YippyHotKeys.return.onDown(pasteSelected)
        YippyHotKeys.ctrlAltCmdLeftArrow.onDown { State.main.panelPosition.accept(.left) }
        YippyHotKeys.ctrlAltCmdRightArrow.onDown { State.main.panelPosition.accept(.right) }
        YippyHotKeys.ctrlAltCmdDownArrow.onDown { State.main.panelPosition.accept(.bottom) }
        YippyHotKeys.ctrlAltCmdUpArrow.onDown { State.main.panelPosition.accept(.top) }
        YippyHotKeys.ctrlDelete.onDown(deleteSelected)
        YippyHotKeys.space.onDown(togglePreview)
        YippyHotKeys.cmdBackslash.onDown(focusSearchBar)
        YippyHotKeys.toggleBookmarksFilter.onDown(self.toggleBookmarksFilter)
        YippyHotKeys.toggleBookmark.onDown{self.toggleBookmark()}
        
        // Paste hot keys
        YippyHotKeys.cmd0.onDown { self.shortcutPressed(key: 0) }
        YippyHotKeys.cmd1.onDown { self.shortcutPressed(key: 1) }
        YippyHotKeys.cmd2.onDown { self.shortcutPressed(key: 2) }
        YippyHotKeys.cmd3.onDown { self.shortcutPressed(key: 3) }
        YippyHotKeys.cmd4.onDown { self.shortcutPressed(key: 4) }
        YippyHotKeys.cmd5.onDown { self.shortcutPressed(key: 5) }
        YippyHotKeys.cmd6.onDown { self.shortcutPressed(key: 6) }
        YippyHotKeys.cmd7.onDown { self.shortcutPressed(key: 7) }
        YippyHotKeys.cmd8.onDown { self.shortcutPressed(key: 8) }
        YippyHotKeys.cmd9.onDown { self.shortcutPressed(key: 9) }
        
        bindHotKeyToYippyWindow(YippyHotKeys.downArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.upArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.return, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.escape, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.pageDown, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.pageUp, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdLeftArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdRightArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdDownArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdUpArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd0, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd1, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd2, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd3, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd4, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd5, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd6, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd7, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd8, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd9, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlDelete, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.space, disposeBag: disposeBag)
    }
    
    func resetSelected() {
        if yippyHistory.items.count > 0 {
            selected.accept(0)
            selectedItem = yippyHistory.items[0]
        }
        else {
            selected.accept(nil)
            selectedItem = nil
        }
    }
    
    func scrollToSelected() {
        self.scrollToSelectedItem = UUID()
    }
    
    func onHistoryChange(_ history: [HistoryItem], change: History.Change) {
        updateSearchEngine(items: history)
        scrollToSelected()
        switch change {
        case .toggleBookmark:
            if self.showBookmarks {
                runSearch()
                resetSelected()
                return;
            }
            break;
        case .move:
            runSearch()
            resetSelected()
            return;
        default: break;
        }

        if !searchBarValue.isEmpty {
            runSearch()
            resetSelected()
        }
        else {
            results.accept(Results(items: history, isSearchResult: false))
            switch change {
            case .insert(let i):
                if i == 0 {
                    incrementSelected()
                }
                break;
            default: break;
            }
        }
    }
    
    func onWindowPanelPositionChanged(_ position: PanelPosition) {
        switch position {
        case .right, .left:
            panelPosition = .vertical
        case .top, .bottom:
            panelPosition = .horizontal
        default:
            panelPosition = .vertical
        }
    }
    
    func onSearchBarValueChange() {
        runSearch()
        resetSelected()
        scrollToSelected()
    }
    
    func updateSearchEngine(items: [HistoryItem]) {
        self.searchEngine = SearchEngine(data: items.compactMap({$0.getPlainString()}))
    }
    
    func onAllChange(_ results: Results, _ selected: (Int?, Int?)) {
        if results.items != self.yippyHistory.items {
            if results.isSearchResult {
                self.itemCountLabel = "\(results.items.count) matches"
            }
            else {
                self.itemCountLabel = "\(results.items.count) items"
            }
            
            self.yippyHistory = YippyHistory(history: State.main.history, items: results.items)
        }
        
        if let selectedIndex = selected.1, yippyHistory.items.indices.contains(selectedIndex) {
            self.selectedItem = yippyHistory.items[selectedIndex]
            
            if self.isPreviewShowing {
                State.main.previewHistoryItem.accept(self.yippyHistory.items[selectedIndex])
            }
        }
    }
    
    func onShowsRichText(_ showsRichText: Bool) {
        isRichText = showsRichText
    }
    
    func bindHotKeyToYippyWindow(_ hotKey: YippyHotKey, disposeBag: DisposeBag) {
        State.main.isHistoryPanelShown
            .distinctUntilChanged()
            .subscribe(onNext: { [] in
                hotKey.isPaused = !$0
            })
            .disposed(by: disposeBag)
    }
    
    func goToNextItem() {
        incrementSelected()
        scrollToSelected()
    }
    
    func goToPreviousItem() {
        decrementSelected()
        scrollToSelected()
    }
    
    func pasteSelected() {
        if let selected = self.selected.value {
            paste(selected: selected)
            isSearchBarFocused = false
            searchBarValue = ""
            isSearchBarFocused = true
        }
    }
    
    func deleteSelected() {
        if let selected = self.selected.value {
            self.selected.accept(yippyHistory.delete(selected: selected))
            if self.selected.value != nil {
                self.selectedItem = yippyHistory.items[self.selected.value!]
            }
        }
    }
    
    func paste(at index: Int) {
        paste(selected: index)
    }
    
    func delete(at index: Int) {
        self.selected.accept(yippyHistory.delete(selected: index))
        if self.selected.value != nil {
            self.selectedItem = yippyHistory.items[self.selected.value!]
        }
    }
    
    func toggleBookmarksFilter() {
        self.showBookmarks.toggle()
        self.runSearch()
        resetSelected()
        scrollToSelected()
    }
    
    func toggleBookmark(id: UUID?=nil) {
        if id == nil && self.selectedItem != nil {
            yippyHistory.toggleBookmark(selected: self.selectedItem!.fsId)
            return
        }
        if let id = id {
            yippyHistory.toggleBookmark(selected: id)
        }
    }
    
    func onSelectItem(at index: Int) {
        self.selected.accept(index)
        self.selectedItem = yippyHistory.items[index]
        scrollToSelected()
    }
    
    func close() {
        isPreviewShowing = false
        State.main.isHistoryPanelShown.accept(false)
        State.main.previewHistoryItem.accept(nil)
        resetSelected()
    }
    
    func shortcutPressed(key: Int) {
        paste(selected: key)
    }
    
    func togglePreview() {
        if let selected = self.selected.value {
            isPreviewShowing = !isPreviewShowing
            if isPreviewShowing {
                // TODO: "selected" sometimes is out of index and crashes the app
                State.main.previewHistoryItem.accept(yippyHistory.items[selected])
            }
            else {
                State.main.previewHistoryItem.accept(nil)
            }
        }
    }
    
    func focusSearchBar() {
        NSApp.activate(ignoringOtherApps: true)
        self.isSearchBarFocused = true
    }
    
    func runSearch() {
        if (self.searchBarValue.isEmpty) {
            if self.showBookmarks {
                self.results.accept(Results(items: State.main.history.items.filter({ HistoryItem in
                    return HistoryItem.bookmarked
                }), isSearchResult: false))
            } else {
                self.results.accept(Results(items: State.main.history.items, isSearchResult: false))
            }
            return
        }
        self.results.accept(Results(items: State.main.history.items.filter({ HistoryItem in
            if self.showBookmarks {
                if let urlString = HistoryItem.getPlainString() {
                    return urlString.lowercased().contains(self.searchBarValue.lowercased()) && HistoryItem.bookmarked
                }
            }
            if !self.showBookmarks {
                if let urlString = HistoryItem.getPlainString() {
                    return urlString.lowercased().contains(self.searchBarValue.lowercased())
                }
            }
            return false
        }), isSearchResult: true))
    }
    
    private func incrementSelected() {
        guard let s = selected.value else {
            if yippyHistory.items.count > 0 {
                selected.accept(0)
                selectedItem = yippyHistory.items[0]
            }
            return
        }
        if s < yippyHistory.items.count - 1 {
            selected.accept(s + 1)
            selectedItem = yippyHistory.items[s + 1]
        }
    }
    
    private func decrementSelected() {
        guard let s = selected.value else {
            if yippyHistory.items.count > 0 {
                selected.accept(0)
                selectedItem = yippyHistory.items[0]
            }
            return
        }
        if s > 0 {
            selected.accept(s - 1)
            selectedItem = yippyHistory.items[s - 1]
        }
    }
    
    private func paste(selected: Int) {
        self.close()
        yippyHistory.paste(selected: selected)
    }
}
