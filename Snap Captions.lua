-- Copyright (C) 2023 Orson Lord & Dan Knowlton
--
-- Snap Captions v1.2
-- This tool automates the process of creating Text+ clips from subtitle
-- clips.
--
-- If you find this tool useful, please consider donating to support its
-- development: https://bit.ly/SnapCaptions
--
-- This software can not be redistributed or sold without the express
-- permission of the authors.


local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)

local winID = "SnapCaptionsWin"

local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()
local mediaPool = project:GetMediaPool()

local fusion_titles = {}

local TEXT_TEMPLATE_FOLDER = "Snap Captions"

local platform = (FuPLATFORM_WINDOWS and "Windows") or
                 (FuPLATFORM_MAC and "Mac") or
                 (FuPLATFORM_LINUX and "Linux")

local function script_path()
    return debug.getinfo(2, "S").source:sub(2)
end


local function ScriptIsInstalled()
    local script_path = script_path()
    if platform == "Windows" then
        local match1 = script_path:find("\\Blackmagic Design\\DaVinci Resolve\\Support\\Fusion\\Scripts")
        local match2 = script_path:find("\\Blackmagic Design\\DaVinci Resolve\\Fusion\\Scripts")
        return match1 ~= nil or match2 ~= nil
    elseif platform == "Mac" then
        local match1 = script_path:find("/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts")
        return match1 ~= nil
    else
        local match1 = script_path:find("resolve/Fusion/Scripts")
        local match2 = script_path:find("resolve/Fusion/Scripts")
        local match3 = script_path:find("/DaVinciResolve/Fusion/Scripts")
        return match1 ~= nil or match2 ~= nil or match3 ~= nil
    end
end

local SCRIPT_INSTALLED = ScriptIsInstalled()

local COLUMN_WIDTH = 130
local WINDOW_WIDTH = 320
local WINDOW_HEIGHT = 356

local COMBOBOX_ACTION_BUTTON_CSS = [[
    QPushButton
    {
        border: 1px solid rgb(0,0,0);
        border-top-right-radius: 4px;
        border-bottom-right-radius: 4px;
        border-top-left-radius: 0px;
        border-bottom-left-radius: 0px;
        border-left: 0px;
        font-size: 22px;
        min-height: 26px;
        max-height: 26px;
        min-width: 26px;
        max-width: 26px;
        background-color: rgb(31,31,31);
    }
    QPushButton:hover
    {
        color: rgb(255, 255, 255);
    }
    QPushButton:pressed
    {
        background-color: rgb(20,20,20);
    }
]]
local SECTION_TITLE_CSS = [[
    QLabel
    {
        color: rgb(255, 255, 255);
        font-size: 13px;
        font-weight: bold;
    }
    QLabel:!enabled
    {
        color: rgb(150, 150, 150);
    }
]]
local BANNER_ACTION_BUTTON_CSS = [[
    QPushButton
    {
        max-height: 20px;
        min-height: 20px;
        color: rgb(200, 200, 200);
        font-size: 12px;
        min-width: 80px;
    }
]]
local PRIMARY_ACTION_BUTTON_CSS = [[
    QPushButton
    {
        border: 1px solid rgb(51,176,74);
        max-height: 28px;
        border-radius: 14px;
        background-color: rgb(51,176,74);
        color: rgb(255, 255, 255);
        min-height: 28px;
        font-size: 13px;
    }
    QPushButton:hover
    {
        border: 2px solid rgb(40,140,59);
        background-color: rgb(40,140,59);
    }
    QPushButton:pressed
    {
        border: 2px solid rgb(36,126,53);
        background-color: rgb(36,126,53);
    }
    QPushButton:!enabled
    {
        border: 2px solid rgb(36,126,53);
        background-color: rgb(36,126,53);
        color: rgb(150, 150, 150);
    }
]]
local SECONDARY_ACTION_BUTTON_CSS = [[
    QPushButton
    {
        max-height: 24px;
        min-height: 24px;
    }
]]
local DIVIDER_CSS = [[
    QFrame[frameShape="4"]
    {
        border: none;
        background-color: rgb(30, 30, 30);
        max-height: 1px;
    }
]]
local COMBOBOX_PLACEHOLDER_CSS = [[
    QLabel
    {
        color: rgb(140, 140, 140);
        font-size: 13px;
        min-height: 26px;
        max-height: 26px;
        background-color: rgb(31,31,31);
        border: 1px solid rgb(0,0,0);
        border-top-right-radius: 0px;
        border-bottom-right-radius: 0px;
        border-top-left-radius: 4px;
        border-bottom-left-radius: 4px;
        padding-left: 4px;
    }
]]

