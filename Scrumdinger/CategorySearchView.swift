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
    @State var entities: [EntityName] = []

    @State private var selectedImage: UIImage?
    @State private var selectedImageFormat: ImageFormat?
    @State private var isPickerPresented: Bool = false
    
    @StateObject public var network: NetworkManager

    var body: some View {
        NavigationStack {
                VStack {
                    Form {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .onTapGesture {
                                    isPickerPresented.toggle()
                                }
                        } else {
                            Text("No Image Selected")
                                .foregroundColor(.gray)
                        }
                        Button("Select Photo") {
                            isPickerPresented.toggle()
                        }
                        .padding()
                        Section("Basic info") {
                            if #available(iOS 17.0, *) {
                                TextField("File name", text: $userInput)
                                    .onChange(of: userInput) {
                                        withAnimation{
                                            if let fileName = currentFileName {
                                                network.checkIfFileExists(name: fileName)
                                            }
                                        }
                                    }
                            } else {
                                TextField("File name", text: $userInput)
                                    .onChange(of: userInput) { newValue in
                                        withAnimation {
                                            if let fileName = currentFileName {
                                                network.checkIfFileExists(name: fileName)
                                            }
                                        }
                                    }
                            }
                            
                            Text(self.fileNameStatus)
                                .foregroundColor(self.fileNameColor)
                            
                        }
                        Section("Tagging") {
                            NavigationLink(destination: CategorySearchingView(results: $categories)) {
                                Text(categoriesButtonText)
                            }
                            NavigationLink(destination: EntitySearchingView(results: $entities)) {
                                Text(entitiesButtonText)
                            }
                        }
                    
                    }
                }
                .navigationTitle("Upload file")
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    NavigationLink(
                        destination: DoUploadView(request: createRequest(), network: network)
                    ) {
                        Text("Upload")
                            .disabled(!canUpload)
                    }
                    /*Button("About") {
                        print("About tapped!")
                    }
                     */

                    Button("Help") {
                        print("Help tapped!")
                    }
                }
            /*
            NavigationLink(
                    destination: Text("hello") // DoUploadView(image: self.selectedImage, network: network)
                ) {
                    Text("hello thomas")
                     Button("Upload file") {
                        print("hello")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
             */
        }
        .sheet(isPresented: $isPickerPresented) {
            PhotoPicker(
                selectedImage: $selectedImage,
                selectedImageFormat: $selectedImageFormat
            )
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
    
    var entitiesButtonText: String {
        switch entities.count {
        case 0:
            return "Select entities"
        case 1:
            let entity = entities[0]
            return "\(entity.name)"
        default:
            return "\(entities.count) entities"
        }
    }
    
    var fileNameStatus: String {
        if selectedImage == nil {
            return "Select an image..."
        }
        
        if self.userInput == "" {
            return "No file name entered"
        }
        
        if network.pageExists, let currentFileName = currentFileName {
            return "File \(currentFileName) already exists"
        }
                
        return "File name is valid"
    }
    
    var fileNameColor: Color {
        if self.userInput == "" {
            return .black
        }

        if network.pageExists {
            return .red
        }
        
        return .green
    }
    
    var currentFileName: String? {
        if userInput == "" {
            return nil
        }

        guard let format = self.selectedImageFormat else {
            return nil
        }
        
        var extString = ""
        switch format {
        case .JPEG:
            extString = ".jpg"
        case .PNG:
            extString = ".png"
        case .Error:
            fallthrough
        case .Other:
            extString = ""
        }
        
        return userInput + extString
    }
    
    var canUpload: Bool {
        if selectedImage == nil {
            return false
        }
        
        return true
    }
    
    func createRequest() -> UploadRequest {
        return UploadRequest(
            image: selectedImage,
            title: self.userInput,
            entities: self.entities,
            categories: self.categories
        )
    }
}

#Preview {
    let networkManager = NetworkManager()
    return UploadFileView(network: networkManager)
}
