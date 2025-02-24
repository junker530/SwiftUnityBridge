//
//  MusicPlayerlistManager.swift
//  CustomCirclePicker
//
//  Created by Shota Sakoda on 2025/02/12.
//

import SwiftUI
import MediaPlayer

struct MusicItem: Identifiable, Equatable {
    let id: String
    let assetURL: URL?
    let title: String
    let artist: String
    let artwork: MPMediaItemArtwork?
    let mediaItem: MPMediaItem  // 追加：元のMPMediaItemを保持
    
    init(from mediaItem: MPMediaItem) {
        self.id = mediaItem.persistentID.description
        self.assetURL = mediaItem.assetURL
        self.title = mediaItem.title ?? "Unknown Title"
        self.artist = mediaItem.artist ?? "Unknown Artist"
        self.artwork = mediaItem.artwork
        self.mediaItem = mediaItem
    }
}

class MusicPlaylistManager: ObservableObject {
    @Published var playlists: [MPMediaPlaylist] = []
    @Published var currentPlaylist: [MusicItem] = []
    @Published var authorizationStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    @Published var currentPlaylistId: MPMediaEntityPersistentID? = nil
    
    init() {
        checkAuthorization()
    }
    
    func checkAuthorization() {
        authorizationStatus = MPMediaLibrary.authorizationStatus()
        
        switch authorizationStatus {
        case .authorized:
            fetchPlaylists()
        case .notDetermined:
            MPMediaLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    self?.authorizationStatus = status
                    if status == .authorized {
                        self?.fetchPlaylists()
                    }
                }
            }
        default:
            break
        }
    }
    
    func fetchPlaylists() {
        let playlistQuery = MPMediaQuery.playlists()
        if let playlists = playlistQuery.collections as? [MPMediaPlaylist] {
            self.playlists = playlists
        }
    }
    
    func loadPlaylist(_ playlist: MPMediaPlaylist) {
        currentPlaylistId = playlist.persistentID
        let items = playlist.items.map { mediaItem -> MusicItem in
            let item = MusicItem(from: mediaItem)
            if item.assetURL == nil {
                print("Warning: Asset URL not available for song: \(item.title)")
                print("Is cloud item: \(mediaItem.isCloudItem)")
                print("Has protected asset: \(mediaItem.hasProtectedAsset)")
            }
            return item
        }
        
        DispatchQueue.main.async {
            self.currentPlaylist = items
        }
    }
}
