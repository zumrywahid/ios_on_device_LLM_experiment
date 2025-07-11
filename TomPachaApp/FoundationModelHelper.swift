//
//  FMHelper.swift
//  NegativeTalkApp
//
//  Created by Zumry on 28/06/2025.
//
import Foundation
import FoundationModels

class FoundationModelHelper {
    
    /// Returns the opposite version of the given prompt using the Foundation Model.
    static func getFoundationModel(prompt: String) async -> String {
        
        let model = SystemLanguageModel.default
        
        switch model.availability {
        case .available:
            print("Model is available")
        case .unavailable(.appleIntelligenceNotEnabled):
            print("Model is appleIntelligenceNotEnabled")
        case .unavailable(.deviceNotEligible):
            print("Model deviceNotEligible")
        case .unavailable(.modelNotReady):
            print("Model is not ready")
        case .unavailable(let other):
            print("Model is unavailable for an unknown reason: \(other)")
        }

        do {
            let session = LanguageModelSession()
            let prompt = "Return only the opposite version of : '\(prompt)'"
            let response = try await session.respond(to: prompt)
            return response.content
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            print("Generation failed due to guardrail violation.")
        } catch {
            print("Error generating response: \(error)")
        }
        
        return "Something went wrong, please try again later."
        
    }
        
}
    
