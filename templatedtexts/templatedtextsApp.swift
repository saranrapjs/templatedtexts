//
//  templatedtextsApp.swift
//  templatedtexts
//
//  Created by Jeffrey Sisson on 8/12/24.
//

import SwiftUI
import SwiftData

@main
struct templatedtextsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TextMessage.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    

    var body: some Scene {
        WindowGroup {
            TextsView()
        }
        .modelContainer(sharedModelContainer)
    }
}


struct TextsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var texts: [TextMessage]

    var body: some View {
        VStack{
            ForEach(texts) { text in
                ContentView(text:text)
            }
        }
        .onAppear {
            if texts.isEmpty {
                modelContext.insert(TextMessage(text: "", groupID: nil))
            }
        }
    }
}
