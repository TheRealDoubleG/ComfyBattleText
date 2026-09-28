ComfyBattleText = ComfyBattleText or {}
local A = ComfyBattleText
local de = GetLocale and GetLocale() == "deDE"

local EN = {
    TAB_GENERAL="Battle Text", TAB_INFO="Info", ADDON_ENABLED="Enable ComfyBattleText",
    INFO_VERSION="Version", INFO_BUILD_DATE="Build date", INFO_STATUS="Status", INFO_CLIENT="Current client",
    INFO_TESTED_TARGET="Tested target", INFO_COMPAT_STATUS="Compatibility", INFO_AUTHOR="Author",
    INFO_DISCORD="Discord", INFO_GITHUB="GitHub", INFO_COMMANDS="Slash commands",
    COMPAT_MATCH="Compatible", COMPAT_UPDATE_REQUIRED="Interface differs from the tested target",
    INFO_NOTICE="ComfyBattleText only changes combat-event presentation. It does not automate combat, targeting, movement or protected actions.",
    INFO_THANKS="Thanks for using ComfyBattleText! Feedback and bug reports are welcome via Discord.",

    CAT_INCOMING="Incoming", CAT_OUTGOING="Outgoing", CAT_NOTIFICATIONS="Notifications",
    CAT_NAMEPLATES="Nameplates", CAT_FILTERS="Filters", CAT_APPEARANCE="Appearance",

    SECTION_INCOMING="Incoming combat text",
    SECTION_OUTGOING="Outgoing combat text",
    SECTION_NOTIFICATIONS="Combat notifications",
    SECTION_NAMEPLATES="Nameplate combat text",
    SECTION_FILTERS="Spam filters",
    SECTION_APPEARANCE="Appearance and scroll areas",

    ENABLE_INCOMING="Enable incoming area", ENABLE_OUTGOING="Enable outgoing area",
    ENABLE_NOTIFICATIONS="Enable notification area", ENABLE_NAMEPLATES="Enable nameplate combat text",
    SHOW_DAMAGE="Show damage", SHOW_HEALING="Show healing", SHOW_MISSES="Show misses / avoids",
    SHOW_PET_DAMAGE="Include own pet damage", SHOW_INTERRUPTS="Show successful interrupts",
    SHOW_DISPELS="Show dispels / spell steals",
    MIN_IN_DAMAGE="Minimum incoming damage", MIN_IN_HEAL="Minimum incoming healing",
    MIN_OUT_DAMAGE="Minimum outgoing damage", MIN_OUT_HEAL="Minimum outgoing healing",
    HIDE_PERIODIC_DAMAGE="Hide periodic damage", HIDE_PERIODIC_HEALING="Hide periodic healing",

    FONT_SIZE="Font size", DIRECTION="Scroll direction", DIR_UP="Up", DIR_DOWN="Down",
    SHORT_NUMBERS="Shorten large numbers (12.4k)", SHOW_SPELL_NAME="Show spell names",
    SHOW_SPELL_ICON="Show spell icons", SCHOOL_COLORS="Color outgoing damage by spell school",
    CRIT_SCALE="Critical-hit size", MESSAGE_LIFETIME="Message lifetime",
    SCROLL_SPEED="Scroll speed", MAX_MESSAGES="Maximum messages per area",
    UNLOCK_AREAS="Unlock and show scroll-area anchors", RESET_AREAS="Reset area positions",
    TEST_TEXT="Test battle text",

    INCOMING="Incoming", OUTGOING="Outgoing", NOTIFICATIONS="Notifications",
    MELEE="Melee", INTERRUPT="Interrupt", DISPEL="Dispel", ABSORB="Absorb",
    ANCHORS_ON="Scroll-area anchors unlocked.", ANCHORS_OFF="Scroll-area anchors locked.",
    FOREVER_NOTE="The first beta uses guarded CombatLogGetCurrentEventInfo data and intentionally filters to the player and own pet. Forever combat-log payloads still need in-game validation.",
}

