---Documentation for ChloeSpaceOut's Imortalized Piano Avatar
---@class ChloePianoAPI
local ChloePianoAPI = {}

--- Piano UUID "943218fd-5bbc-4015-bf7f-9da4f37bac59"

---@class ConcatinatedVector3 : string

---@alias keyID string
---| "A0"
---| "A\x230"
---| "B0"
---
---| "C1"
---| "C\x231"
---| "D1"
---| "D\x231"
---| "E1"
---| "F1"
---| "F\x231"
---| "G1"
---| "G\x231"
---| "A1"
---| "A\x231"
---| "B1"
---
---| "C2"
---| "C\x232"
---| "D2"
---| "D\x232"
---| "E2"
---| "F2"
---| "F\x232"
---| "G2"
---| "G\x232"
---| "A2"
---| "A\x232"
---| "B2"
---
---| "C3"
---| "C\x233"
---| "D3"
---| "D\x233"
---| "E3"
---| "F3"
---| "F\x233"
---| "G3"
---| "G\x233"
---| "A3"
---| "A\x233"
---| "B3"
---
---| "C4"
---| "C\x234"
---| "D4"
---| "D\x234"
---| "E4"
---| "F4"
---| "F\x234"
---| "G4"
---| "G\x234"
---| "A4"
---| "A\x234"
---| "B4"
---
---| "C5"
---| "C\x235"
---| "D5"
---| "D\x235"
---| "E5"
---| "F5"
---| "F\x235"
---| "G5"
---| "G\x235"
---| "A5"
---| "A\x235"
---| "B5"
---
---| "C6"
---| "C\x236"
---| "D6"
---| "D\x236"
---| "E6"
---| "F6"
---| "F\x236"
---| "G6"
---| "G\x236"
---| "A6"
---| "A\x236"
---| "B6"


---The playNote() function just plays a note on the piano when run. It contains the following:  
---`pianoID` is a string containing the ID of the selected piano. E.g. "{1, 65, -102}". The ID is determined by the player head coordinates. To easily grab the ID, run tostring(pos) where pos is a vec3 of the selected piano head position.  
---`keyID` is a string containing the ID of the note that should play. E.g. "C2","F#3","A0" This is just standard notation formatting of note as a letter, followed by octave as a number.  
---`doesPlaySound` is a boolean which determines if a sound will play when the note is pressed. This exists to make the implementation for holding notes simple. Just keep this as true.  
---`notePos` is a vec3 containing the world coordinates the note should play at. If left empty, it will just play at. You can simply ignore this and it will play at the player head coordinates. This is rarely useful, but if you want you can use the piano as a piano sample library (assuming you have it loaded), and play piano sounds anywhere in the world.  
---@param pianoID ConcatinatedVector3
---@param keyId keyID
---@param doesPlaySound boolean
---@param notePos Vector3?
function ChloePianoAPI.playNote(pianoID, keyId, doesPlaySound, notePos)
end

---@param pianoID ConcatinatedVector3
---@return boolean
function ChloePianoAPI.validPos(pianoID) return false end

---@param keyID keyID
---@param notePos Vector3
---@param noteVolume number?
function ChloePianoAPI.playSound(keyID, notePos, noteVolume) end

---@return table<keyID,integer>
function ChloePianoAPI.getPlayingKeys() return {} end