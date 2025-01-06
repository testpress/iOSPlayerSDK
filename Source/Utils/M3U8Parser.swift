//
//  M3U8Util.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 20/11/24.
//

import Foundation

#if CocoaPods
import M3U8Kit
#else
import M3U8Parser
#endif

public class M3U8Parser {
    
    static func extractContentID(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            // Create a playlist model from the master URL
            let masterPlaylist = try M3U8PlaylistModel(url: url)
            
            // Check if the master playlist contains a valid stream list
            if let streamList = masterPlaylist.masterPlaylist?.xStreamList, streamList.count != 0 {
                // Take the first variant's URL from the stream list
                if let variant = streamList.xStreamInf(at: 0),
                   let variantURL = variant.m3u8URL() {
                    parseVariantURL(variantURL) { result in
                        switch result {
                        case .success(let contentID):
                            completion(.success(contentID)) // Pass the contentID back
                        case .failure(let error):
                            completion(.failure(error)) // Pass the error back
                        }
                    }
                } else {
                    completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No variant URL found."])))
                }
            } else {
                completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No variants found in master playlist."])))
            }
        } catch {
            completion(.failure(error)) // Pass the error back if something went wrong
        }
    }
    
    static func parseVariantURL(_ variantURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: variantURL) { data, response, error in
            // Handle network errors
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Ensure valid data
            guard let data = data, let rawText = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load or decode playlist."])))
                return
            }
            
            // Process the M3U8 content
            let lines = rawText.components(separatedBy: .newlines)
            for line in lines {
                // Look for #EXT-X-KEY and extract the URI
                if line.starts(with: "#EXT-X-KEY"), let uriRange = line.range(of: "URI=\"") {
                    let keyURI = line[uriRange.upperBound...].split(separator: "\"").first ?? ""
                    if let contentID = extractIDFromURI(uri: String(keyURI)) {
                        completion(.success(contentID))
                        return
                    }
                }
            }
            
            // No Content ID found
            completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Content ID found in the playlist."])))
        }
        
        task.resume() // Start the network task
    }
    
    // Helper function to extract contentID from URI
    static func extractIDFromURI(uri: String) -> String? {
        if uri.hasPrefix("skd://") {
            return uri // Retain the full URI with skd:// prefix
        }
        return nil
    }
}
