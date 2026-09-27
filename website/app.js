const english={
skip:"Skip to content",navHow:"How it works",eyebrow:"FOR YOUR EVERYDAY MAC",title:"AirDrop it.<br>Make it a photo<br><em>you can use.</em>",
intro:"Turn incoming HEIC photos into PNG or JPEG.<br>No opening Preview. No manual export.<br>A little less work, right from your menu bar.",
download:"Download for Mac",requirements:"Free & MIT licensed / macOS 14 or later<br>Apple Silicon & Intel",
feature1:"Finds your photos",feature1body:"Detects images received via AirDrop.",feature2:"Converts together",feature2body:"Waits for the transfer. Works in the background.",feature3:"Keeps originals safe",feature3body:"Optionally trashes only successfully converted files.",
howTitle:"The same AirDrop.<br>A simpler next step.",step1:"Add it to your Mac",step1body:"Unzip, copy the app to Applications, and allow access to Downloads.",step2:"Send your photos",step2body:"AirDrop from your iPhone as usual. When the transfer finishes, confirm conversion.",step3:"Convert and use",step3body:"Choose your format. PNG or JPEG files are saved next to the originals.",
detailsTitle:"There when you need it.<br>Out of the way otherwise.",detailsIntro:"Lives in your menu bar, without a Dock icon.<br>Image conversion happens on your Mac.",
manualTitle:"Already have photos? Pick them.",manualBody:"Select existing HEIC or HEIF files from the menu and convert them together.",
safeTitle:"No overwrites. No lost failed inputs.",safeBody:"Existing outputs get numbered filenames. Even with deletion enabled, originals are kept when conversion fails.",
settingsTitle:"Set it up for your workflow.",settingsBody:"Pause monitoring, choose an output format, trash originals after conversion, or launch at login. English and Japanese menus included.",
getTitle:"One less step.<br>Starting with your next AirDrop.",getNote:"Available on GitHub Releases<br>Developer ID signed & Apple notarized",
notesTitle:"Formats and things to know",notesBody:"<p>PNG and JPEG are supported. WebP appears only when macOS supports encoding it.</p><p>Automatic detection requires an AirDrop quarantine attribute. Use manual conversion for files without it, or files already present when monitoring starts.</p><p>Only the primary HEIF image is converted. Live Photo videos and depth data are not exported. Physical iPhone AirDrop, launch after a real login, and execution on Intel hardware have not been verified.</p>",
footer:"Free and open source. A small companion for your Mac."
};
const nodes=[...document.querySelectorAll("[data-i18n]")];
const japanese=Object.fromEntries(nodes.map(node=>[node.dataset.i18n,node.innerHTML]));
const button=document.querySelector("#language");
let language="ja";
button.addEventListener("click",()=>{
language=language==="ja"?"en":"ja";
const dictionary=language==="en"?english:japanese;
nodes.forEach(node=>{node.innerHTML=dictionary[node.dataset.i18n];});
document.documentElement.lang=language;
button.textContent=language==="ja"?"EN":"日本語";
button.setAttribute("aria-label",language==="ja"?"Switch to English":"日本語に切り替え");
document.querySelector(".hero-art .logo").alt=language==="ja"?"写真のフレームを包む青い矢印のAirDropConverterロゴ":"AirDropConverter logo with a blue arrow wrapping a photo frame";
document.title=language==="ja"?"AirDropConverter — AirDropした画像を、すぐ使える形に。":"AirDropConverter — AirDrop photos, ready to use.";
document.querySelector('meta[name="description"]').content=language==="ja"?"AirDropで届いたHEIC画像をPNG・JPEGに。AirDropConverterは、変換のひと手間を減らす無料のmacOSメニューバーアプリです。":"Convert AirDropped HEIC photos to PNG or JPEG with a free, open-source macOS menu bar app.";
});
