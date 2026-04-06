//
//  SupabaseManager.swift
//  Revibe
//

import Foundation
import Supabase

private let supabaseProjectURL = URL(string: "https://elpxxgkgjyufuidnnevk.supabase.co")!

/// Shown after the user taps the email confirmation link. Must be listed in Supabase Dashboard → Authentication → URL Configuration → Redirect URLs.
let authEmailRedirectURL = supabaseProjectURL
    .appendingPathComponent("functions")
    .appendingPathComponent("v1")
    .appendingPathComponent("email-confirmed")

let supabase = SupabaseClient(
    supabaseURL: supabaseProjectURL,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVscHh4Z2tnanl1ZnVpZG5uZXZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwMTMxMDIsImV4cCI6MjA4OTU4OTEwMn0.mE3aeDcjDytEq5-AVN5jL954_PM7fpwtAi7K7RzIsFw"
)
