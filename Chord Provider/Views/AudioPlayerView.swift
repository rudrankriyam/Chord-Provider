//
//  AudioPlayerView.swift
//  Chord Provider
//
//  © 2023 Nick Berendsen
//

import SwiftUI
import AVKit
import SwiftlyFolderUtilities
import SwiftlyAlertMessage

/// SwiftUI `View` for the audio player
struct AudioPlayerView: View {
    /// The music URL
    let musicURL: URL
    /// The `AVAudioPlayer`
    @State private var audioPlayer: AVAudioPlayer?
    /// Bool if the player is playing or not
    @State private var isPlaying: Bool = false
    /// The FileBrowser model
    @EnvironmentObject var fileBrowser: FileBrowser
    /// The status of the song
    @State private var status: Status = .unknown
    /// The iCloud URL of the song
    private var iCloudURL: URL {
        let hiddenFile = ".\(musicURL.lastPathComponent).icloud"
        return musicURL.deletingLastPathComponent().appending(path: hiddenFile)
    }
    /// Show an `Alert` if the music file is not found
    @State private var errorAlert: AlertMessage?
    /// Show an `ConfirmationDialog` if the music file is not downloaded
    @State private var confirmationDialog: AlertMessage?

    // MARK: Body of the View

    /// The body of the `View`
    var body: some View {
        HStack {
            playButton
            if status == .ready {
                pauseButton
            } else {
                Button(
                    action: {
                        switch status {
                        case .songNotDownloaded:
                            confirmationDialog = Status.songNotDownloaded.alert {
                                Task {
                                    await downloadSong()
                                }
                            }
                        default:
                            errorAlert = status.alert()
                        }
                    },
                    label: {
                        status.icon
                    }
                )
            }
        }
        .errorAlert(message: $errorAlert)
        .confirmationDialog(message: $confirmationDialog)
        .animation(.default, value: status)
        .buttonStyle(.bordered)
        .task(id: musicURL) {
            await checkSong()
        }
        .task(id: fileBrowser.songsFolder) {
            await checkSong()
        }
    }

    // MARK: Additional View parts

    /// The play button
    @ViewBuilder var playButton: some View {
        Button(
            action: {
                Task {
                    try? await FolderBookmark.action(bookmark: FileBrowser.bookmark) { _ in
                        playSong()
                    }
                }
            },
            label: {
                Image(systemName: "play.fill")
            }
        )
        .disabled(status != .ready)
    }

    /// The pause button
    @ViewBuilder var pauseButton: some View {
        Button(
            action: {
                if audioPlayer?.isPlaying == true {
                    audioPlayer?.pause()
                } else {
                    audioPlayer?.play()
                }
            },
            label: {
                Image(systemName: "pause.fill")
            }
        )
        .disabled(!isPlaying)
    }

    // MARK: Prive functions

    /// Check the song file
    @MainActor private func checkSong() async {
        do {
            try await FolderBookmark.action(bookmark: FileBrowser.bookmark) { _ in
                if musicURL.exist() {
                    status = .ready
                } else {
                    if iCloudURL.exist() {
                        status = .songNotDownloaded
                    } else {
                        status = .songNotFound
                    }
                }
            }
        } catch {
            status = .noFolderSelected
        }
    }

    /// Play the song file
    private func playSong() {
        do {
            if isPlaying {
                audioPlayer?.stop()
                audioPlayer = AVAudioPlayer.init()
            }
            audioPlayer = try AVAudioPlayer(contentsOf: musicURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            /// For the button state
            isPlaying = true
        } catch {
            errorAlert = Status.songNotFound.alert()
        }
    }

    /// Download the song
    private func downloadSong() async {
        try? await FolderBookmark.action(bookmark: FileBrowser.bookmark) { _ in
            do {
                try FileManager.default.startDownloadingUbiquitousItem(at: iCloudURL )
            } catch {
                print(error.localizedDescription)
            }
            while status != .ready {
                try? await Task.sleep(nanoseconds: 100000000)
                await checkSong()
            }
        }
    }
}
