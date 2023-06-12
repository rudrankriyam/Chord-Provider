//
//  SongView.swift
//  Chord Provider
//
//  © 2022 Nick Berendsen
//

import SwiftUI

/// The Song View
struct SongView: View {
    /// The ``Song``
    let song: Song
    /// The scale factor of the `View`
    @SceneStorage("scale") var scale: Double = 1.2
    /// Pinch to zoom gesture
    var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = scale * value
                if 0.8...2.0 ~= newScale {
                    scale = newScale
                }
            }
    }
    /// The body of the `View`
    var body: some View {
        ScrollView {
            SongRenderView(song: song, scale: scale)
                .gesture(magnificationGesture)
                .background {
                    RoundedRectangle(cornerRadius: 6 * scale, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(radius: 2)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