local DONATE_URL = "https://bit.ly/SnapCaptions"
local TUTORIAL_URL = "https://bit.ly/SnapCaptionsTutorial"

local timeline_type_names = {}
timeline_type_names["Timeline"] = true
timeline_type_names["タイムライン"] = true
timeline_type_names["时间线"] = true
timeline_type_names["Línea de tiempo"] = true
timeline_type_names["Linha de Tempo"] = true
timeline_type_names["Временная шкала"] = true
timeline_type_names["ไทม์ไลน์"] = true
timeline_type_names["타임라인"] = true


local function OpenURL(url)
    if bmd.openurl then
        bmd.openurl(url)
        print("[Opening URL] " .. url)
    end
end


local function ClearTable(table)
    for k in pairs(table) do
        table[k] = nil
    end
end


local function EndDispLoop()
    local win = ui:FindWindow(winID)
    if win ~= nil then
        return
    end

    disp:ExitLoop()
end


local function CreateDialog(title, message)
    local position = {nil, nil}
    local win = ui:FindWindow(winID)
    if win ~= nil then
        position = {win.Geometry[1] + 10, win.Geometry[2] + 150}
    end

    local dialog = disp:AddWindow({
        ID = "SnapCaptionsDialog",
        WindowTitle = "Snap Captions | Error",
        WindowModality = "ApplicationModal",
        Geometry = {position[1], position[2], 300, 100},
        FixedSize = {300, 100},
        Margin = 16,
        ui:VGroup
        {
            ID = "root",
            Spacing = 4,
            FixedX = 300,
            FixedY = 100,
            ui:Label
            {
                Weight = 0,
                ID = "error_title",
                Text = title,
                Alignment = { AlignHCenter = true, AlignBottom = true},
                WordWrap = true,
                StyleSheet = [[
                    QLabel {
                        color: rgb(255, 255, 255);
                        font-size: 13px;
                        font-weight: bold;
                    }
                ]]
            },
            ui:Label
            {
                Weight = 10,
                ID = "error_message",
                Text = message,
                WordWrap = true,
                Alignment = { AlignHCenter = true, AlignTop = true }
            },
            ui:VGap(0, 1),
            ui:HGroup
            {
                Weight = 0,
                ui:Button{ ID = "OK",
                            Text = "OK",
                            StyleSheet = SECONDARY_ACTION_BUTTON_CSS
                }
            }
        }
    })

    function dialog.On.OK.Clicked(ev)
        dialog:Hide()
        dialog = nil
        EndDispLoop()
    end

    function dialog.On.SnapCaptionsDialog.Close(ev)
        dialog:Hide()
        dialog = nil
        EndDispLoop()
    end

    return dialog
end


local function InstallScript()
    local source_path = script_path()
    local target_path = nil
    if platform == "Windows" then
        target_path = os.getenv("APPDATA") .. "\\Blackmagic Design\\DaVinci Resolve\\Support\\Fusion\\Scripts\\Comp\\"
    elseif platform == "Mac" then
        target_path = os.getenv("HOME") .. "/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Comp/"
    else
        target_path = os.getenv("HOME") .. "/.local/share/DaVinciResolve/Fusion/Scripts/Comp/"
    end

    local script_name = source_path:match(".*[/\\](.*)")
    target_path = target_path .. script_name

    -- Copy the file.
    local source_file = io.open(source_path, "r")
    local contents = source_file:read("*a")
    source_file:close()

    local target_file = io.open(target_path, "w")
    if target_file == nil then
        local dialog = CreateDialog("Failed to install Snap Captions",
            "Snap Captions could not be installed automatically. " ..
            "Please manually copy to the Scripts/Comp folder.")
        dialog:Show()
        dialog:RecalcLayout()
        return false
    end

    target_file:write(contents)
    target_file:close()

    print("[Snap Captions] Installed to " .. target_path)
    return true
