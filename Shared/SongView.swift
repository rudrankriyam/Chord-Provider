import SwiftUI

struct SongView: View {
    @Binding var song: Song
    
    @AppStorage("showEditor") var showEditor: Bool = false
    @AppStorage("showMetronome") var showMetronome: Bool = false
    @AppStorage("showChords") var showChords: Bool = true
    
    var body: some View {
        /// Stupid hack to ge the view using full height
        GeometryReader { g in
            ScrollView {
                HtmlView(html: (song.html ?? "")).frame(height: g.size.height)
            }.frame(height: g.size.height)
        }
    }
}
