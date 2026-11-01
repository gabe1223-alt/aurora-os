// Aurora default desktop: bottom taskbar, start menu, app grid, tray, clock.
// Executed once per user by /usr/lib/aurora/apply-layout via plasmashell's scripting API.
var wallpaper = "file:///usr/share/wallpapers/AuroraDawn";

var oldPanels = panels();
for (var i = 0; i < oldPanels.length; i++) {
    oldPanels[i].remove();
}

var panel = new Panel;
panel.location = "bottom";
panel.height = 46;
panel.hiding = "none";

var start = panel.addWidget("org.kde.plasma.kickoff");
start.currentConfigGroup = ["General"];
start.writeConfig("icon", "aurora-logo");

var grid = panel.addWidget("org.kde.plasma.kickerdash");
grid.currentConfigGroup = ["General"];
grid.writeConfig("icon", "view-grid");

var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers",
    "applications:firefox-esr.desktop,applications:org.kde.dolphin.desktop," +
    "applications:systemsettings.desktop,applications:org.kde.discover.desktop");

panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.systemtray");

var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", "BelowTime");

panel.addWidget("org.kde.plasma.showdesktop");

var all = desktops();
for (var j = 0; j < all.length; j++) {
    all[j].wallpaperPlugin = "org.kde.image";
    all[j].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    all[j].writeConfig("Image", wallpaper);
}
