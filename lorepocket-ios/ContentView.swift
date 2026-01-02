//
//  ContentView.swift
//  lorepocket-ios
//
//  Created by 細田健司 on 2026/01/02.
//

import SwiftUI

struct ContentView: View {
    @State private var store = ProgressStore()
    @State private var library = PackLibrary()
    
    var body: some View {
        RootTabView(store: store, library: library)
    }
}

#Preview {
    ContentView()
}
