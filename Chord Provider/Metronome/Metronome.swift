//
//  Metronome.swift
//  Chord Provider
//
//  © 2023 Nick Berendsen
//

import Foundation
import AVFoundation

/// The observable metronome for Chord Provider
final class Metronome: ObservableObject {
    /// The time signature
    var time: String = "4/4" {
        didSet {
            timeSignature = Int(time.prefix(1)) ?? 4
        }
    }
    /// The current BPM of the metronome
    var bpm: Float = 60.0 {
        didSet {
            bpm = min(300.0, max(30.0, bpm))
        }
    }
    /// Bool if the metronome ticker is enabled
    @Published var enabled: Bool = false {
        didSet {
            if enabled {
                nextTick = DispatchTime.now()
                tick()
            } else {
                /// Reset the animation and counter
                flip = true
                tickCounter = 1
            }
        }
    }
    /// Bool for the high/low tick and animation
    @Published var flip: Bool = true
    /// Timing for the next 'tick'
    private var nextTick: DispatchTime = DispatchTime.distantFuture
    /// timeSignature
    private var timeSignature: Int = 4
    /// tickCounter
    private var tickCounter: Int = 1
    /// The ID of the 'low' sound
    private var lowSoundID: SystemSoundID = 1
    /// The ID of the 'low' sound
    private var highSoundID: SystemSoundID = 2

    /// Init the class
    init() {
        if let fileURL = Bundle.main.url(forResource: "Low", withExtension: "aif") {
            AudioServicesCreateSystemSoundID(fileURL as CFURL, &lowSoundID)
        }
        if let fileURL = Bundle.main.url(forResource: "High", withExtension: "aif") {
            AudioServicesCreateSystemSoundID(fileURL as CFURL, &highSoundID)
        }
    }

    /// Play the metrome 'tick' as a system sound
    private func tick() {
        guard
            enabled,
            nextTick <= DispatchTime.now()
        else {
            return
        }
        let interval: TimeInterval = 60.0 / TimeInterval(bpm)
        // swiftlint:disable:next shorthand_operator
        nextTick = nextTick + interval
        DispatchQueue.main.asyncAfter(deadline: nextTick) { [weak self] in
            self?.tick()
        }
        /// Animation
        flip.toggle()
        /// Play the tick
        AudioServicesPlaySystemSound(tickCounter == 1 ? lowSoundID : highSoundID)
        /// Update the counter
        tickCounter = tickCounter < timeSignature ? tickCounter + 1 : 1
    }
}
