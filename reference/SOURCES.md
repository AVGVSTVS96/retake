# Sources

Everything in `reference/` and where it came from. Collected 2026-10-09.

## Apple documentation (authoritative)

| What | URL |
|---|---|
| iPhone User Guide, iOS 27, Voice Memos section (11 pages) | https://support.apple.com/guide/iphone/make-a-recording-iph4d2a39a3b/27/ios/27 (siblings: view-a-transcription-iph00953a982, play-it-back-iphebbd067ce, add-a-second-layer-to-a-recording-iphfefa3252b, export-a-recording-to-files-iph831c37815, edit-or-delete-a-recording-iphc9bdaee83, keep-recordings-up-to-date-iph38b91c7af, organize-recordings-iph73bfaba07, search-for-or-rename-a-recording-iph0e546e6ec, share-a-recording-iph3d6dc359, duplicate-a-recording-iphbda915db2; swap `/27/ios/27` for `/26/ios/26` or `/18.0/ios/18.0`) |
| iPad User Guide, iPadOS 27, Voice Memos section (12 pages) | https://support.apple.com/guide/ipad/get-started-with-voice-memos-ipadf455678c/27/ipados/27 (siblings: make-a-recording-ipadf455678zz, view-a-transcription-ipad282bee5e, play-it-back-ipad1af54777, work-with-layered-recordings-ipadb372d34f, export-a-recording-to-files-ipad117b485b, edit-or-delete-a-recording-ipadcba66e18, keep-recordings-up-to-date-ipad577019a4, organize-recordings-ipad5d59d4c5, search-for-or-rename-a-recording-ipade52454e2, share-a-recording-ipad83364e1f, duplicate-a-recording-ipadf646b2a8) |
| Apple Newsroom, Layered Recording (Dec 2024, iOS 18.2) | https://www.apple.com/newsroom/2024/12/voice-memos-update-brings-layered-recording-to-iphone-16-pro-lineup/ |
| Apple Music for Artists, "iOS 26: What's new" (Studio Voice, Spatial Audio default, Enhanced Sharing) | https://artists.apple.com/support/5550-ios-26-whats-new |
| WWDC25 session 251 (Spatial Audio in audio-only apps, .qta with APAC track) | https://developer.apple.com/videos/play/wwdc2025/251/ |

Plain-text dumps of the guide pages, with every image URL inline: `apple-guide-text/iphone-ios27.txt`, `iphone-ios26.txt`, `iphone-ios18.txt`, `ipad-ipados27.txt`.

## Screenshots: `shots/`

### From Apple's guides (clean renders, light mode)

| File | Source page | Image URL |
|---|---|---|
| iphone-ios27-recording-sheet-expanded-light_apple-guide.png | iOS 27 Make a recording | https://ipcdn-web.apple.com/assets/v2/web/e842f65a-01d3-4e80-8312-a30fc05c367a |
| iphone-ios27-list-row-expanded-playback-light_apple-guide.png | iOS 27 Play it back | https://ipcdn-web.apple.com/assets/v2/web/00164159-3fd7-4b42-8018-ba6601180a23 |
| iphone-ios27-edit-trim-light_apple-guide.png | iOS 27 Edit or delete | https://ipcdn-web.apple.com/assets/v2/web/9b8f9075-5519-48dc-88f6-e776404a1950 |
| iphone-ios27-layer2-record-light_apple-guide.png | iOS 27 Add a second layer | https://ipcdn-web.apple.com/assets/v2/web/f357e44c-11ba-46e4-9679-24cafdf5563d |
| iphone-ios27-dynamic-island-recording-light_apple-guide.png | iOS 27 Make a recording | https://ipcdn-web.apple.com/assets/v2/web/51280838-be41-4391-a364-f158233dfd16 |
| iphone-ios26-recording-sheet-expanded-light_apple-guide.png | iOS 26 Make a recording | https://ipcdn-web.apple.com (id f8f05b01…, see apple-guide-text/iphone-ios26.txt) |
| iphone-ios26-list-row-expanded-playback-siri-tip-light_apple-guide.png | iOS 26 Play it back | id 4ce3e1be… |
| iphone-ios26-edit-trim-light_apple-guide.png | iOS 26 Edit or delete | id 9f589623… |
| iphone-ios26-dynamic-island-recording-light_apple-guide.png | iOS 26 Make a recording | id 8993f561… |
| iphone-ios18-recording-sheet-expanded-light_apple-guide.png | iOS 18 Make a recording | id a28a3553… |
| iphone-ios18-list-row-expanded-playback-light_apple-guide.png | iOS 18 Play it back | id e4735297… |
| iphone-ios18-edit-trim-light_apple-guide.png | iOS 18 Edit or delete | id 4acb5cbe… |
| ipad-ipados27-split-list-plus-player-light_apple-guide.png | iPadOS 27 Get started | https://ipcdn-web.apple.com/assets/v2/web/8134c4a0-fbf3-4c8c-93d2-adf07c302da3 |
| ipad-ipados27-split-list-plus-player-alt-light_apple-guide.png | iPadOS 27 Make a recording | https://ipcdn-web.apple.com/assets/v2/web/39411d03-abc7-43db-9d78-a9262d240e24 |
| ipad-ipados27-edit-trim-light_apple-guide.png | iPadOS 27 Edit or delete | https://ipcdn-web.apple.com/assets/v2/web/762f27fb-4256-4b34-97f1-6505e90c0946 |
| iphone-ios18.2-layered-recording-two-screens-dark_apple-newsroom.jpg | Apple Newsroom Dec 2024 | https://www.apple.com/newsroom/images/2024/12/voice-memos-update-brings-layered-recording-to-iphone-16-pro-lineup/article/Apple-Voice-Memos-update-hero_big.jpg.large.jpg |

