//
//  PreviewView.swift
//  SongPro Editor
//
//  Created by Brian Kelly on 6/29/20.
//  Copyright © 2020 SongPro. All rights reserved.
//

import SwiftUI
import WebKit

struct HtmlView: NSViewRepresentable {
    
    var html: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        webView.setValue(true, forKey: "allowsMagnification")
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        //let song = ChordPro.parse(text)
        //let html = buildHtml(song: song)
        webView.loadHTMLString(html, baseURL: nil)
    }



    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

func GetAccentColor() -> String {
    return NSColor.controlAccentColor.hexString
}
func GetHighlightColor() -> String {
    return NSColor.controlAccentColor.hexString + "33"
}

func AAGetHighlightColor() -> String {
    return NSColor.selectedControlColor.hexString
}

extension NSColor {
    var hexString: String{
        let rgbColor = usingColorSpace(.extendedSRGB) ?? NSColor(red: 1, green: 1, blue: 1, alpha: 1)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let rgb:Int = (Int)(red*255)<<16 | (Int)(green*255)<<8 | (Int)(blue*255)<<0
        return String(format: "#%06x", rgb)
    }
}