local DE = {
    TAB_GENERAL="Kampftext", TAB_INFO="Info", ADDON_ENABLED="ComfyBattleText aktivieren",
    INFO_VERSION="Version", INFO_BUILD_DATE="Build-Datum", INFO_STATUS="Status", INFO_CLIENT="Aktueller Client",
    INFO_TESTED_TARGET="Getestetes Ziel", INFO_COMPAT_STATUS="Kompatibilität", INFO_AUTHOR="Autor",
    INFO_DISCORD="Discord", INFO_GITHUB="GitHub", INFO_COMMANDS="Slash-Befehle",
    COMPAT_MATCH="Kompatibel", COMPAT_UPDATE_REQUIRED="Interface weicht vom getesteten Ziel ab",
    INFO_NOTICE="ComfyBattleText verändert nur die Darstellung von Kampfereignissen. Kampf, Zielwahl, Bewegung oder geschützte Aktionen werden nicht automatisiert.",
    INFO_THANKS="Danke, dass du ComfyBattleText nutzt! Feedback und Fehlermeldungen sind über Discord willkommen.",

    CAT_INCOMING="Eingehend", CAT_OUTGOING="Ausgehend", CAT_NOTIFICATIONS="Hinweise",
    CAT_NAMEPLATES="Namensplaketten", CAT_FILTERS="Filter", CAT_APPEARANCE="Darstellung",

    SECTION_INCOMING="Eingehender Kampftext",
    SECTION_OUTGOING="Ausgehender Kampftext",
    SECTION_NOTIFICATIONS="Kampfhinweise",
    SECTION_NAMEPLATES="Kampftext an Namensplaketten",
    SECTION_FILTERS="Spam-Filter",
    SECTION_APPEARANCE="Darstellung und Scrollbereiche",

    ENABLE_INCOMING="Eingehenden Bereich aktivieren", ENABLE_OUTGOING="Ausgehenden Bereich aktivieren",
    ENABLE_NOTIFICATIONS="Hinweisbereich aktivieren", ENABLE_NAMEPLATES="Kampftext an Namensplaketten aktivieren",
    SHOW_DAMAGE="Schaden anzeigen", SHOW_HEALING="Heilung anzeigen", SHOW_MISSES="Verfehlt / Vermeidung anzeigen",
    SHOW_PET_DAMAGE="Schaden des eigenen Begleiters einbeziehen", SHOW_INTERRUPTS="Erfolgreiche Unterbrechungen anzeigen",
    SHOW_DISPELS="Bannungen / Zauberraub anzeigen",
    MIN_IN_DAMAGE="Mindestwert eingehender Schaden", MIN_IN_HEAL="Mindestwert eingehende Heilung",
    MIN_OUT_DAMAGE="Mindestwert ausgehender Schaden", MIN_OUT_HEAL="Mindestwert ausgehende Heilung",
    HIDE_PERIODIC_DAMAGE="Periodischen Schaden ausblenden", HIDE_PERIODIC_HEALING="Periodische Heilung ausblenden",

    FONT_SIZE="Schriftgröße", DIRECTION="Scrollrichtung", DIR_UP="Nach oben", DIR_DOWN="Nach unten",
    SHORT_NUMBERS="Große Zahlen kürzen (12,4k)", SHOW_SPELL_NAME="Zaubernamen anzeigen",
    SHOW_SPELL_ICON="Zauber-Icons anzeigen", SCHOOL_COLORS="Ausgehenden Schaden nach Magieschule färben",
    CRIT_SCALE="Größe kritischer Treffer", MESSAGE_LIFETIME="Anzeigedauer",
    SCROLL_SPEED="Scrollgeschwindigkeit", MAX_MESSAGES="Maximale Nachrichten pro Bereich",
    UNLOCK_AREAS="Scrollbereiche entsperren und anzeigen", RESET_AREAS="Positionen zurücksetzen",
    TEST_TEXT="Kampftext testen",

    INCOMING="Eingehend", OUTGOING="Ausgehend", NOTIFICATIONS="Hinweise",
    MELEE="Nahkampf", INTERRUPT="Unterbrochen", DISPEL="Gebannt", ABSORB="Absorbiert",
    ANCHORS_ON="Scrollbereiche entsperrt.", ANCHORS_OFF="Scrollbereiche gesperrt.",
    FOREVER_NOTE="Die erste Beta nutzt abgesicherte Daten aus CombatLogGetCurrentEventInfo und filtert bewusst auf Spieler und eigenen Begleiter. Die Forever-Combat-Log-Payloads müssen noch ingame geprüft werden.",
}

local S = de and DE or EN
function A:T(k) return S[k] or EN[k] or k end