end


local function PopulateSubtitleTracks(win)
    local combobox = win:Find("subtitle_tracks")
    local subtitle_stack = win:Find("subtitle_stack")
    local subtitle_placeholder = win:Find("subtitle_placeholder")
    combobox:Clear()

    local timeline = project:GetCurrentTimeline()
    local track_count = timeline:GetTrackCount("subtitle")
    if track_count == 0 then
        combobox:SetEnabled(false)
        subtitle_stack:SetCurrentIndex(1)
        combobox:SetVisible(false)
        subtitle_placeholder:SetVisible(true)
        return
    end

    subtitle_stack:SetCurrentIndex(0)
    combobox:SetEnabled(true)
    subtitle_placeholder:SetVisible(false)
    combobox:SetVisible(true)

    for i=1,track_count do
        win:Find("subtitle_tracks"):AddItems(
                {"[ST" .. i .. "] " .. timeline:GetTrackName("subtitle", i)})
    end
end


local function PopulateTextTemplates(win)
    ClearTable(fusion_titles)
    local combobox = win:Find("title_templates")
    local title_stack = win:Find("title_stack")
    local title_placeholder = win:Find("title_placeholder")
    combobox:Clear()

    local template_folder = nil
    for i, subfolder in ipairs(mediaPool:GetRootFolder():GetSubFolderList()) do
        if subfolder:GetName() == TEXT_TEMPLATE_FOLDER then
            template_folder = subfolder
            break
        end
    end

    if template_folder == nil or #template_folder:GetClipList() == 0 then
        if template_folder == nil then
            title_placeholder:SetText("No '" .. TEXT_TEMPLATE_FOLDER .. "' Bin Found")
        else
            title_placeholder:SetText("No Text+ Templates Found")
        end

        title_stack:SetCurrentIndex(1)
        combobox:SetEnabled(false)
        combobox:SetVisible(false)
        title_placeholder:SetVisible(true)
        return
    end

    title_stack:SetCurrentIndex(0)
    combobox:SetEnabled(true)
    title_placeholder:SetVisible(false)
    combobox:SetVisible(true)
    for i, clip in ipairs(template_folder:GetClipList()) do
        -- Filter out items that are not Text+ templates.
        if clip:GetClipProperty("File Path") == "" then
            table.insert(fusion_titles, clip)
            combobox:AddItems({clip:GetClipProperty("Clip Name")})
        end
    end
end


local function PopulateTextTransforms(win)
    local transform_combobox = win:Find("text_transform")
    transform_combobox:Clear()
    transform_combobox:AddItems({"None"})
    transform_combobox:AddItems({"To Lowercase"})
    transform_combobox:AddItems({"To Uppercase"})
    transform_combobox:AddItems({"Capitalize All Words"})
end


local function IsTimelineClip(clip)
    local clip_type = clip:GetClipProperty("Type")
    return timeline_type_names[clip_type] ~= nil
end


local function GetTimelineClipFromMediaPool(timeline_name, folder)
    local folder = folder or mediaPool:GetRootFolder()

    for i, clip in ipairs(folder:GetClipList()) do
        if IsTimelineClip(clip) and
                clip:GetClipProperty("Clip Name") == timeline_name then
            return clip
        end
    end

    for i, subfolder in ipairs(folder:GetSubFolderList()) do
        local clip = GetTimelineClipFromMediaPool(timeline_name, subfolder)
        if clip ~= nil then
            return clip
        end
    end

    return nil
end


