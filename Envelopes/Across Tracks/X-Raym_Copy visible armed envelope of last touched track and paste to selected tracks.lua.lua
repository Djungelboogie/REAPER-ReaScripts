--[[
 * ReaScript Name: Copy visible armed envelope of last touched tracks and paste to selected tracks
 * Description: A way to copy paste envelopes across tracks.
 * Instructions: Make a track selection. Touch a track. Have sure you have source and destination envelope armed and visible. It will copy point from source to destination if envelope name match.
 * Author: X-Raym
 * Author URl: http://extremraym.com
 * Repository: GitHub > X-Raym > EEL Scripts for Cockos REAPER
 * Repository URl: https://github.com/X-Raym/REAPER-EEL-Scripts
 * File URl: https://github.com/X-Raym/REAPER-EEL-Scripts/scriptName.eel
 * Licence: GPL v3
 * Forum Thread: Script (LUA): Copy points envelopes in time selection and paste them at edit cursor
 * Forum Thread URl: http://forum.cockos.com/showthread.php?p=1497832#post1497832
 * Version: 1.1
 * Version Date: 2015-03-18
 * REAPER: 5.0 pre 18b
 * Extensions: None
 --]]
 
--[[
 * Changelog:
 * v1.1 (2015-03-18)
	+ Select new points
	+ Redraw envelope value at cursor pos in TCP (thanks to HeDa!)
 * v1.0 (2015-03-17)
	+ Initial release
 --]]

-- ----- DEBUGGING ====>
--[[
local info = debug.getinfo(1,'S');

local full_script_path = info.source

local script_path = full_script_path:sub(2,-5) -- remove "@" and "file extension" from file name

if reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32" then
  package.path = package.path .. ";" .. script_path:match("(.*".."\\"..")") .. "..\\Functions\\?.lua"
else
  package.path = package.path .. ";" .. script_path:match("(.*".."/"..")") .. "../Functions/?.lua"
end

require("X-Raym_Functions - console debug messages")


debug = 1 -- 0 => No console. 1 => Display console messages for debugging.
clean = 1 -- 0 => No console cleaning before every script execution. 1 => Console cleaning before every script execution.

msg_clean()]]
-- <==== DEBUGGING -----

-- INIT
time = {}
valueSource = {}
shape = {}
tension = {}
selectedOut = {}

function main() -- local (i, j, item, take, track)

	-- GET AND UNSELECT LAST TRACK
	last_track = reaper.GetLastTouchedTrack()
	if reaper.IsTrackSelected(last_track) == true then
		reaper.SetTrackSelected(last_track, false)
		restore_sel = true
	end -- ENFIF last track is selected

	reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

	-- LOOP THROUGH LAST TOUCHED TRACK ENVELOPES
	env_count = reaper.CountTrackEnvelopes(last_track)
	for j = 0, env_count-1 do

		-- GET THE ENVELOPE
		env = reaper.GetTrackEnvelope(last_track, j)
		retval, env_name = reaper.GetEnvelopeName(env, "")

		-- IF VISIBLE AND ARMED
		retval, strNeedBig = reaper.GetEnvelopeStateChunk(env, "", true)
		x, y = string.find(strNeedBig, "VIS 1")
		w, z = string.find(strNeedBig, "ARM 1")

		if x ~= nil and w ~= nil then
			
			-- SAVE LAST TOUCHED TRACK ENVELOPES POINTS
			env_points_count = reaper.CountEnvelopePoints(env)

			if env_points_count > 0 then

				-- LOOP THROUGH POINTS
				for k = 0, env_points_count-1 do 

					retval, time[k], valueSource[k], shape[k], tension[k], selectedOut[k] = reaper.GetEnvelopePoint(env, k)
				
				end -- ENDIF points on the envelope

			end -- ENDIF there was envelope envelope point

			-- LOOP TRHOUGH SELECTED TRACKS
			selected_tracks_count = reaper.CountSelectedTracks(0)
			for i = 0, selected_tracks_count-1  do
				
				-- GET THE TRACK
				track = reaper.GetSelectedTrack(0, i) -- Get selected track i

				env_count = reaper.CountTrackEnvelopes(track)
				for m = 0, env_count-1 do

					-- GET THE ENVELOPE
					env_dest = reaper.GetTrackEnvelope(track, m)
					retval, env_name_dest = reaper.GetEnvelopeName(env_dest, "")

					-- IF VISIBLE AND ARMED
					retval, strNeedBig_dest = reaper.GetEnvelopeStateChunk(env_dest, "", true)
					a, c = string.find(strNeedBig_dest, "VIS 1")
					b, d = string.find(strNeedBig_dest, "ARM 1")

					if a ~= nil and b ~= nil and env_name_dest == env_name then

						-- GET LAST POINT TIME OF DEST TRACKS AND DELETE ALL
						env_points_count_dest = reaper.CountEnvelopePoints(env_dest)

						retval_last, time_last, valueSource_last, shape_last, tension_last, selectedOut_last = reaper.GetEnvelopePoint(env_dest, env_points_count_dest-1)

						reaper.DeleteEnvelopePointRange(env_dest, 0, time_last+1)

						-- LOOP IN STORED POINTS AND INSERT
						for p = 0, env_points_count-1 do
							
							reaper.InsertEnvelopePoint(env_dest, time[p], valueSource[p], shape[p], tension[p], true, true)

						end -- END LOOP THROUGH SAVED POINTS

					end -- ENDIF envelope passed

					reaper.Envelope_SortPoints(env_dest)

				end -- ENDLOOP selected tracks envelope
			
			end -- ENDLOOP selected tracks

		end -- ENFIF visible
		
	end -- ENDLOOP through envelopes

	-- RESTORE LAST TRACK SELECTION
	if restore_sel == true then
		reaper.SetTrackSelected(last_track, true)
	end

	reaper.Undo_EndBlock("Copy visible armed envelope of last touched tracks and paste to selected tracks", 0) -- End of the undo block. Leave it at the bottom of your main function.

end -- end main()

--msg_start() -- Display characters in the console to show you the begining of the script execution.

--[[ reaper.PreventUIRefresh(1) ]]-- Prevent UI refreshing. Uncomment it only if the script works.

--reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SAVE_CURSOR_POS_SLOT_8"), 0)

main() -- Execute your main function

--[[ reaper.PreventUIRefresh(-1) ]] -- Restore UI Refresh. Uncomment it only if the script works.

--reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_RESTORE_CURSOR_POS_SLOT_8"), 0)

reaper.UpdateArrange() -- Update the arrangement (often needed)

--msg_end() -- Display characters in the console to show you the end of the script execution.

-- BEWARE OF CTRL+Z as last touched track will Change

-- Update the TCP envelope value at edit cursor position
function HedaRedrawHack()
	reaper.PreventUIRefresh(1)

	track=reaper.GetTrack(0,0)

	trackparam=reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT")	
	if trackparam==0 then
		reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 1)
	else
		reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 0)
	end
	reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", trackparam)

	reaper.PreventUIRefresh(-1)
	
end

HedaRedrawHack()