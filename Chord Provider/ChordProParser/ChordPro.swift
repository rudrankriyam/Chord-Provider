//
//  ChordPro.swift
//  Chord Provider
//
//  © 2023 Nick Berendsen
//

import SwiftUI
import SwiftlyChordUtilities

/// The `ChordPro` file parser
enum ChordPro {

    // MARK: Parse a 'ChordPro' file

    /// Parse a ChordPro file
    /// - Parameters:
    ///   - text: The text of the file
    ///   - transponse: The optional transpose of the song
    /// - Returns: A ``Song`` item
    static func parse(text: String, transpose: Int, instrument: Instrument) -> Song {
        /// Start with a fresh song
        var song = Song(instrument: instrument)
        /// Add the optional transpose
        song.transpose = transpose
        /// And add the first section
        var currentSection = Song.Section(id: song.sections.count + 1)
        /// Parse each line of the text:
        for text in text.components(separatedBy: .newlines) {
            switch text.trimmingCharacters(in: .whitespaces).prefix(1) {
            case "{":
                /// Directive
                processDirective(text: text, song: &song, currentSection: &currentSection)
            case "|":
                /// Tab or Grid
                if text.starts(with: "|-") || currentSection.type == .tab {
                    /// Tab
                    processTab(text: text, song: &song, currentSection: &currentSection)
                } else {
                    /// Grid
                    processGrid(text: text, song: &song, currentSection: &currentSection)
                }
            case "":
                /// Empty line; add an empty line in the section
                if !currentSection.lines.isEmpty {
                    /// Start with a fresh line:
                    var line = Song.Section.Line(id: currentSection.lines.count + 1)
                    /// Add an empty part
                    /// - Note: Use a 'space' as text
                    let part = Song.Section.Line.Part(id: 1, chord: nil, text: " ")
                    line.parts.append(part)
                    currentSection.lines.append(line)
                }
            case "#":
                /// A remark; just ignore it
                break
            default:
                switch currentSection.type {
                case .tab:
                    /// A tab can start with '|--02-3-4|', but also with 'E|--2-3-4| for example
                    processTab(text: text, song: &song, currentSection: &currentSection)
                case .strum:
                    processStrum(text: text, song: &song, currentSection: &currentSection)
                default:
                    /// Anything else
                    processLine(text: text, song: &song, currentSection: &currentSection)
                }
            }
        }
        /// Close the last section if needed
        if !currentSection.lines.isEmpty {
            song.sections.append(currentSection)
        }
        /// Set the first chord as key if not set manual
        if song.key == nil {
            song.key = song.chords.first
        }
        /// All done!
        return song
    }

    // MARK: Process a directive

