//
//  SupabaseManager.swift
//  Revibe
//

import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://elpxxgkgjyufuidnnevk.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVscHh4Z2tnanl1ZnVpZG5uZXZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwMTMxMDIsImV4cCI6MjA4OTU4OTEwMn0.mE3aeDcjDytEq5-AVN5jL954_PM7fpwtAi7K7RzIsFw"
)
