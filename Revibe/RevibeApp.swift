//
//  RevibeApp.swift
//  Revibe
//
//  Created by Jason Liu on 2/26/26.
//

import SwiftUI
import Supabase

@main
struct RevibeApp: App {
    @State private var isAuthenticated = false
    @State private var isCheckingSession = true

    var body: some Scene {
        WindowGroup {
            Group {
                if isCheckingSession {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(DS.Colors.bgPrimary.ignoresSafeArea())
                } else if isAuthenticated {
                    ContentView()
                } else {
                    AuthView()
                }
            }
            .task {
                let hasSession = (try? await supabase.auth.session) != nil
                isAuthenticated = hasSession
                isCheckingSession = false

                for await (event, session) in await supabase.auth.authStateChanges {
                    switch event {
                    case .signedIn, .tokenRefreshed, .initialSession:
                        isAuthenticated = session != nil
                    case .signedOut:
                        isAuthenticated = false
                    default:
                        break
                    }
                }
            }
        }
    }
}
