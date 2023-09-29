local file = fs.open("logging.log", "w")
file.writeLine("Program started at " .. textutils.formatTime(os.time(), false) .. " (" .. os.time() .. ").")
file.close()

shell.run("main")