local function ConvertTimecodeToFrame(timecode, fps, is_drop_frame, is_interlaced)
    local time_pieces = {}
    for str in string.gmatch(timecode, "(%d+)") do
        table.insert(time_pieces, str)
    end

    local rounded_fps = math.floor(fps + 0.5)

    local hours = tonumber(time_pieces[1])
    local minutes = tonumber(time_pieces[2])
    local seconds = tonumber(time_pieces[3])
    local frame = (hours * 60 * 60 + minutes * 60 + seconds) * rounded_fps
    local frame_count = tonumber(time_pieces[4])

    if is_interlaced then
        frame_count = frame_count * 2
        local add_frame = timecode:find('%.') == nil and timecode:find(',') == nil
        if add_frame then
            frame_count = frame_count + 1
        end
    end

    frame = frame + frame_count

    if is_drop_frame then
        local dropped_frames = math.floor(fps / 15 + 0.5)
        local total_minutes = 60 * hours + minutes

        frame = frame - (dropped_frames * (total_minutes - math.floor(total_minutes / 10)))
    end

    return frame
end


local function ConvertFrameToTimecode(frame, fps, is_drop_frame, is_interlaced)
    local rounded_fps = math.floor(fps + 0.5)
    if is_drop_frame then
        local dropped_frames = math.floor(fps / 15 + 0.5)
        local frames_per_ten = math.floor(fps * 60 * 10 + 0.5)
        local frames_per_minute = (rounded_fps * 60) - dropped_frames

        local d = math.floor(frame / frames_per_ten)
        local m = math.fmod(frame, frames_per_ten)
        if m > dropped_frames then
            frame = frame + (dropped_frames * 9 * d) +
                        dropped_frames * math.floor((m - dropped_frames) / frames_per_minute)
        else
            frame = frame + dropped_frames * 9 * d
        end
    end

    local frame_count = math.fmod(frame, rounded_fps)
    local seconds = math.fmod(math.floor(frame / rounded_fps), 60)
    local minutes = math.fmod(math.floor(math.floor(frame / rounded_fps) / 60), 60)
    local hours = math.floor(math.floor(math.floor(frame / rounded_fps) / 60) / 60)

    local frame_chars = string.len(tostring(rounded_fps - 1))
    local frame_divider = ":"
    local interlace_divider = "."
    if is_drop_frame then
        frame_divider = ";"
        interlace_divider = ","
    end

    local format_string = "%02d:%02d:%02d" .. frame_divider .. "%0" .. frame_chars .. "d"
    if is_interlaced then
        local frame_mod = math.fmod(frame_count , 2)
        frame_count = math.floor(frame_count / 2)
        if frame_mod == 0 then
            format_string = format_string:gsub("(.*)" .. frame_divider,
                                               "%1" .. interlace_divider)
        end
    end

    return string.format(format_string, hours, minutes, seconds, frame_count)
end


local function TimelineUsesDropFrameTimecodes(timeline)
    return timeline:GetSetting("timelineDropFrameTimecode") == "1"
end


local function TimelineUsesInterlacedTimecodes(timeline)
    return timeline:GetSetting("timelineInterlaceProcessing") == "1"
end


local function GetTimelineInOutTimecodes(timeline_clip, is_drop_frame, is_interlaced)
    local in_out_set = true
    local in_timecode = timeline_clip:GetClipProperty("In")
    if in_timecode == "" then
        in_timecode = timeline_clip:GetClipProperty("Start TC")
        local frame_divider = ":"
        local interlace_divider = "."
        if is_drop_frame then
            frame_divider = ";"
            interlace_divider = ","
        end
        if is_interlaced then
            in_timecode = in_timecode:gsub("(.*)" .. frame_divider,
                                           "%1" .. interlace_divider)
        end
    end
    local out_timecode = timeline_clip:GetClipProperty("Out")
    if out_timecode == "" then
        out_timecode = timeline_clip:GetClipProperty("End TC")
    end

    return in_timecode, out_timecode
end


local function ToTitleCase(first, rest)
    return first:upper()..rest:lower()
end


local function ApplyTextTransform(text, transform)
    if transform == "To Lowercase" then
        return string.lower(text)
    elseif transform == "To Uppercase" then
        return string.upper(text)
    elseif transform == "Capitalize All Words" then
        return text:gsub("(%a)([%w_']*)", ToTitleCase)
    else
        return text
    end
