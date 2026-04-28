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
    @State private var needsOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if isCheckingSession {
                    ProgressView()
                        .tint(DS.Colors.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(DS.Colors.bgPrimary.ignoresSafeArea())
                } else if !isAuthenticated {
                    AuthView()
                } else if needsOnboarding {
                    OnboardingView {
                        needsOnboarding = false
                    }
                } else {
                    ContentView()
                }
            }
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                Task { try? supabase.auth.handle(url) }
            }
            .task {
                let hasSession = (try? await supabase.auth.session) != nil
                isAuthenticated = hasSession
                if hasSession { await checkOnboarding() }
                isCheckingSession = false

                for await (event, session) in supabase.auth.authStateChanges {
                    switch event {
                    case .signedIn, .tokenRefreshed, .initialSession:
                        isAuthenticated = session != nil
                        if session != nil { await checkOnboarding() }
                    case .signedOut:
                        isAuthenticated = false
                        needsOnboarding = false
                    default:
                        break
                    }
                }
            }
        }
    }

    private func checkOnboarding() async {
        do {
            let userId = try await supabase.auth.session.user.id.uuidString
            let count: Int = try await supabase
                .from("onboarding_responses")
                .select("*", head: true, count: .exact)
                .eq("user_id", value: userId)
                .execute()
                .count ?? 0
            needsOnboarding = count == 0
        } catch {
            needsOnboarding = true
        }
    }
}
