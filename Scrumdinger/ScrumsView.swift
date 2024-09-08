//
//  ScrumsView.swift
//  Scrumdinger
//
//  Created by Thomas Kowalski on 04/09/2024.
//

import SwiftUI


struct ScrumsView: View {
    @StateObject private var networkManager = NetworkManager()
    @Binding var scrums: [DailyScrum]
  
    @State private var isPickerPresented = false
    @State private var isUploadPresented = false
    @State private var isSearchPresented = true
    @State private var newSelectedImage: UIImage?
    @State private var selectedImage: UIImage?
    
    @State var categoryNames: [CategoryName] = []
    
    var body: some View {
        /*
        NavigationStack {
            List($scrums) { $scrum in
                NavigationLink(destination: DetailView(scrum: $scrum)) {
                    CardView(scrum: scrum)
                }
                .listRowBackground(scrum.theme.mainColor)
            }
            .navigationTitle("Daily Scrums")
            .toolbar {
                Button(action: {
                    scrums[0].title = "thomas"
                }) {
                    Image(systemName: "plus")
                }
            }
        }
         */
        VStack {
            /*
             if let categories = networkManager.categoryResults {
                Text("Name: \(categories)")
                // Text("Email: \(user.email)")
            } else {
                Text("Loading...")
            }
             */
        }


        .sheet(isPresented: $isUploadPresented) {
            VStack {
                Image(uiImage: forceSelectedImage())
                    .resizable()
                    .scaledToFit()
                List(networkManager.categoryResults, selection: $selectedItems) { category in
                    Text(category.name)
                    .onTapGesture {
                        toggleSelection(item: category)
                    }
                }
                Text(selectedItemsStr)
            }
        }
    }
    
    @State private var selectedItems = Set<String>()
    
    var selectedItemsStr: String {
        get {
            let count = selectedItems.count
            if count == 0 {
                return "No categories"
            } else if count == 1 {
                return "One category"
            }
            
            return "\(count) categories"
        }
    }
    
    private func toggleSelection(item: CategoryName) {
        // print("Tapped \(item)")
        if selectedItems.contains(item.id) {
            // print("  -> Removing")
            selectedItems.remove(item.id)
        } else {
            // print("  -> Inserting")
            selectedItems.insert(item.id)
        }
    }
    
    private func forceSelectedImage() -> UIImage {
        guard let selectedImage = self.selectedImage else {
            print("Tried to access selectedImage with selectedImage not set, crashing.")
            exit(1)
        }
        
        return selectedImage
    }
}


struct ScrumsView_Previews: PreviewProvider {
    static var previews: some View {
        ScrumsView(scrums: .constant(DailyScrum.sampleData))
    }
}
