//
//  M3U8Util.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 20/11/24.
//

import Foundation

import M3U8Kit

public class M3U8Parser {
    
    public static func extractContentID(url: URL, playlistModel: M3U8PlaylistModel? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        let processPlaylist = { (model: M3U8PlaylistModel) in
            // Check if the master playlist contains a valid stream list
            if let streamList = model.masterPlaylist?.xStreamList, streamList.count != 0 {
                // Take the first variant's URL from the stream list
                if let variant = streamList.xStreamInf(at: 0),
                   let variantURL = variant.m3u8URL() {
                    parseVariantURL(variantURL) { result in
                        completion(result)
                    }
                } else {
                    completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No variant URL found."])))
                }
            } else {
                completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No variants found in master playlist."])))
            }
        }

        if let model = playlistModel {
            processPlaylist(model)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let model = try M3U8PlaylistModel(url: url)
                processPlaylist(model)
            } catch {
                completion(.failure(error))
            }
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
    
    public static func parseQualities(from url: URL, completion: @escaping (Result<([VideoQuality], M3U8PlaylistModel), Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let playlistModel = try M3U8PlaylistModel(url: url)
                var qualities: [VideoQuality] = []
                
                if let streamList = playlistModel.masterPlaylist?.xStreamList {
                    for i in 0..<streamList.count {
                        if let extXStreamInf = streamList.xStreamInf(at: i) {
                            let resolution = "\(Int(extXStreamInf.resolution.height))p"
                            let bitrate = Double(extXStreamInf.bandwidth)
                            qualities.append(VideoQuality(resolution: resolution, bitrate: bitrate))
                        }
                    }
                }
                
                let sortedQualities = qualities.sorted { $0.bitrate < $1.bitrate }
                DispatchQueue.main.async {
                    completion(.success((sortedQualities, playlistModel)))
                }
            } catch {
                print("Error parsing manifest for qualities: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
