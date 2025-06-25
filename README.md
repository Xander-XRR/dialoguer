# Dialoguer
Undertale style Dialogue GIF Generator made to be as customizable as Godot allows me to make it!

# Current Features
- Ability to type out text in a typewritter style akin to Undertale.
- Ability to spesify amost everything about any line, including font, font size, icons, custum textboxes, text-, icon- and textbox color, delays, and more.
- Intigrated BBCode Support [(color], [wave], [shake], [tornado] and [rainbow]).
- Thats really about it lol

# Instructions
To create a Dialogue GIF, follow these Steps:
1. Install ffmpeg, its the program used to actually generate the GIF.
2. Open Dialoguer at least once. It will automatically generate the folders you'll need for your textboxes in your Documents Folder under `Documents/Dialoguer Assets`.
3. Go to `/Dialoguer Assets/Dialogue` and create an empty document/empty text file.
4. Name it whatever you want and make it a JSON file. (if you made an empty text file, replace the .txt at the end with .json)
5. Start typing! In the downloaded ZIP file you should find two files called 'info.json' and 'example.json', the former showing all available variables and the latter showing an example of how to use some of them.
6. Run the program, put the GIFs name in the first field, the JSON files name in the second and the filename in `Dialoguer Assets/Dialogue`, then start.
7. It'll show the textbox typing the characters out, so if you wanna change anything simply make that change and try again!
8. Open the GIFs Folder and enjoy your Textbox GIF!

NOTE: For now, when something goes wrong and the program doesn't seem to continue with the dialogue, force-close it and clear the Frames Folder on startup. Clearing the leftover frames is always recommended as it might mess with your future GIFs otherwise.

# Future Plans
Currently Planned Features:
- Custom Text Shader support using .gdshader files.
- Custom events allowing things like a screenflash or other animated shenanigans.
- Option to export as an MP4, allowing an audio-visual format instead of being limited to text and sprites.
- More control over the generation of the GIFs.

I want to expand this Project further and add even more stuff so if you have ideas or know stuff about Godot and would like to help out, reach out over discord (xanderxrr) and leave feedback, i'll try making this thing as good as i can. :3
