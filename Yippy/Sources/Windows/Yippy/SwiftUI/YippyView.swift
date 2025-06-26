//
//  YippyView.swift
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

class SUIYippyViewController: NSHostingController<YippyView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: YippyView())
    }
}

#Preview {
    YippyView()
}

struct YippyView: View {
    
    enum Focus {
        case searchbar
    }
    
    @Bindable var viewModel = YippyViewModel()
    @FocusState private var focusState: Focus?
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 4) {
                HStack {
                    Text("Yippy")
                        .font(.title)
                    Spacer()
                    Button {
                    } label: {
                        Image(systemName: "photo")
                    }
                    .buttonStyle(.borderless)
                    Button {
                    } label: {
                        Image(systemName: "document.fill")
                    }
                    .buttonStyle(.borderless)
                    Button {
                    } label: {
                        Image(systemName: "text.page")
                    }
                    .buttonStyle(.borderless)
                    Button {
                        viewModel.filterBookmarks()
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(viewModel.showBookmarks ? .accentColor : .gray )
                    }
                    .buttonStyle(.borderless)
                }.padding(.horizontal, 24)
                
                HStack{
                    Image(systemName: "magnifyingglass")
                    TextField(text: $viewModel.searchBarValue, prompt: Text("Search For Something...")) {
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($focusState, equals: .searchbar)
                    .autocorrectionDisabled()
                    .onChange(of: viewModel.searchBarValue) { _, _ in
                        viewModel.onSearchBarValueChange()
                    }
                    Text(viewModel.itemCountLabel)
                        .font(.subheadline)
                }.padding(.horizontal, 24)
                
                YippyHistoryTableView(viewModel: viewModel)
                    .onAppear(perform: viewModel.onAppear)
            }
        }
        .safeAreaPadding(.top, 48)
        .materialBlur(style: .sidebar)
        .onChange(of: viewModel.isSearchBarFocused) { _, newValue in
            if newValue == true {
                self.focusState = .searchbar
            } else {
                self.focusState = nil
            }
        }
    }
}

struct YippyHistoryTableView: View {
    
    @Bindable var viewModel: YippyViewModel
    
    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { reader in
                ScrollView(viewModel.panelPosition, showsIndicators: false) {
                    if viewModel.panelPosition == .horizontal {
                        LazyHStack(spacing: 12) {
                            content(proxy: proxy)
                        }
                    } else {
                        LazyVStack(spacing: 4) {
                            content(proxy: proxy)
                                .padding(.top, 8)
                        }
                    }
                }
                .onChange(of: viewModel.selectedItem) { oldValue, newValue in
                    if let value = newValue {
                        reader.scrollTo(value)
                    }
                }
            }
        }
        .environment(\.historyCellSettings, HistoryCellSettings())
    }
    
    func content(proxy: GeometryProxy) -> some View {
        ForEach(Array(viewModel.yippyHistory.items.enumerated()), id: \.element) { (index, item) in
            HistoryCellView(item: item, proxy: proxy, usingItemRtf: viewModel.isRichText)
                .clipShape(
                    RoundedRectangle(cornerRadius: 4)
                )
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(NSColor.textBackgroundColor))
                )
                .overlay {
                    ZStack(alignment: .topLeading) {
                        if viewModel.selectedItem == item {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.accentColor, lineWidth: 2, )
                        }
                        if index < 10 {
                            VStack {
                                HStack {
                                    Text("\(index)")
                                        .font(.system(size: 8))
                                        .frame(width: 8, height: 12, alignment: .center)
                                        .padding(EdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1))
                                        .foregroundStyle(Color(NSColor.textBackgroundColor))
                                        .background(
                                            UnevenRoundedRectangle(cornerRadii: .init(
                                                topLeading: 4,
                                                bottomLeading: 0,
                                                bottomTrailing: 4,
                                                topTrailing: 0),
                                                                   style: .continuous)
                                            .fill(viewModel.selectedItem == item ? Color.accentColor : Color.secondary)
                                        )
                                        .offset(x: 0, y: -5)
                                        Spacer()
                                        Button {
                                            viewModel.toggleBookmark(id: item.id)
                                        } label: {
                                            Image(systemName: item.bookmarked ? "bookmark.fill" : "bookmark")
                                        }
                                        .buttonStyle(.borderless)
                                        .foregroundColor(item.bookmarked ? .accentColor : .gray )
                                        .padding(4)
                                }
                                Spacer()
                            }
                        } else{
                            VStack {
                                HStack {
                                    Spacer()
                                    Button {
                                        viewModel.toggleBookmark(id: item.id)
                                    } label: {
                                        Image(systemName: item.bookmarked ? "bookmark.fill" : "bookmark")
                                    }
                                    .buttonStyle(.borderless)
                                    .foregroundColor(item.bookmarked ? .accentColor : .gray )
                                    .padding(4)
                                }
                                Spacer()
                            }
                        }
                       
                    }
                }
                .onTapGesture {
                    viewModel.onSelectItem(at: index)
                }
                .contextMenu(
                    ContextMenu(menuItems: {
                        Button("Copy") {
                            viewModel.paste(at: index)
                        }
                        
                        Button("Delete") {
                            viewModel.delete(at: index)
                        }
                    })
                )
                .id(item)
                .draggable(item)
        }
    }
}
