//
//  CategorySearchView.swift
//  Scrumdinger
//
//  Created by Thomas Kowalski on 07/09/2024.
//

import SwiftUI

struct UploadFileView: View {
    @State private var userInput: String = ""
    
    @State var categories: [CategoryName] = []

    @State private var selectedImage: UIImage?
    @State private var isPickerPresented: Bool = false
    
    @StateObject private var network = NetworkManager()

    var body: some View {
        NavigationStack {
            VStack {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .onTapGesture {
                            // self.selectedImage = nil
                            isPickerPresented.toggle()
                        }
                } else {
                    Text("No Image Selected")
                        .foregroundColor(.gray)
                }
                Button("Select Photo") {
                    // selectedImage = nil
                    isPickerPresented.toggle()
                }
                .padding()
            }
            Form {
                Section("Basic info") {
                    if #available(iOS 17.0, *) {
                        TextField("File name", text: $userInput)
                            .onChange(of: userInput) {
                                withAnimation{
                                    network.checkIfFileExists(name: userInput)
                                    network.searchWikidataEntities(terms: userInput)
                                }
                            }
                    } else {
                        TextField("File name", text: $userInput)
                            .onChange(of: userInput) { newValue in
                                withAnimation {
                                    network.checkIfFileExists(name: userInput)
                                    network.searchWikidataEntities(terms: userInput)
                                }
                            }
                    }
                    
                    ZStack {
                        if network.pageExists {
                            Text(network.pageExists ? "File \(userInput) already exists" : "thomas")
                                .foregroundColor(.red)
                        }
                    }
                    .transition(.push(from: .top))
                    .animation(.easeInOut(duration: 1), value: network.pageExists)
                }
                
                Section("Tagging") {
                    NavigationLink(destination: CategorySearchingView(results: $categories)) {
                        Text(categoriesButtonText)
                    }
                    NavigationLink(destination: Text("thomas")) {
                        Text("Wikidata")
                    }
                }
                .navigationTitle("Upload file")
            }
        }
        .sheet(isPresented: $isPickerPresented) {
            PhotoPicker(selectedImage: $selectedImage)
        }
        .onChange(of: isPickerPresented) { newValue in
            
        }
    }
    
    var categoriesButtonText: String {
        switch categories.count {
        case 0:
            return "Select categories"
        case 1:
            let category = categories[0]
            return "\(category.name)"
        default:
            return "\(categories.count) categories"
        }
    }
}

#Preview {
    UploadFileView()
}
