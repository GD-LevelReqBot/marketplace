// !nowplaying — show the currently playing song
let current = ms.get("current");
if current == () || current == "" {
    chat.say("Nothing is currently playing.");
} else {
    chat.say(`Now playing: ${current}`);
}