end


local function GetSubtitleData(subtitle_track_index,
                               in_frame,
                               out_frame,
                               transform,
                               remove_punctuation)
    local timeline = project:GetCurrentTimeline()
    local subtitle_clips = timeline:GetItemsInTrack("subtitle", subtitle_track_index)
    local subtitle_data = {}
    local index = 1

    for _, clip in ipairs(subtitle_clips) do
        if clip:GetEnd() <= in_frame or clip:GetStart() >= out_frame then
            goto continue
        end

        local start_frame = clip:GetStart()
        if start_frame < in_frame then
            start_frame = in_frame
        end

        local end_frame = clip:GetEnd()
        if end_frame > out_frame then
            end_frame = out_frame
        end

        subtitle_data[index] = {}
        subtitle_data[index]["start"] = start_frame
        subtitle_data[index]["end"] = end_frame
        subtitle_data[index]["duration"] = end_frame - start_frame

        local text = clip:GetName()
        text = ApplyTextTransform(text, transform)
        if remove_punctuation then
            text = text:gsub("[.!?,:;]", "")
        end

        -- Remove "invisible" UTF-8 line break
        text = text:gsub("\u{2028}", "\n")

        subtitle_data[index]["text"] = text
        index = index + 1

        ::continue::
    end

    return subtitle_data
end


local function CreateTextPlusClips(win, subtitle_data, template_index, video_track)
    if #subtitle_data == 0 then
        return true
    end

    local fill_gaps = win:Find("fill_gaps").Checked
    local max_fill = win:Find("max_fill").Value
    local text_clip = fusion_titles[template_index]

    -- First calculate a duration multiplier to ensure that any scaling triggered
    -- by the Fusion comp does not affect the length of the clip (too much...).
    local testClip = {}
    local testDuration = 100
    testClip["mediaPoolItem"] = text_clip
    testClip["startFrame"] = 0
    testClip["endFrame"] = testDuration - 1
    testClip["trackIndex"] = video_track
    testClip["recordFrame"] = subtitle_data[1]["start"]
    local testItem = mediaPool:AppendToTimeline({testClip})[1]
    local testDurationReal = testItem:GetDuration()
    local timeline = project:GetCurrentTimeline()
    timeline:DeleteClips({testItem}, false)
    local duration_multiplier = testDuration / testDurationReal

    for i, subtitle in ipairs(subtitle_data) do
        local newClip = {}
        newClip["mediaPoolItem"] = text_clip
        newClip["startFrame"] = 0
        newClip["endFrame"] = subtitle["duration"] - 1

        -- If filling gaps, check if there is a gap between this subtitle and
        -- the next one. If so, set the end of this subtitle to the start of
        -- the next one.
        if fill_gaps and i < #subtitle_data then
            local next_title = subtitle_data[i+1]
            local gap_size = next_title["start"] - subtitle["end"]
            if gap_size > 0 and gap_size <= max_fill then
                newClip["endFrame"] = newClip["endFrame"] + gap_size
            end
        end

        -- Update based on the duration multiplier. This conteracts any
        -- modifications to the clip length triggered by the Fusion comp.
        local base_duration = newClip["endFrame"] - newClip["startFrame"] + 1
        local new_duration = math.floor(base_duration * duration_multiplier + 0.999)
        newClip["endFrame"] = new_duration - 1

        newClip["trackIndex"] = video_track
        newClip["recordFrame"] = subtitle["start"]

        local timelineItem = mediaPool:AppendToTimeline({newClip})[1]
        timelineItem:SetClipColor("Green")

        if timelineItem:GetFusionCompCount() == 0 then
            local dialog = CreateDialog("No Fusion Comp found in the template",
                                        "Please ensure that the Text+ template contains a Fusion Comp and try again.")
            dialog:Show()
            dialog:RecalcLayout()
            return false
        end

        local comp = timelineItem:GetFusionCompByIndex(1)

        -- Check that the TextPlus tool exists in the comp.
        local text_plus_tools = comp:GetToolList(false, "TextPlus")
        if #text_plus_tools == 0 then
            local dialog = CreateDialog("No Text+ Tool found in the template",
                                        "Please ensure that the Text+ template contains a Text+ tool and try again.")
            dialog:Show()
            dialog:RecalcLayout()
            return false
        end

        text_plus_tools[1]:SetInput("StyledText", subtitle["text"])
        app:Sleep(0.005)
        win:Repaint()
    end

    return true
