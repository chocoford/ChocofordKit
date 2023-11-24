//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/11/23.
//

import Foundation
import Vision

extension VNImageRequestHandler {
    public func getOCRString(joiner: String = " ") async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            // Create a new request to recognize text.
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let request = request as? VNRecognizeTextRequest else {
                    return
                }
                guard let observations = request.results else {
                    return
                }
                let recognizedStrings = observations.compactMap { observation in
                    // Return the string of the top VNRecognizedText instance.
                    return observation.topCandidates(1).first?.string
                }
                let joined = recognizedStrings.joined(separator: joiner)
                DispatchQueue.main.async {
                    continuation.resume(returning: joined)
                }
            }
            if #available(macOS 13.0, *) {
                request.automaticallyDetectsLanguage = true
            } else {
                request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US", "fr-FR", "it-IT", "de-DE", "es-ES", "pt-BR"]
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
//            DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.perform([request])
            } catch {
//                continuation.resume(throwing: error)
                dump(error)
            }
//            }
        }
    }
    public func getFeature(imageCropAndScaleOption: VNImageCropAndScaleOption = .scaleFill) async throws -> VNFeaturePrintObservation {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateImageFeaturePrintRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let request = request as? VNGenerateImageFeaturePrintRequest else {
                    return
                }
                guard let observation = request.results?.first else {
                    return
                }
                continuation.resume(returning: observation)
            }
            request.imageCropAndScaleOption = .scaleFit
            
//            DispatchQueue.global(qos: .background).async {
                do {
                    try self.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
//            }
        }
    }
    public func getClassifications() async throws -> [VNClassificationObservation] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let request = request as? VNClassifyImageRequest else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: request.results ?? [])
            }
            
            DispatchQueue.global(qos: .background).async {
                do {
                    try self.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
