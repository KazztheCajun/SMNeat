
local backgroundColor = 0xD0FFFFFF
local black = 0xFF000000
while true do
    local x = memory.readbyte(0x6D)
    local y = memory.readbyte(0x00B5)
    local screen = memory.readbyte(0x86)
    local state = memory.readbyte(0x000E)
    local float = memory.readbyte(0x001D)
    local dir = memory.readbyte(0x0045)
    local speed = memory.readbyte(0x0057)
    local absSpeed = memory.readbyte(0x0700)
    local enemy1 = memory.readbyte(0x1E)
    local enemy2 = memory.readbyte(0x1F)
    local enemy3 = memory.readbyte(0x20) 
    local enemy4 = memory.readbyte(0x21)
    local enemy5 = memory.readbyte(0x22)
    gui.drawBox(0, 0, 300, 38, backgroundColor, backgroundColor)
    gui.drawText(0, 0, "Player level X: ".. (x * 255) + screen .. " | Y: " .. y, black , 5)
    gui.drawText(0, 12,"Player State: " .. state .. "| Direction: " .. dir, black , 5)
    -- gui.drawText(0, 24, "Enemys: " .. enemy1 .. " | " .. enemy2 .. " | " .. enemy3 .. " | " .. enemy4 .. " | " .. enemy5, black , 11)
    gui.drawText(0, 24, "Speed: " .. speed .. " | Abs Speed " .. absSpeed, black, 5)


    emu.frameadvance()
end