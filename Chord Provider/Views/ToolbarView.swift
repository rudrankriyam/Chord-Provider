//
//  ToolbarView.swift
//  Chord Provider
//
//  © 2023 Nick Berendsen
//

import SwiftUI

/// Swiftui `View` for the toolbar
struct ToolbarView: View {
    /// The ``song``
    @Binding var song: Song
    /// Bool to show the editor or not
    @SceneStorage("showEditor")
    var showEditor: Bool = false
    /// Bool to show the chords or not
    @AppStorage("showChords")
    var showChords: Bool = true
    /// The body of the `View`
    var body: some View {
        HStack {
            Button(action: {
                song.transpose -= 1
            }, label: {
                Label("♭", systemImage: "arrow.down")
                    .foregroundColor(song.transpose < 0 ? .primary : .secondary)
            })
            Button(action: {
                song.transpose += 1
            }, label: {
                Label("♯", systemImage: "arrow.up")
                    .foregroundColor(song.transpose > 0 ? .primary : .secondary)
            })
            Button {
                showEditor.toggle()
            } label: {
                Label("Edit", systemImage: showEditor ? "pencil.circle.fill" : "pencil.circle")
            }
            Button {
                showChords.toggle()
            } label: {
                Label("Chords", systemImage: showChords ? "number.circle.fill" : "number.circle")
            }
        }
        .labelStyle(.titleAndIcon)
    }
}

extension ToolbarView {
    struct ScaleSlider: View {
        /// Current scaling of the `SongView`
        @SceneStorage("scale") var scale: Double = 1.2
        /// The body of the `View`
        var body: some View {
            Slider(value: $scale, in: 0.8...2.0) {
                Label("Zoom", systemImage: "magnifyingglass")
            }
            .labelStyle(.iconOnly)
        }
    }
}

extension ToolbarView {
    struct PlayerButtons: View {
        /// The ``Song``
        let song: Song
        /// The optional file location
        let file: URL?
        /// The body of the `View`
        var body: some View {
            if let musicURL = getMusicURL() {
                AudioPlayerView(musicURL: musicURL)
            } else {
                EmptyView()
            }
        }
        /// Get the URL for the music file
        /// - Returns: A full URL to the file, if found
        private func getMusicURL() -> URL? {
            guard let file, let path = song.musicPath else {
                return nil
            }
            var musicURL = file.deletingLastPathComponent()
            musicURL.appendPathComponent(path)
            return musicURL
        }
    }
}
