all: helper audio_output

helper: helper.c cpu.h sketchybar.h
	clang -std=c99 -O3 helper.c -o helper

audio_output: audio_output.c
	clang -std=c99 -O3 audio_output.c -o audio_output -framework CoreAudio -framework CoreFoundation
