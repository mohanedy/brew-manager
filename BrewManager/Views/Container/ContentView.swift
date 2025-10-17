//
//  ContentView.swift
//  BrewManager
//
//  Created by Izam on 11/10/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItem: NavigationItems = .home
    
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedItem) {
                ForEach(NavigationItems.allCases , id: \.title) { item in
                    NavigationLink(value: item) {
                        HStack {
                            if !item.systemImageName.isEmpty {
                                Image(systemName: item.systemImageName)
                            }
                            Text(item.title)
                        }
                    }
                }
                
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            selectedItem.view
                .padding()
        }
        
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