end


local function GenerateTextPlus(win)
    -- Get the selected subtitle track.
    local subtitle_track_index = win:Find("subtitle_tracks").CurrentIndex + 1
    if subtitle_track_index == 0 then
        local dialog = CreateDialog("No Subtitle Track",
                                    "Please create a subtitle track and try again.")
        dialog:Show()
        dialog:RecalcLayout()
        return false
    end

    local text_template_index = win:Find("title_templates").CurrentIndex + 1
    if text_template_index == 0 then
        local dialog = CreateDialog("No Text+ Template",
                                    "Please add a Text+ template to the Media Pool in a bin named '" .. TEXT_TEMPLATE_FOLDER .. "' and try again.")
        dialog:Show()
        dialog:RecalcLayout()
        return false
    end

    local timeline = project:GetCurrentTimeline()
    local is_interlaced = TimelineUsesInterlacedTimecodes(timeline)
    local is_drop_frame = TimelineUsesDropFrameTimecodes(timeline)
    local timeline_clip = GetTimelineClipFromMediaPool(timeline:GetName())
    local in_timecode, out_timecode =
            GetTimelineInOutTimecodes(timeline_clip, is_drop_frame, is_interlaced)
    local fps = timeline_clip:GetClipProperty("FPS")
    local in_frame = ConvertTimecodeToFrame(in_timecode, fps, is_drop_frame, is_interlaced)
    local out_frame = ConvertTimecodeToFrame(out_timecode, fps, is_drop_frame, is_interlaced)

    local transform = win:Find("text_transform").CurrentText
    local remove_punctuation = win:Find("remove_punctuation").Checked
    local subtitle_data = GetSubtitleData(subtitle_track_index,
                                          in_frame,
                                          out_frame,
                                          transform,
                                          remove_punctuation)

    -- Create a new video track.
    timeline:AddTrack("video")
    local track_count = timeline:GetTrackCount("video")

    local success = CreateTextPlusClips(win, subtitle_data, text_template_index, track_count)
    if not success then
        -- Delete the added track.
        timeline:DeleteTrack("video", track_count)
    else
        timeline:SetTrackEnable("subtitle", subtitle_track_index, false)
    end

    -- Reset the In/Out points.
    local timeline_clip = GetTimelineClipFromMediaPool(timeline:GetName())
    if timeline_clip:GetClipProperty("In") ~= "" or
            timeline_clip:GetClipProperty("Out") ~= "" then

        -- Note: SetClipProperty does not correctly handle interlaced timecodes.
        timeline_clip:SetClipProperty("In",
                        ConvertFrameToTimecode(in_frame+1, fps, is_drop_frame, false))
        if is_interlaced then
            in_timecode = ConvertFrameToTimecode(in_frame, fps, is_drop_frame, false)
        end
        timeline_clip:SetClipProperty("In", in_timecode)
    end

    return success
end


