//
//  AuthView.swift
//  Revibe
//

import SwiftUI
import Supabase

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showConfirmationAlert = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: DS.Spacing.xs) {
                Text("Revibe")
                    .font(.system(size: 38, weight: .regular, design: .serif))
                    .foregroundColor(DS.Colors.textPrimary)
                    .tracking(-0.5)

                Text(isSignUp ? "Create an account" : "Welcome back")
                    .font(.subheadline)
                    .foregroundColor(DS.Colors.textMuted)
            }

            Spacer().frame(height: DS.Spacing.lg)

            VStack(spacing: 12) {
                if isSignUp {
                    TextField("", text: $displayName, prompt: Text("Display name").foregroundColor(DS.Colors.textMuted))
                        .foregroundColor(DS.Colors.textPrimary)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(DS.Colors.bgSecondary)
                        .cornerRadius(DS.Radius.input)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.input)
                                .stroke(DS.Colors.border, lineWidth: 1)
                        )
                }

                TextField("", text: $email, prompt: Text("Email").foregroundColor(DS.Colors.textMuted))
                    .foregroundColor(DS.Colors.textPrimary)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .padding(12)
                    .background(DS.Colors.bgSecondary)
                    .cornerRadius(DS.Radius.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.input)
                            .stroke(DS.Colors.border, lineWidth: 1)
                    )

                SecureField("", text: $password, prompt: Text("Password").foregroundColor(DS.Colors.textMuted))
                    .foregroundColor(DS.Colors.textPrimary)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .padding(12)
                    .background(DS.Colors.bgSecondary)
                    .cornerRadius(DS.Radius.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.input)
                            .stroke(DS.Colors.border, lineWidth: 1)
                    )
            }
            .padding(.horizontal, DS.Spacing.md)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(DS.Colors.error)
                    .padding(.top, DS.Spacing.xs)
                    .padding(.horizontal, DS.Spacing.md)
            }

            Spacer().frame(height: DS.Spacing.md)

            Button {
                Task { await authenticate() }
            } label: {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(DS.Colors.textOnAccent)
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DS.Colors.textOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(DS.Colors.accent)
                .cornerRadius(DS.Radius.button)
            }
            .disabled(isLoading)
            .padding(.horizontal, DS.Spacing.md)

            Spacer().frame(height: 12)

            Button {
                withAnimation { isSignUp.toggle() }
                errorMessage = nil
            } label: {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.subheadline)
                    .foregroundColor(DS.Colors.textMuted)
            }

            Spacer()
        }
        .background(DS.Colors.bgPrimary.ignoresSafeArea())
        .alert("Check Your Email", isPresented: $showConfirmationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A confirmation email has been sent to your email.")
        }
    }

    private func authenticate() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        if isSignUp && displayName.isEmpty {
            errorMessage = "Please enter a display name."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            if isSignUp {
                try await supabase.auth.signUp(
                    email: email,
                    password: password,
                    data: ["display_name": .string(displayName)],
                    redirectTo: authEmailRedirectURL
                )
                showConfirmationAlert = true
            } else {
                try await supabase.auth.signIn(
                    email: email,
                    password: password
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    AuthView()
}
