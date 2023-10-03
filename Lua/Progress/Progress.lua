
local backgroundColor = 0xD0FFFFFF
while true do
    local x = memory.readbyte(0x6D)
    local screen = memory.readbyte(0x86)
    local state = memory.readbyte(0x000E)
    local float = memory.readbyte(0x001D)
    local enemy1 = memory.readbyte(0x1E)
    local enemy2 = memory.readbyte(0x1F)
    local enemy3 = memory.readbyte(0x20) 
    local enemy4 = memory.readbyte(0x21)
    local enemy5 = memory.readbyte(0x22)
    gui.drawBox(0, 0, 300, 38, backgroundColor, backgroundColor)
    gui.drawText(0, 0, "Player level POS: ".. (x * 255) + screen, 0xFF000000 , 11)
    gui.drawText(0, 12,"Player State: " .. state .. " Float: " .. float, 0xFF000000 , 11)
    gui.drawText(0, 24, "Enemys: " .. enemy1 .. " | " .. enemy2 .. " | " .. enemy3 .. " | " .. enemy4 .. " | " .. enemy5, 0xFF000000 , 11)

    emu.frameadvance()
end