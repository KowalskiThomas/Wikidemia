//
//  DoUploadView.swift
//  Scrumdinger
//
//  Created by Thomas Kowalski on 14/09/2024.
//

import SwiftUI

struct UploadRequest {
    let image: UIImage?
    let title: String?
    let entities: [EntityName]?
    let categories: [CategoryName]?
}

struct DoUploadView: View {
    public var request: UploadRequest
    
    @StateObject var network: NetworkManager
    
    var body: some View {
        NavigationStack {
            VStack {
                if let image = request.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .onTapGesture {}
                }
                ProgressView {
                    
                }
                Text("Uploading")
            }
            
            .navigationTitle("Uploading")
            .onAppear() {
                network.doUpload(request: request)
            }
        }
    }
}

#Preview {
    let placeholderImage = UIImage(named: "sampleImage") ?? UIImage(systemName: "photo")!
    let networkManager = NetworkManager()
    let request = UploadRequest(image: placeholderImage, title: "My image", entities: [], categories: [])
    return DoUploadView(request: request, network: networkManager)
}