Full ids for the iOS 26/18 images are in the `apple-guide-text/*.txt` dumps (search for the 8-char prefix).

`glyphs-apple-guide-ios27/` and `glyphs-apple-guide-ipados27/`: every inline button glyph from the guides (Record, Stop, Pause, Done, More, Options, Trim, Layers, Transcription, Favorite, New Folder, tortoise/hare…), named `<alt>__<page>__<id>.png`. Contact sheet: `glyphs-apple-guide-ios27-contact-sheet.png`.

### Video stills: `shots/video-stills/`

Cropped full-res frames from the videos below. Naming: `<device>-<os>-<screen>_<appearance>[_capture-kind]`.

- `iphone18promax-ios27-*` and `iphone18pro-ios27-*`: from TUTORIAL_info (camera-filmed real iPhone 18 Pro Max/Pro on iOS 27.0; camera white balance adds a lavender tint, so don't sample colors from these).
- `iphone-ios26-screenrec-*`: from Strait Macintosh User Group (true screen recording, iOS 26.x, Feb 2026). Best for colors and measurements.
- `iphone-ios27beta-*_dark_camera`: Stephen Robles, iOS 27 beta, dark mode, camera-filmed.
- `iphone-ios18-dark-*`: Techrona (screen recording inside a phone mockup, actually iOS 18 UI, dark).

## Videos: `video/`

| File | Source | OS | Kind | Why |
|---|---|---|---|---|
| 20260926_TUTORIAL_info_iPhone_18_Pro_Max_How_to_Use_Voice_Memos_wDcM9ZKxigU.mp4 | https://www.youtube.com/watch?v=wDcM9ZKxigU | iOS 27.0, iPhone 18 Pro Max | camera, 1080p60 | **Primary iOS 27 reference.** Covers empty state, record, card → sheet, pause/resume, rename, replace, layer 2, transcript, options, menus, Done, delete, folders, Recently Deleted |
| 20260929_TUTORIAL_info_iPhone_18_Pro_How_to_Use_Voice_Memos_58It1ayd3ds.mp4 | https://www.youtube.com/watch?v=58It1ayd3ds | iOS 27.0, iPhone 18 Pro | camera, 1080p60 | Same flows with an existing row in the list; tap-to-expand the card |
| 20260219_Strait_Macintosh_User_Group_iOS_26_-_Voice_Memo_app_C_pCqbpvt_E.mp4 | https://www.youtube.com/watch?v=C_pCqbpvt_E | iOS 26.x | **screen recording**, 1080p60 | Only true screen capture of the Liquid Glass record → **stop** → row-insert cycle |
| 20250919_HardReset.Info_How_to_Record_Sounds_on_iPhone_17_Pro_Max_-_Voice__fq21iIxBCTg.mp4 | https://www.youtube.com/watch?v=fq21iIxBCTg | iOS 26.0, iPhone 17 Pro Max | camera, 1080p60 | Second take of record/stop on iOS 26 |
| ios27_stephen-robles_voice-memos-chapter_L-AsK8wivl8.mp4 | https://www.youtube.com/watch?v=L-AsK8wivl8 (52:37 chapter "Voice Memos", clip 52:20-53:20) | iOS 27 beta | camera, dark | Dark mode list, row menu, share Options (Rendered/Editable) |
| 20251024_Techrona_How_To_Edit_Voice_Memos_On_iPhone_ujTYJIXArSE.mp4 | https://www.youtube.com/watch?v=ujTYJIXArSE | iOS 18 UI | screen rec in mockup, dark, 60fps | Pre-Liquid-Glass baseline: options sheet with Skip Silence/Enhance, trim, replace |
| 20251021_Techrona_How_To_Use_Voice_Memos_On_iPhone_2026_Step-By-Step_Tutorial_aPREWM1sOi4.mp4 | https://www.youtube.com/watch?v=aPREWM1sOi4 | iOS 18 UI | screen rec in mockup, dark | Folders list, recording, row menu (iOS 18 baseline) |

Other videos looked at and skipped: 9to5Mac "Everything You Can Do With Voice Memos" (2023, iOS 16), SEIDS (Dec 2024), Free Tech Guide "Record a Conversation (iOS 27.0.1)" (mostly Phone call recording, deleted), Brandon Butch iOS 27 roundups (no Voice Memos segment found).

## Frame sequences: `frames/`

All at the video's native 60 fps, cropped to the phone screen, named `fNNNN.jpg` from 0. Frame 0 = the start time listed.

| Folder | Video | Start (s) | Length |
|---|---|---|---|
| ios27_record-tap_card-rise | wDcM9ZKxigU | 37.0 | 3.5 s |
| ios27_record-tap_card-rise_with-existing-row | 58It1ayd3ds | 37.5 | 2.5 s |
| ios27_card-swipe-up_to_expanded-sheet | wDcM9ZKxigU | 43.5 | 3.0 s |
| ios27_tap-card_to_expanded-sheet | 58It1ayd3ds | 45.5 | 2.5 s |
| ios27_pause-resume | wDcM9ZKxigU | 50.0 | 4.0 s |
| ios27_transcript-toggle | wDcM9ZKxigU | 129.0 | 2.5 s |
| ios27_options-sheet-open | wDcM9ZKxigU | 155.5 | 2.5 s |
| ios27_sheet-more-menu-open | wDcM9ZKxigU | 186.5 | 2.5 s |
| ios27_done_sheet-dismiss_row-insert | wDcM9ZKxigU | 203.5 | 2.5 s |
| ios27_row-waveform-button_to_full-player | wDcM9ZKxigU | 218.5 | 2.5 s |
| ios27_row-more-menu-open | wDcM9ZKxigU | 225.5 | 2.5 s |
| ios27_delete-row_to-empty-state | wDcM9ZKxigU | 243.5 | 2.5 s |
| ios27_back-to-folders | wDcM9ZKxigU | 250.5 | 3.0 s |
| ios26_screenrec_record-tap_card-rise | C_pCqbpvt_E | 15.0 | 2.5 s |
| ios26_screenrec_stop_card-collapse_row-insert | C_pCqbpvt_E | 25.0 | 3.0 s |

## Press and community (features, bugs)

- Mac Observer, "How to use Studio Sound in iOS 27 Voice Memos" (403 to fetch; seen via search): https://www.macobserver.com/tips/round-ups/how-to-use-studio-sound-ios-27-voice-memos/
- BetaWiki iOS 27 (via search summary only, page 403s): Voice Memos listed among apps that gained landscape layouts. https://betawiki.net/wiki/IOS_27
- iGeeksBlog iOS 26 Voice Memos guide (third-party, low trust): https://www.igeeksblog.com/how-to-use-voice-memos-on-iphone-ipad/
- Bug threads: see the bugs section at the end of SPEC.md for links.