    /// Process a directive
    /// - Parameters:
    ///   - text: The text to process
    ///   - song: The `Song`
    ///   - currentSection: The current `section` of the `song`
    private static func processDirective(
        text: String,
        song: inout Song,
        currentSection: inout Song.Section
    ) {

        if let match = text.wholeMatch(of: directiveRegex) {

            let directive = match.1
            let label = match.2

            switch directive {

                // MARK: Meta-data directives

            case .t, .title:
                song.title = label
            case .st, .subtitle, .artist:
                song.artist = label
            case .capo:
                song.capo = label
            case .time:
                song.time = label
            case .key:
                if let label, var chord = ChordDefinition(name: label, instrument: song.instrument) {
                    /// Transpose the key if needed
                    if song.transpose != 0 {
                        chord.transpose(transpose: song.transpose, scale: chord.root)
                    }
                    song.key = chord
                }
            case .tempo:
                song.tempo = label
            case .year:
                song.year = label
            case .album:
                song.album = label

                // MARK: Formatting directives

            case .c, .comment:
                if let label {
                    /// Start with a new line
                    var line = Song.Section.Line(id: currentSection.lines.count + 1)
                    line.comment = label
                    switch currentSection.type {
                    case .none:
                        /// A comment in its own section
                        processSection(
                            label: Environment.comment.rawValue,
                            type: Environment.comment,
                            song: &song,
                            currentSection: &currentSection
                        )
                        currentSection.lines.append(line)
                        song.sections.append(currentSection)
                        currentSection = Song.Section(id: song.sections.count + 1)
                    default:
                        /// An inline comment, e.g. inside a verse or chorus
                        currentSection.lines.append(line)
                    }
                }

                // MARK: Environment directives

                /// ## Start of Chorus
            case .soc, .startOfChorus:
                processSection(
                    label: label ?? Environment.chorus.rawValue,
                    type: .chorus,
                    song: &song,
                    currentSection: &currentSection
                )

                /// ## Repeat Chorus
            case .chorus:
                processSection(
                    label: label ?? Environment.repeatChorus.rawValue,
                    type: .repeatChorus,
                    song: &song,
                    currentSection: &currentSection
                )
                song.sections.append(currentSection)
                currentSection = Song.Section(id: song.sections.count + 1)

                /// ## Start of Verse
            case .sov, .startOfVerse:
                processSection(
                    label: label ?? Environment.verse.rawValue,
                    type: .verse,
                    song: &song,
                    currentSection: &currentSection
                )

                /// ## Start of Bridge
            case .sob, .startOfBridge:
                processSection(
                    label: label ?? Environment.bridge.rawValue,
                    type: .bridge,
                    song: &song,
                    currentSection: &currentSection
                )

                /// ## Start of Tab
            case .sot, .startOfTab:
                processSection(
                    label: label ?? Environment.tab.rawValue,
                    type: .tab,
                    song: &song,
                    currentSection: &currentSection
                )

                /// ## Start of Grid
            case .sog, .startOfGrid:
                processSection(
                    label: label ?? Environment.grid.rawValue,
                    type: .grid,
                    song: &song,
                    currentSection: &currentSection
                )

                /// ## Start of Strum
            case .sos, .startOfStrum:
                processSection(
                    label: label ?? Environment.strum.rawValue,
                    type: .strum,
                    song: &song,
                    currentSection: &currentSection
                )

                /// # End of environment
            case .eoc, .endOfChorus, .eov, .endOfVerse, .eob, .endOfBridge, .eot, .endOfTab, .eog, .endOfGrid, .eos, .endOfStrum:
                processSection(
                    label: Environment.none.rawValue,
                    type: .none,
                    song: &song,
                    currentSection: &currentSection
                )

                // MARK: Chord diagrams
            case .define:
                if let label {
                    processDefine(text: label, song: &song)
                }

                // MARK: Custom directives
            case .musicPath:
                if let label {
                    song.musicPath = label
                }
            case .tag:
                if let label {
                    song.tags.append(label.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
    }

    // MARK: Process a section

    /// Process a section
    /// - Parameters:
    ///   - label: The label of the `section`
    ///   - type: The type of `section`
    ///   - song: The `song`
    ///   - currentSection: The current `section` of the `song`
    private static func processSection(label: String, type: Environment, song: inout Song, currentSection: inout Song.Section) {
        if currentSection.lines.isEmpty {
            /// There is already an empty section
            currentSection.type = type
            currentSection.label = label
        } else {
            /// Make a new section
            song.sections.append(currentSection)
            currentSection = Song.Section(id: song.sections.count + 1)
            currentSection.type = type
            currentSection.label = label
        }
    }

    // MARK: Process a chord definition

    /// Process a chord definition
    /// - Parameters:
    ///   - text: The chord definition
    ///   - song: The `song`
    private static func processDefine(text: String, song: inout Song) {
        if var definedChord = ChordDefinition(definition: text, instrument: song.instrument, status: .unknown) {
            definedChord.status = song.transpose == 0 ? definedChord.status : .customTransposed
            /// Update a standard chord with the same name if there is one in the chords list
            if let index = song.chords.firstIndex(where: {
                $0.name == definedChord.name &&
                ($0.status == .standard || $0.status == .transposed)
            }) {
                /// Use the same ID as the standard chord
                definedChord.id = song.chords[index].id
                song.chords[index] = definedChord
            } else {
                /// Add the chord as a new definition
                song.chords.append(definedChord)
            }
        }
    }

    // MARK: Process a tab environment

    /// Process a tab environment
    /// - Parameters:
    ///   - text: The text to process
    ///   - song: The `Song`
    ///   - currentSection: The current `section` of the `song`
    private static func processTab(text: String, song: inout Song, currentSection: inout Song.Section) {
        /// Start with a fresh line
        var line = Song.Section.Line(id: currentSection.lines.count + 1)
        line.tab = text.trimmingCharacters(in: .whitespacesAndNewlines)
        currentSection.lines.append(line)
        /// Mark the section as Tab if not set
        if currentSection.type == .none {
            currentSection.type = .tab
            currentSection.label = Environment.tab.rawValue
        }
    }

    // MARK: Process a grid environment

    /// Process a grid environment
    /// - Parameters:
    ///   - text: The text to process
    ///   - song: The `Song`
    ///   - currentSection: The current `section` of the `song`
    private static func processGrid(text: String, song: inout Song, currentSection: inout Song.Section) {
        /// Start with a fresh line:
        var line = Song.Section.Line(id: currentSection.lines.count + 1)
        /// Give the structs an ID
        var partID: Int = 1
        /// Seperate the grids
        let grids = text.replacingOccurrences(of: " ", with: "").split(separator: "|")
        for text in grids where !text.isEmpty {
            var grid = Song.Section.Line.Grid(id: partID)
            /// Process like a 'normal' line'
            var matches = text.matches(of: lineRegex)
            matches = matches.dropLast()
            for match in matches {
                let (_, chord, spacer) = match.output
                if let chord {
                    let result = processChord(chord: String(chord), song: &song)
                    /// Add it as chord
                    grid.parts.append(Song.Section.Line.Part(id: partID, chord: result.id))
                    partID += 1
                }

                if let spacer {
                    /// Add it as spacer
                    for _ in spacer {
                        grid.parts.append(Song.Section.Line.Part(id: partID, chord: nil, text: "."))
                        partID += 1
                    }
                }
            }
            line.grid.append(grid)
        }
        currentSection.lines.append(line)
        /// Mark the section as Grid if not set
        if currentSection.type == .none {
            currentSection.type = .grid
            currentSection.label = Environment.grid.rawValue
        }
    }

    // MARK: Process a strum environment

    /// Process a strum environment
    /// - Parameters:
    ///   - text: The text to process
    ///   - song: The `Song`
    ///   - currentSection: The current `section` of the `song`
    private static func processStrum(text: String, song: inout Song, currentSection: inout Song.Section) {
        /// Start with a fresh line
        var line = Song.Section.Line(id: currentSection.lines.count + 1)

        var pattern = ""
        var bottom = ""

        for(index, character) in text.trimmingCharacters(in: .whitespacesAndNewlines).enumerated() {
            let value = Song.Section.Line.strumCharacterDict[String(character)]
            pattern += value ?? String(character)
            if (index % 2) == 0 {
                bottom += "=="
            } else {
                pattern += " "
                bottom += " "
            }
        }
        line.strum.append(pattern)
        line.strum.append(bottom)
        currentSection.lines.append(line)
    }

    // MARK: Process a line

    /// Process a line
    /// - Parameters:
    ///   - text: The text to process
    ///   - song: The `Song`
    ///   - currentSection: The current `section` of the `song`
    private static func processLine(text: String, song: inout Song, currentSection: inout Song.Section) {
        /// Start with a fresh line:
        var line = Song.Section.Line(id: currentSection.lines.count + 1)
        var partID: Int = 1

        var matches = text.matches(of: lineRegex)
        /// The last match is the newline character so completely empty; we don't need it
        matches = matches.dropLast()
        for match in matches {
            let (_, chord, lyric) = match.output
            var part = Song.Section.Line.Part(id: partID)
            if let chord {
                part.chord = processChord(chord: String(chord), song: &song).id
                part.text = " "
                /// Because it has a chord; it should be at least a verse
                if currentSection.type == .none {
                    currentSection.type = .verse
                    currentSection.label = Environment.verse.rawValue
                }
            }
            if let lyric {
                /// See https://stackoverflow.com/questions/31534742/space-characters-being-removed-from-end-of-string-uilabel-swift
                /// for the funny stuff added to the string...
                part.text = String(lyric + "\u{200c}")
            }
            if !(part.empty) {
                partID += 1
                line.parts.append(part)
            }
        }
        currentSection.lines.append(line)
    }

    // MARK: Process a chord

    /// Process a chord
    /// - Parameters:
    ///   - chord: The `chord` as String
    ///   - song: The `Song`
    /// - Returns: The processed `chord` as String
    private static func processChord(chord: String, song: inout Song) -> ChordDefinition {
        /// Check if this chord is already parsed
        if  let match = song.chords.last(where: { $0.name == chord }) {
            return match
        }
        /// Try to find it in the database
        if var databaseChord = ChordDefinition(name: chord, instrument: song.instrument) {
            if song.transpose != 0 {
                databaseChord.transpose(transpose: song.transpose, scale: song.key?.root ?? .c)
                /// Keep the original name
                databaseChord.name = chord
            }
            song.chords.append(databaseChord)
            return databaseChord
        }
        let unknownChord = ChordDefinition(unknown: chord, instrument: song.instrument)
        song.chords.append(unknownChord)
        return unknownChord
    }
}
