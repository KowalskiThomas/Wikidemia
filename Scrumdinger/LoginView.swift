//
//  LoginView.swift
//  Scrumdinger
//
//  Created by Thomas Kowalski on 13/09/2024.
//

import SwiftUI

struct LoginView: View {
    @State private var username: String = "ThomasInTheSkyTest@ThomasInTheSkyTest"
    @State private var password: String = "0q8dqsiv6p9t5ont3lukcpmguh3n6ekg"
    
    @StateObject var networkManager = NetworkManager()
    @State var errorReasonShowed = false

    var body: some View {
        NavigationStack {
                Form {
                    TextField("Email", text: $username) {
                        
                    }
                    SecureField("Password", text: $password) {
                        
                    }
                    Button("Log in", action: {
                        if networkManager.csrfToken == "" {
                            print("Still waiting...")
                        } else {
                            errorReasonShowed = false
                            networkManager.loginToWikidata(token: networkManager.csrfToken, username: username, password: password)
                        }
                    })
                    .disabled(networkManager.csrfToken == "")
                    .alert(networkManager.loginErrorReason ?? "", isPresented: .constant(networkManager.loginErrorReason != nil && errorReasonShowed == false)) {
                        Button("OK", role: .cancel, action: {
                            errorReasonShowed = true
                        })
                    }
            }
            .navigationDestination(
                isPresented: .constant(networkManager.loggedUsername != nil),
                destination: {
                    UploadFileView(network: networkManager)
                }
            )
            .navigationTitle("Login")
            .onAppear {
                networkManager.getCsrfToken()
            }
        }
    }
}

#Preview {
    LoginView()
}
