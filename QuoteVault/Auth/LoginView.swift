//
//  LoginView.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var vm = AuthViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showingSignup = false
    @State private var showingPasswordReset = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Logo
                VStack(spacing: 12) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    Text("QuoteVault")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Discover & Collect Inspiring Quotes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 30)
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Email", text: $vm.email)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)

                    SecureField("Password", text: $vm.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                }
                .padding(.horizontal)

                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Login Button
                Button(action: {
                    Task {
                        if let session = await vm.login() {
                            sessionManager.setSession(session)
                        }
                    }
                }) {
                    HStack {
                        if vm.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Login")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(vm.isLoading || vm.email.isEmpty || vm.password.isEmpty)
                .padding(.horizontal)

                // Forgot Password
                Button("Forgot Password?") {
                    showingPasswordReset = true
                }
                .font(.footnote)
                .foregroundColor(.accentColor)
                
                Spacer()
                
                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    Button("Sign Up") {
                        showingSignup = true
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .font(.subheadline)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignup) {
                SignupView()
            }
            .sheet(isPresented: $showingPasswordReset) {
                PasswordResetSheetView()
            }
        }
    }
}

struct PasswordResetSheetView: View {
    @StateObject private var vm = AuthViewModel()
    @State private var email = ""
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal)
                
                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if showSuccess {
                    Text("Password reset email sent! Check your inbox.")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                Button(action: {
                    Task {
                        await vm.resetPassword(email: email)
                        if vm.errorMessage == nil {
                            showSuccess = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                dismiss()
                            }
                        }
                    }
                }) {
                    Text("Send Reset Link")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(email.isEmpty || vm.isLoading)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 30)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
