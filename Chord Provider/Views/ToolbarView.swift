//
//  ToolbarView.swift
//  Chord Provider
//
//  © 2023 Nick Berendsen
//

import SwiftUI
import SwiftlyFolderUtilities

/// SwiftUI `View` for the toolbar
struct ToolbarView: View {
    /// The app state
    @EnvironmentObject private var appState: AppState
    /// The scene state
    @EnvironmentObject private var sceneState: SceneState
    /// Bool to show the editor or not
    @SceneStorage("showEditor") var showEditor: Bool = false
    /// The body of the `View`
    var body: some View {
        Group {
            Button(action: {
                sceneState.song.transpose -= 1
            }, label: {
                Label("♭", systemImage: sceneState.song.transpose < 0 ? "arrow.down.circle.fill" : "arrow.down.circle")
            })
            Button(action: {
                sceneState.song.transpose += 1
            }, label: {
                Label("♯", systemImage: sceneState.song.transpose > 0 ? "arrow.up.circle.fill" : "arrow.up.circle")
            })
            Button {
                showEditor.toggle()
            } label: {
                Label("Edit", systemImage: showEditor ? "pencil.circle.fill" : "pencil.circle")
            }
            Menu("Chords", systemImage: appState.settings.showChords ? "number.circle.fill" : "number.circle") {
                Button {
                    appState.settings.showChords.toggle()
                } label: {
                    Text(appState.settings.showChords ? "Hide Chords" : "Show Chords")
                }
                Divider()
                Picker("Position:", selection: $appState.settings.chordsPosition) {
                    ForEach(ChordProviderSettings.Position.allCases, id: \.rawValue) { value in
                        Text(value.rawValue)
                            .tag(value)
                    }
                }
                .pickerStyle(.inline)
                .disabled(appState.settings.showChords == false)
            }
            .frame(minWidth: 120)
        }
        .labelStyle(.titleAndIcon)
    }
}

extension ToolbarView {

    /// SwiftUI `View` with a slider to zoom the content
    struct ScaleSlider: View {
        /// The scene state
        @EnvironmentObject private var sceneState: SceneState
        /// The body of the `View`
        var body: some View {
            Slider(value: $sceneState.currentScale, in: 0.8...2.0) {
                Label("Zoom", systemImage: "magnifyingglass")
            }
            .labelStyle(.iconOnly)
        }
    }
}

extension ToolbarView {

    /// SwiftUI `View` with a togle to view inline diagrams
    struct ChordAsDiagram: View {
        /// The app state
        @EnvironmentObject private var appState: AppState
        /// The body of the `View`
        var body: some View {
            Toggle(isOn: $appState.settings.showInlineDiagrams) {
                Text("Chords as Diagram")
            }
        }
    }
}

extension ToolbarView {

    /// SwiftUI `View` with a picker for the song paging
    struct Pager: View {
        /// The app state
        @EnvironmentObject private var appState: AppState
        /// The body of the `View`
        var body: some View {
            Picker("Pager:", selection: $appState.settings.paging) {
                ForEach(Song.DisplayOptions.Paging.allCases, id: \.rawValue) { value in
                    value.label
                        .tag(value)
                }
            }
        }
    }
}

extension ToolbarView {

    /// SwiftUI `View` with optional player buttons
    struct PlayerButtons: View {
        /// The scene state
        @EnvironmentObject private var sceneState: SceneState
        /// The body of the `View`
        var body: some View {
            if let musicURL = getMusicURL() {
                AudioPlayerView(musicURL: musicURL)
                    .padding(.leading)
            } else {
                EmptyView()
            }
        }
        /// Get the URL for the music file
        /// - Returns: A full URL to the file, if found
        private func getMusicURL() -> URL? {
            guard let file = sceneState.file, let path = sceneState.song.musicPath else {
                return nil
            }
            var musicURL = file.deletingLastPathComponent()
            musicURL.appendPathComponent(path)
            return musicURL
        }
    }
}

extension ToolbarView {

    /// SwiftUI `View` for the folder selector
    struct FolderSelector: View {
        /// The FileBrowser model
        @StateObject var fileBrowser: FileBrowser = .shared
        /// Folder selector title
        private var folderTitle: String {
            FolderBookmark.getBookmarkL(bookmark: FileBrowser.bookmark)?.lastPathComponent ?? "Not selected"
        }
        var body: some View {
            FolderBookmark.SelectFolder(
                bookmark: FileBrowser.bookmark,
                title: folderTitle,
                systemImage: "folder"
            ) {
                Task { @MainActor in
                    await fileBrowser.getFiles()
                }
            }
        }
    }
}
