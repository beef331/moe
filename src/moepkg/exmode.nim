import strutils
import editorstatus, ui, normalmode, gapbuffer, fileutils

proc getCommand(commandWindow: var Window): seq[string] =
  var command = ""
  while true:
    commandWindow.erase
    commandWindow.write(0, 0, ":"&command)
    commandWindow.refresh
 
    let key = commandWindow.getkey
    
    if isResizeKey(key): continue
    if isEnterKey(key): break
    if isBackspaceKey(key):
      if command.len > 0: command.delete(command.high, command.high)
      continue
    if not key in 0..255: continue
 
    command &= chr(key)
 
  return command.splitWhitespace

proc writeNoWriteError(commandWindow: var Window) =
  commandWindow.erase
  commandWindow.write(0, 0, "Error: No write since last change", ColorPair.redDefault)
  commandWindow.refresh

proc exMode*(status: var EditorStatus) =
  let command = getCommand(status.commandWindow)

  if command.len == 1 and isDigit(command[0]):
    var line = command[0].parseInt-1
    if line < 0: line = 0
    if line >= status.buffer.len: line = status.buffer.high
    jumpLine(status, line)
    status.mode = Mode.normal
  elif command.len == 1 and command[0] == "w":
    saveFile(status.filename, status.buffer)
    status.countChange = 0
    status.mode = Mode.normal
  elif command.len == 1 and command[0] == "q":
    if status.countChange == 0: status.mode = Mode.quit
    else:
      writeNoWriteError(status.commandWindow)
      status.mode = Mode.normal
  elif command.len == 1 and command[0] == "wq":
    saveFile(status.filename, status.buffer)
    status.mode = Mode.quit
  elif command.len == 1 and command[0] == "q!":
    status.mode = Mode.quit
  else:
    status.mode = Mode.normal
