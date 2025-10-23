//
//  ContentView.swift
//  messageAI
//
//  Created by Miriam Flander on 10/20/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            switch authViewModel.route {
            case .splash:
                ProgressView()
                    .progressViewStyle(.circular)
            case .signIn:
                LoginView(viewModel: authViewModel)
            case .signUp:
                SignUpView(viewModel: authViewModel)
            case .username(let session):
                UsernameSetupView(viewModel: authViewModel, session: session)
            case .authenticated(let session):
                if let presenceService = authViewModel.presenceService {
                    MainTabView(session: session,
                                modelContext: modelContext,
                                presenceService: presenceService,
                                onSignOut: {
                        Task {
                            await authViewModel.signOut()
                        }
                    })
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
        }
    }
        .animation(.easeInOut, value: authViewModel.route)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            User.self,
            Conversation.self,
            Message.self,
            Contact.self
        ], inMemory: true)
}