local function CreateToolWindow()
    local win = disp:AddWindow(
        {
            ID = winID,
            WindowTitle = "Snap Captions v1.2",
            Geometry = {nil, nil, WINDOW_WIDTH, WINDOW_HEIGHT},
            Margin = 16,

            ui:VGroup
            {
                Spacing = 0,
                ui:VGroup
                {
                    Weight = 0,
                    ID = "install_bar",
                    Spacing = 0
                },
                ui:VGroup
                {
                    ID = "root",
                    Spacing = 0,
                    FixedX = WINDOW_WIDTH,
                    FixedY = WINDOW_HEIGHT,
                    ui:Label
                    {
                        Text = "Source Subtitle Track",
                        StyleSheet = SECTION_TITLE_CSS,
                    },
                    ui:VGap(8, 0),
                    ui:HGroup
                    {
                        Spacing = 0,
                        ID = "subtitle_track_group",
                        ui:Stack
                        {
                            ID = "subtitle_stack",
                            CurrentIndex = 0,
                            ui:ComboBox
                            {
                                ID = "subtitle_tracks",
                                MinimumSize = {10, 26}
                            },
                            ui:Label
                            {
                                ID = "subtitle_placeholder",
                                Visible = false,
                                Text = "No subtitle tracks found",
                                StyleSheet = COMBOBOX_PLACEHOLDER_CSS
                            }
                        },
                        ui:Button
                        {
                            ID = "refresh_subtitle_tracks",
                            Text = "↺",
                            ToolTip = "Refresh Subtitle Track List",
                            StyleSheet = COMBOBOX_ACTION_BUTTON_CSS
                        }
                    },
                    ui:VGap(16, 0),
                    ui:Label
                    {
                        Text = "Text+ Template",
                        StyleSheet = SECTION_TITLE_CSS,
                    },
                    ui:VGap(8, 0),
                    ui:HGroup
                    {
                        Spacing = 0,
                        ui:Stack
                        {
                            ID = "title_stack",
                            CurrentIndex = 0,
                            ui:ComboBox
                            {
                                ID = "title_templates",
                                MinimumSize = {10, 26}
                            },
                            ui:Label
                            {
                                ID = "title_placeholder",
                                Visible = false,
                                Text = "No '" .. TEXT_TEMPLATE_FOLDER .. "' Bin Found",
                                ToolTip = "<qt>Add Text+ templates to the Media Pool in a Bin named '" .. TEXT_TEMPLATE_FOLDER .. "'</qt>",
                                StyleSheet = COMBOBOX_PLACEHOLDER_CSS
                            }
                        },
                        ui:Button
                        {
                            ID = "refresh_text_templates",
                            Text = "↺",
                            ToolTip = "Refresh Text+ Template List",
                            StyleSheet = COMBOBOX_ACTION_BUTTON_CSS
                        }
                    },
                    ui:VGap(16, 0),
                    ui:Label
                    {
                        FrameStyle = 4,
                        StyleSheet = DIVIDER_CSS
                    },
                    ui:Label
                    {
                        Text = "Customization",
                        StyleSheet = SECTION_TITLE_CSS,
                    },
                    ui:VGap(8, 0),
                    ui:HGroup
                    {
                        Spacing = 8,
                        ui:Label{ Text = "Case Conversion",
                                  MinimumSize = {COLUMN_WIDTH, 0},
                                  MaximumSize = {COLUMN_WIDTH, 1000},
                                  Alignment = { AlignRight = true, AlignVCenter = true }},
                        ui:ComboBox{ ID = "text_transform",
                                      MinimumSize = {10, 26} }
                    },
                    ui:VGap(8, 0),
                    ui:HGroup
                    {
                        Spacing = 8,
                        ui:Label{ Text = "Remove Punctuation",
                                  MinimumSize = {COLUMN_WIDTH, 0},
                                  MaximumSize = {COLUMN_WIDTH, 1000},
                                  Alignment = { AlignRight = true, AlignVCenter = true }},
                        ui:CheckBox{ ID = "remove_punctuation",
                                     Checked = false}
                    },
                    ui:VGap(8, 0),
                    ui:HGroup
                    {
                        Spacing = 8,
                        ui:Label{ Text = "Fill Gaps",
                                  MinimumSize = {COLUMN_WIDTH, 0},
                                  MaximumSize = {COLUMN_WIDTH, 1000},
                                  Alignment = { AlignRight = true, AlignVCenter = true }},
                        ui:CheckBox{ ID = "fill_gaps",
                                     Checked = true,
                                     Events = { Toggled = true }},
                        ui:HGroup
                        {
                            Weight = 1,
                            ID = "max_fill_group",
                            Enabled = true,
                            ui:Label{ Text = "Max Fill",
                                      Alignment = { AlignVCenter = true },
                                      Weight = 0 },
                            ui.SpinBox{ ID = "max_fill",
                                        Suffix = " Frames",
                                        Minimum = 1,
                                        Maximum = 9999,
                                        Value = 10,
                                        Weight = 1,
                                        MinimumSize = {100, 26}}
                        }
                    },
                    ui:VGap(16, 10),
                    ui:Label
                    {
                        FrameStyle = 4,
                        StyleSheet = DIVIDER_CSS
                    },
                    ui:VGap(4, 0),
                    ui:HGroup
                    {
                        ui:Button{ ID = "process",
                                   Text = "Generate",
                                   StyleSheet = PRIMARY_ACTION_BUTTON_CSS
                        }
                    },
                    ui:VGap(12, 0),
                    ui:HGroup
                    {
                        ui:Button{ ID = "tutorial_cta",
                                   Text = "YouTube Tutorial",
                                   StyleSheet = SECONDARY_ACTION_BUTTON_CSS},
                        ui:Button{ ID = "donate_cta",
                                   Text = "Donate",
                                   StyleSheet = SECONDARY_ACTION_BUTTON_CSS},
                    }
                }
            }
        })

    PopulateSubtitleTracks(win)
    PopulateTextTemplates(win)
    PopulateTextTransforms(win)

    function win.On.tutorial_cta.Clicked(ev)
        OpenURL(TUTORIAL_URL)
    end

    function win.On.donate_cta.Clicked(ev)
        OpenURL(DONATE_URL)
    end

    function win.On.process.Clicked(ev)
        local root_element = win:Find("root")
        root_element:SetEnabled(false)
        local success = GenerateTextPlus(win)
        root_element:SetEnabled(true)
        if not success then
            return
        end
        disp:ExitLoop()
    end

    function win.On.fill_gaps.Toggled(ev)
        local group = win:Find("max_fill_group")
        local checkbox = win:Find("fill_gaps")
        group:SetEnabled(checkbox.Checked)
    end

    function win.On.SnapCaptionsWin.Close(ev)
        disp:ExitLoop()
    end

    function win.On.refresh_subtitle_tracks.Clicked(ev)
        PopulateSubtitleTracks(win)
    end

    function win.On.refresh_text_templates.Clicked(ev)
        PopulateTextTemplates(win)
    end

    function win.On.install.Clicked(ev)
        local success = InstallScript()
        if not success then
            return
        end

        local content = win:GetItems().install_bar
        content:RemoveChild("install_group")
        win:RecalcLayout()
    end

    if not SCRIPT_INSTALLED then
        local content = win:GetItems().install_bar
        content:AddChild(
            ui:VGroup
            {
                ID = "install_group",
                Weight = 0,
                Spacing = 10,
                StyleSheet = [[
                    QWidget
                    {
                        margin-bottom: 0px;
                    }
                ]],
                ui:HGroup
                {
                    ui:Label
                    {
                        Weight = 1,
                        Text = "Install tool to Resolve's Scripts folder?"
                    },
                    ui:Button
                    {
                        Weight = 0,
                        ID = "install",
                        Text = "Install",
                        StyleSheet = BANNER_ACTION_BUTTON_CSS
                    }
                },
                ui:Label
                {
                    Weight = 0,
                    FrameStyle = 4,
                    StyleSheet = DIVIDER_CSS
                }
            })
    end

    win:RecalcLayout()
    win:Show()
    disp:RunLoop()
    win:Hide()
end


local function Main()
    -- Check that there is a current timeline.
    if project:GetCurrentTimeline() == nil then
        local dialog = CreateDialog("No Current Timeline",
                                    "Please open a timeline and try again.")
        dialog:RecalcLayout()
        dialog:Show()
        disp:RunLoop()
        return
    end

    -- If the window is already being shown, raise it and exit.
    local win = ui:FindWindow(winID)
    if win ~= nil then
        win:RecalcLayout()
        win:Show()
        win:Raise()
        return
    end

    -- Otherwise, create the tool window.
    CreateToolWindow()
end


Main()
