import critbits, unicode, sugar, options, sequtils
import ui, window, generalautocomplete, bufferstatus, gapbuffer, unicodeext, color, editorstatus, movement

type SuggestionWindow* = object
  identifierDictionary: CritBitTree[void]
  oldLine: seq[Rune]
  inputWord: seq[Rune]
  firstColumn, lastColumn: int
  suggestoins: seq[seq[Rune]]
  selectedSuggestion: int
  popUpWindow: Window

proc selectedWordOrInputWord(suggestionWindow: SuggestionWindow): seq[Rune] =
  if suggestionWindow.selectedSuggestion == -1:
    suggestionWindow.inputWord
  else:
    suggestionWindow.suggestoins[suggestionWindow.selectedSuggestion]

proc newLine*(suggestionWindow: SuggestionWindow): seq[Rune] =
  suggestionWindow.oldLine.dup(proc (r: var seq[Rune]) = r[suggestionWindow.firstColumn .. suggestionWindow.lastColumn] = suggestionWindow.selectedWordOrInputWord)

proc close*(suggestionWindow: var SuggestionWindow) =
  suggestionWindow.popUpWindow.deleteWindow

proc canHandleInSuggestionWindow*(key: Rune): bool {.inline.} =
  isTabKey(key) or isShiftTab(key) or isUpKey(key) or isDownKey(key) or isPageUpKey(key) or isPageDownKey(key)

proc handleKeyInSuggestionWindow*(suggestionWindow: var SuggestionWindow, bufStatus: var BufferStatus, windowNode: var WindowNode, key: Rune) =
  doAssert(canHandleInSuggestionWindow(key))

  # Check whether the selected suggestion is changed.
  let prevSuggestion = suggestionWindow.selectedSuggestion

  if isTabKey(key) or isDownKey(key):
    inc(suggestionWindow.selectedSuggestion)
  elif isShiftTab(key) or isUpKey(key):
    dec(suggestionWindow.selectedSuggestion)
  elif isPageDownkey(key):
    suggestionWindow.selectedSuggestion += suggestionWindow.popUpWindow.height - 1
  elif isPageUpKey(key):
    suggestionWindow.selectedSuggestion -= suggestionWindow.popUpWindow.height - 1

  suggestionWindow.selectedSuggestion = suggestionWindow.selectedSuggestion.clamp(0, suggestionWindow.suggestoins.high)

  if suggestionWindow.selectedSuggestion != prevSuggestion:
    # The selected suggestoin is changed.
    # Update the buffer without recording the change.
    bufStatus.moveToBackwardWord(windowNode)
    bufStatus.buffer.assign(suggestionWindow.newLine, windowNode.currentLine, false)
    bufStatus.moveToForwardAfterWord(windowNode)

proc initSuggestionWindow*(text, word, currentLineText: seq[Rune], firstColumn, lastColumn: int): Option[SuggestionWindow] =
  var suggestionWindow: SuggestionWindow

  suggestionwindow.identifierDictionary = makeIdentifierDictionary(text)
  suggestionwindow.inputWord = word
  suggestionwindow.firstColumn = firstColumn
  suggestionwindow.lastColumn = lastColumn
  suggestionwindow.suggestoins = collectSuggestions(suggestionwindow.identifierDictionary, word)

  if suggestionwindow.suggestoins.len == 0: return none(SuggestionWindow)

  suggestionwindow.selectedSuggestion = -1
  suggestionwindow.oldLine = currentLineText

  return some(suggestionWindow)

proc extractWordAfterCursor(bufStatus: BufferStatus, windowNode: WindowNode): Option[tuple[word: seq[Rune], first, last: int]] =
  if windowNode.currentColumn - 1 < 0: return
  extractNeighborWord(bufStatus.buffer[windowNode.currentLine], windowNode.currentColumn - 1)

proc wordExistsAfterCursor(bufStatus: BufferStatus, windowNode: WindowNode): bool =
  if windowNode.currentColumn == 0: return false
  let wordFirstLast = extractWordAfterCursor(bufStatus, windowNode)
  wordFirstLast.isSome and wordFirstLast.get.word.len > 0

proc buildSuggestionWindow*(bufStatus: BufferStatus, windowNode: WindowNode): Option[SuggestionWindow] =
  let (word, firstColumn, lastColumn) = extractWordAfterCursor(bufStatus, windowNode).get

  # Eliminate the word on the cursor.
  let
    line = windowNode.currentLine
    column = windowNode.currentColumn - 1
    lastDeletedIndex = bufStatus.buffer.calcIndexInEntireBuffer(line, column, true)
    firstDeletedIndex = lastDeletedIndex - word.len + 1
    text = bufStatus.buffer.toRunes.dup(delete(firstDeletedIndex, lastDeletedIndex))

  initSuggestionWindow(text, word, bufStatus.buffer[windowNode.currentLine], firstColumn, lastColumn)

proc tryOpenSuggestionWindow*(bufStatus: BufferStatus, windowNode: WindowNode): Option[SuggestionWindow] =
  if wordExistsAfterCursor(bufStatus, windowNode):
    return buildSuggestionWindow(bufStatus, windowNode)

proc calcSuggestionWindowPosition*(suggestionWindow: SuggestionWindow, windowNode: WindowNode): tuple[y, x: int] =
  let
    line = windowNode.currentLine
    column = suggestionWindow.firstColumn
    (absoluteY, absoluteX) = windowNode.absolutePosition(line, column)
    diffY = 1
    leftMargin = 1
  return (absoluteY + diffY, absoluteX - leftMargin)

proc writeSuggestionWindow*(suggestionWindow: var SuggestionWindow, y, x: int) =
  let
    height = suggestionwindow.suggestoins.len
    width = suggestionwindow.suggestoins.map(item => item.len).max + 2

  if suggestionwindow.popUpWindow == nil:
    suggestionwindow.popUpWindow = initWindow(height, width, y, x, EditorColorPair.popUpWindow)
  else:
    suggestionwindow.popUpWindow.height = height
    suggestionwindow.popUpWindow.width = width
    suggestionwindow.popUpWindow.y = y
    suggestionwindow.popUpWindow.x = x

  var popUpWindow = suggestionWindow.popUpWindow
  popUpWindow.writePopUpWindow(popUpWindow.height, popUpWindow.width, popUpWindow.y, popUpWindow.x, suggestionWindow.selectedSuggestion, suggestionWindow.suggestoins)

proc isLineChanged*(suggestionWindow: SuggestionWindow): bool {.inline.} =
  suggestionWindow.newLine != suggestionWindow.oldLine