//
//  ContentView.swift
//  BrewManager
//
//  Created by Izam on 11/10/2025.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var selectedItem: NavigationItems = .home
    
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedItem) {
                ForEach(NavigationItems.mainNavigationItems, id: \.title) { item in
                    NavigationLink(value: item) {
                        HStack {
                            if !item.systemImageName.isEmpty {
                                Image(systemName: item.systemImageName)
                            }
                            Text(item.title)
                        }
                    }
                }
                Divider()
                NavigationLink(value: NavigationItems.about) {
                    HStack {
                        Image(systemName: NavigationItems.about.systemImageName)
                        Text(NavigationItems.about.title)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            NavigationStack {
                    detailView()
            }
        }
        .background(WindowAccessor())
    }
    
    @ViewBuilder
    private func detailView() -> some View {
        switch selectedItem {
        case .home:
            HomeView()
        case .discover:
            DiscoverView()
        case .about:
            AboutView()
        case .settings:
            Text("Settings View" )
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.isOpaque = false
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            window.isOpaque = false
        }
    }
}

#Preview {
    ContentView()
}
