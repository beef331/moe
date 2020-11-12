import unicode

proc saveInt(a: BiggestInt): string = discard

proc saveString(a: string): string = discard

proc saveBool(a: bool): string = discard

proc saveFloat(a: BiggestFloat): string = discard

proc getString(a: string, len: int, buf: string, pos: int): string = discard

proc getFloat(buf: string, pos: BiggestInt): BiggestFloat = discard

proc getInt(buf: string, pos: BiggestInt): BiggestInt = discard

import strutils

proc addToBuffer*[T](a: T, buf: var string) =
  when T is object or T is tuple or T is ref object:
    when T is ref object:
      addToBuffer(a.isNil, buf)
      if a.isNil: return
      for field in a[].fields:
        addToBuffer(field, buf)
    else:
      for field in a.fields:
        addToBuffer(field, buf)
  elif T is seq:
    addToBuffer(a.len, buf)
    for x in a:
      addToBuffer(x, buf)
  elif T is array:
    for x in a:
      addToBuffer(x, buf)
  elif T is SomeFloat:
    buf &= saveFloat(a.BiggestFloat)
  elif T is SomeOrdinal:
    buf &= saveInt(a.BiggestInt)
  elif T is string:
    buf &= saveString(a)


proc getFromBuffer*(buff: string, T: typedesc, pos: var BiggestInt): T=
  if(pos > buff.len): echo "Buffer smaller than datatype requested"
  when T is object or T is tuple or T is ref object:
    when T is ref object:
      let isNil = getFromBuffer(buff, bool, pos)
      if isNil: 
        return nil
      else: result = T()
      for field in result[].fields:
        field = getFromBuffer(buff, field.typeof, pos)
    else:
      for field in result.fields:
        field = getFromBuffer(buff, field.typeof, pos)
  elif T is seq:
    result.setLen(getFromBuffer(buff, int, pos))
    for x in result.mitems:
      x = getFromBuffer(buff, typeof(x), pos)
  elif T is array:
    for x in result.mitems:
      x = getFromBuffer(buff, typeof(x), pos)
  elif T is SomeFloat:
    result = getFloat(buff, pos).T
    pos += sizeof(BiggestInt)
  elif T is SomeOrdinal:
    result = getInt(buff, pos).T
    pos += sizeof(BiggestInt)
  elif T is string:
    let len = getFromBuffer(buff, BiggestInt, pos)
    result = buff[pos..<(pos + len)]
    pos += len

import macros
macro exportToNim(input: untyped): untyped=
  let 
    exposed = copy(input)
    hasRetVal = input[3][0].kind != nnkEmpty
  if exposed[0].kind == nnkPostfix:
    exposed[0][0] = ident($exposed[0][0] & "Exported")
  else:
    exposed[0] = postfix(ident($exposed[0] & "Exported"), "*")
  if hasRetVal:
    exposed[3][0] = ident("string")

  if exposed[3].len > 2:
    exposed[3].del(2, exposed[3].len - 2)
  if exposed[3].len > 1:
    exposed[3][1] = newIdentDefs(ident("parameters"), ident("string"))
  
  let
    buffIdent = ident("parameters")
    posIdent = ident("pos")
  var
    params: seq[NimNode]
    expBody = newStmtList().add quote do:
      var `posIdent`: BiggestInt = 0
  for identDefs in input[3][1..^1]:
    let idType = identDefs[^2]
    for param in identDefs[0..^3]:
      params.add param
      expBody.add quote do:
        let `param` = getFromBuffer(`buffIdent`, `idType`, `posIdent`)
  let procName = if input[0].kind == nnkPostfix: input[0][0] else: input[0]
  if hasRetVal:
    expBody.add quote do:
      `procName`().addToBuffer(result)
    if params.len > 0: expBody[^1][0][0].add params
  else:
    expBody.add quote do:
      `procName`()
    if params.len > 0: expBody[^1].add params
  exposed[^1] = expBody
  result = newStmtList(input, exposed)

type
  ColorTheme* = enum
    config = 0, vscode = 1, dark = 2, light = 3, vivid = 4

type
  CursorType* = enum
    blinkBlock = 0, noneBlinkBlock = 1, blinkIbeam = 2, noneBlinkIbeam = 3

type
  DebugWorkSpaceSettings* = object
    enable*: bool
    numOfWorkSpaces*: bool
    currentWorkSpaceIndex*: bool

type
  DebugWindowNodeSettings* = object
    enable*: bool
    currentWindow*: bool
    index*: bool
    windowIndex*: bool
    bufferIndex*: bool
    parentIndex*: bool
    childLen*: bool
    splitType*: bool
    haveCursesWin*: bool
    y*: bool
    x*: bool
    h*: bool
    w*: bool
    currentLine*: bool
    currentColumn*: bool
    expandedColumn*: bool
    cursor*: bool

type
  DebugBufferStatusSettings* = object
    enable*: bool
    bufferIndex*: bool
    path*: bool
    openDir*: bool
    currentMode*: bool
    prevMode*: bool
    language*: bool
    encoding*: bool
    countChange*: bool
    cmdLoop*: bool
    lastSaveTime*: bool
    bufferLen*: bool

type
  DebugModeSettings* = object
    workSpace*: DebugWorkSpaceSettings
    windowNode*: DebugWindowNodeSettings
    bufStatus*: DebugBufferStatusSettings

type
  NotificationSettings* = object
    screenNotifications*: bool
    logNotifications*: bool
    autoBackupScreenNotify*: bool
    autoBackupLogNotify*: bool
    autoSaveScreenNotify*: bool
    autoSaveLogNotify*: bool
    yankScreenNotify*: bool
    yankLogNotify*: bool
    deleteScreenNotify*: bool
    deleteLogNotify*: bool
    saveScreenNotify*: bool
    saveLogNotify*: bool
    workspaceScreenNotify*: bool
    workspaceLogNotify*: bool
    quickRunScreenNotify*: bool
    quickRunLogNotify*: bool
    buildOnSaveScreenNotify*: bool
    buildOnSaveLogNotify*: bool
    filerScreenNotify*: bool
    filerLogNotify*: bool
    restoreScreenNotify*: bool
    restoreLogNotify*: bool

type
  BuildOnSaveSettings* = object
    enable*: bool
    workspaceRoot*: seq[Rune]
    command*: seq[Rune]

type
  QuickRunSettings* = object
    saveBufferWhenQuickRun*: bool
    command*: string
    timeout*: int
    nimAdvancedCommand*: string
    ClangOptions*: string
    CppOptions*: string
    NimOptions*: string
    shOptions*: string
    bashOptions*: string

type
  AutoBackupSettings* = object
    enable*: bool
    idleTime*: int
    interval*: int
    backupDir*: seq[Rune]
    dirToExclude*: seq[seq[Rune]]

type
  FilerSettings = object
    showIcons*: bool

type
  WorkSpaceSettings = object
    workSpaceLine*: bool

type
  StatusBarSettings* = object
    enable*: bool
    merge*: bool
    mode*: bool
    filename*: bool
    chanedMark*: bool
    line*: bool
    column*: bool
    characterEncoding*: bool
    language*: bool
    directory*: bool
    multipleStatusBar*: bool
    gitbranchName*: bool
    showGitInactive*: bool
    showModeInactive*: bool

type
  TabLineSettings* = object
    useTab*: bool
    allbuffer*: bool

type
  EditorViewSettings* = object
    lineNumber*: bool
    currentLineNumber*: bool
    cursorLine*: bool
    indentationLines*: bool
    tabStop*: int

type
  AutocompleteSettings* = object
    enable*: bool

proc editorBgComphexCol(parameters: string) =
  discard
proc editorBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  editorBgComphexCol(params)
proc lineNumComphexCol(parameters: string) =
  discard
proc lineNum(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  lineNumComphexCol(params)
proc lineNumBgComphexCol(parameters: string) =
  discard
proc lineNumBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  lineNumBgComphexCol(params)
proc currentLineNumComphexCol(parameters: string) =
  discard
proc currentLineNum(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  currentLineNumComphexCol(params)
proc currentLineNumBgComphexCol(parameters: string) =
  discard
proc currentLineNumBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  currentLineNumBgComphexCol(params)
proc statusBarNormalModeComphexCol(parameters: string) =
  discard
proc statusBarNormalMode(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarNormalModeComphexCol(params)
proc statusBarNormalModeBgComphexCol(parameters: string) =
  discard
proc statusBarNormalModeBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarNormalModeBgComphexCol(params)
proc statusBarModeNormalModeComphexCol(parameters: string) =
  discard
proc statusBarModeNormalMode(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarModeNormalModeComphexCol(params)
proc statusBarModeNormalModeBgComphexCol(parameters: string) =
  discard
proc statusBarModeNormalModeBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarModeNormalModeBgComphexCol(params)
proc statusBarNormalModeInactiveComphexCol(parameters: string) =
  discard
proc statusBarNormalModeInactive(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarNormalModeInactiveComphexCol(params)
proc statusBarNormalModeInactiveBgComphexCol(parameters: string) =
  discard
proc statusBarNormalModeInactiveBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarNormalModeInactiveBgComphexCol(params)
proc statusBarInsertModeComphexCol(parameters: string) =
  discard
proc statusBarInsertMode(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarInsertModeComphexCol(params)
proc statusBarInsertModeBgComphexCol(parameters: string) =
  discard
proc statusBarInsertModeBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarInsertModeBgComphexCol(params)
proc statusBarModeInsertModeComphexCol(parameters: string) =
  discard
proc statusBarModeInsertMode(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarModeInsertModeComphexCol(params)
proc statusBarModeInsertModeBgComphexCol(parameters: string) =
  discard
proc statusBarModeInsertModeBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarModeInsertModeBgComphexCol(params)
proc statusBarInsertModeInactiveComphexCol(parameters: string) =
  discard
proc statusBarInsertModeInactive(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarInsertModeInactiveComphexCol(params)
proc statusBarInsertModeInactiveBgComphexCol(parameters: string) =
  discard
proc statusBarInsertModeInactiveBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarInsertModeInactiveBgComphexCol(params)
proc statusBarVisualModeComphexCol(parameters: string) =
  discard
proc statusBarVisualMode(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarVisualModeComphexCol(params)
proc statusBarVisualModeBgComphexCol(parameters: string) =
  discard
proc statusBarVisualModeBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarVisualModeBgComphexCol(params)
proc statusBarModeVisualModeComphexCol(parameters: string) =
  discard
proc statusBarModeVisualMode(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarModeVisualModeComphexCol(params)
proc statusBarModeVisualModeBgComphexCol(parameters: string) =
  discard
proc statusBarModeVisualModeBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarModeVisualModeBgComphexCol(params)
proc statusBarVisualModeInactiveComphexCol(parameters: string) =
  discard
proc statusBarVisualModeInactive(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarVisualModeInactiveComphexCol(params)
proc statusBarVisualModeInactiveBgComphexCol(parameters: string) =
  discard
proc statusBarVisualModeInactiveBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarVisualModeInactiveBgComphexCol(params)
proc statusBarReplaceModeComphexCol(parameters: string) =
  discard
proc statusBarReplaceMode(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarReplaceModeComphexCol(params)
proc statusBarReplaceModeBgComphexCol(parameters: string) =
  discard
proc statusBarReplaceModeBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarReplaceModeBgComphexCol(params)
proc statusBarModeReplaceModeComphexCol(parameters: string) =
  discard
proc statusBarModeReplaceMode(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarModeReplaceModeComphexCol(params)
proc statusBarModeReplaceModeBgComphexCol(parameters: string) =
  discard
proc statusBarModeReplaceModeBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarModeReplaceModeBgComphexCol(params)
proc statusBarReplaceModeInactiveComphexCol(parameters: string) =
  discard
proc statusBarReplaceModeInactive(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarReplaceModeInactiveComphexCol(params)
proc statusBarReplaceModeInactiveBgComphexCol(parameters: string) =
  discard
proc statusBarReplaceModeInactiveBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarReplaceModeInactiveBgComphexCol(params)
proc statusBarFilerModeComphexCol(parameters: string) =
  discard
proc statusBarFilerMode(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarFilerModeComphexCol(params)
proc statusBarFilerModeBgComphexCol(parameters: string) =
  discard
proc statusBarFilerModeBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarFilerModeBgComphexCol(params)
proc statusBarModeFilerModeComphexCol(parameters: string) =
  discard
proc statusBarModeFilerMode(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarModeFilerModeComphexCol(params)
proc statusBarModeFilerModeBgComphexCol(parameters: string) =
  discard
proc statusBarModeFilerModeBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarModeFilerModeBgComphexCol(params)
proc statusBarFilerModeInactiveComphexCol(parameters: string) =
  discard
proc statusBarFilerModeInactive(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarFilerModeInactiveComphexCol(params)
proc statusBarFilerModeInactiveBgComphexCol(parameters: string) =
  discard
proc statusBarFilerModeInactiveBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarFilerModeInactiveBgComphexCol(params)
proc statusBarExModeComphexCol(parameters: string) =
  discard
proc statusBarExMode(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarExModeComphexCol(params)
proc statusBarExModeBgComphexCol(parameters: string) =
  discard
proc statusBarExModeBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarExModeBgComphexCol(params)
proc statusBarModeExModeComphexCol(parameters: string) =
  discard
proc statusBarModeExMode(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarModeExModeComphexCol(params)
proc statusBarModeExModeBgComphexCol(parameters: string) =
  discard
proc statusBarModeExModeBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarModeExModeBgComphexCol(params)
proc statusBarExModeInactiveComphexCol(parameters: string) =
  discard
proc statusBarExModeInactive(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarExModeInactiveComphexCol(params)
proc statusBarExModeInactiveBgComphexCol(parameters: string) =
  discard
proc statusBarExModeInactiveBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarExModeInactiveBgComphexCol(params)
proc statusBarGitBranchComphexCol(parameters: string) =
  discard
proc statusBarGitBranch(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarGitBranchComphexCol(params)
proc statusBarGitBranchBgComphexCol(parameters: string) =
  discard
proc statusBarGitBranchBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  statusBarGitBranchBgComphexCol(params)
proc tabComphexCol(parameters: string) =
  discard
proc tab(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  tabComphexCol(params)
proc tabBgComphexCol(parameters: string) =
  discard
proc tabBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  tabBgComphexCol(params)
proc currentTabComphexCol(parameters: string) =
  discard
proc currentTab(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  currentTabComphexCol(params)
proc currentTabBgComphexCol(parameters: string) =
  discard
proc currentTabBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  currentTabBgComphexCol(params)
proc commandBarComphexCol(parameters: string) =
  discard
proc commandBar(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  commandBarComphexCol(params)
proc commandBarBgComphexCol(parameters: string) =
  discard
proc commandBarBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  commandBarBgComphexCol(params)
proc errorMessageComphexCol(parameters: string) =
  discard
proc errorMessage(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  errorMessageComphexCol(params)
proc errorMessageBgComphexCol(parameters: string) =
  discard
proc errorMessageBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  errorMessageBgComphexCol(params)
proc searchResultComphexCol(parameters: string) =
  discard
proc searchResult(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  searchResultComphexCol(params)
proc searchResultBgComphexCol(parameters: string) =
  discard
proc searchResultBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  searchResultBgComphexCol(params)
proc visualModeComphexCol(parameters: string) =
  discard
proc visualMode(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  visualModeComphexCol(params)
proc visualModeBgComphexCol(parameters: string) =
  discard
proc visualModeBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  visualModeBgComphexCol(params)
proc defaultCharComphexCol(parameters: string) =
  discard
proc defaultChar(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  defaultCharComphexCol(params)
proc gtKeywordComphexCol(parameters: string) =
  discard
proc gtKeyword(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  gtKeywordComphexCol(params)
proc gtFunctionNameComphexCol(parameters: string) =
  discard
proc gtFunctionName(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  gtFunctionNameComphexCol(params)
proc gtBooleanComphexCol(parameters: string) =
  discard
proc gtBoolean(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  gtBooleanComphexCol(params)
proc gtStringLitComphexCol(parameters: string) =
  discard
proc gtStringLit(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  gtStringLitComphexCol(params)
proc gtSpecialVarComphexCol(parameters: string) =
  discard
proc gtSpecialVar(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  gtSpecialVarComphexCol(params)
proc gtBuiltinComphexCol(parameters: string) =
  discard
proc gtBuiltin(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  gtBuiltinComphexCol(params)
proc gtDecNumberComphexCol(parameters: string) =
  discard
proc gtDecNumber(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  gtDecNumberComphexCol(params)
proc gtCommentComphexCol(parameters: string) =
  discard
proc gtComment(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  gtCommentComphexCol(params)
proc gtLongCommentComphexCol(parameters: string) =
  discard
proc gtLongComment(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  gtLongCommentComphexCol(params)
proc gtWhitespaceComphexCol(parameters: string) =
  discard
proc gtWhitespace(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  gtWhitespaceComphexCol(params)
proc gtPreprocessorComphexCol(parameters: string) =
  discard
proc gtPreprocessor(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  gtPreprocessorComphexCol(params)
proc currentFileComphexCol(parameters: string) =
  discard
proc currentFile(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  currentFileComphexCol(params)
proc currentFileBgComphexCol(parameters: string) =
  discard
proc currentFileBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  currentFileBgComphexCol(params)
proc fileComphexCol(parameters: string) =
  discard
proc file(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  fileComphexCol(params)
proc fileBgComphexCol(parameters: string) =
  discard
proc fileBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  fileBgComphexCol(params)
proc dirComphexCol(parameters: string) =
  discard
proc dir(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  dirComphexCol(params)
proc dirBgComphexCol(parameters: string) =
  discard
proc dirBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  dirBgComphexCol(params)
proc pcLinkComphexCol(parameters: string) =
  discard
proc pcLink(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  pcLinkComphexCol(params)
proc pcLinkBgComphexCol(parameters: string) =
  discard
proc pcLinkBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  pcLinkBgComphexCol(params)
proc popUpWindowComphexCol(parameters: string) =
  discard
proc popUpWindow(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  popUpWindowComphexCol(params)
proc popUpWindowBgComphexCol(parameters: string) =
  discard
proc popUpWindowBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  popUpWindowBgComphexCol(params)
proc popUpWinCurrentLineComphexCol(parameters: string) =
  discard
proc popUpWinCurrentLine(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  popUpWinCurrentLineComphexCol(params)
proc popUpWinCurrentLineBgComphexCol(parameters: string) =
  discard
proc popUpWinCurrentLineBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  popUpWinCurrentLineBgComphexCol(params)
proc replaceTextComphexCol(parameters: string) =
  discard
proc replaceText(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  replaceTextComphexCol(params)
proc replaceTextBgComphexCol(parameters: string) =
  discard
proc replaceTextBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  replaceTextBgComphexCol(params)
proc parenTextComphexCol(parameters: string) =
  discard
proc parenText(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  parenTextComphexCol(params)
proc parenTextBgComphexCol(parameters: string) =
  discard
proc parenTextBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  parenTextBgComphexCol(params)
proc currentWordComphexCol(parameters: string) =
  discard
proc currentWord(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  currentWordComphexCol(params)
proc currentWordBgComphexCol(parameters: string) =
  discard
proc currentWordBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  currentWordBgComphexCol(params)
proc highlightFullWidthSpaceComphexCol(parameters: string) =
  discard
proc highlightFullWidthSpace(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  highlightFullWidthSpaceComphexCol(params)
proc highlightFullWidthSpaceBgComphexCol(parameters: string) =
  discard
proc highlightFullWidthSpaceBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  highlightFullWidthSpaceBgComphexCol(params)
proc highlightTrailingSpacesComphexCol(parameters: string) =
  discard
proc highlightTrailingSpaces(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  highlightTrailingSpacesComphexCol(params)
proc highlightTrailingSpacesBgComphexCol(parameters: string) =
  discard
proc highlightTrailingSpacesBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  highlightTrailingSpacesBgComphexCol(params)
proc workSpaceBarComphexCol(parameters: string) =
  discard
proc workSpaceBar(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  workSpaceBarComphexCol(params)
proc workSpaceBarBgComphexCol(parameters: string) =
  discard
proc workSpaceBarBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  workSpaceBarBgComphexCol(params)
proc reservedWordComphexCol(parameters: string) =
  discard
proc reservedWord(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  reservedWordComphexCol(params)
proc reservedWordBgComphexCol(parameters: string) =
  discard
proc reservedWordBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  reservedWordBgComphexCol(params)
proc currentHistoryComphexCol(parameters: string) =
  discard
proc currentHistory(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  currentHistoryComphexCol(params)
proc currentHistoryBgComphexCol(parameters: string) =
  discard
proc currentHistoryBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  currentHistoryBgComphexCol(params)
proc addedLineComphexCol(parameters: string) =
  discard
proc addedLine(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  addedLineComphexCol(params)
proc addedLineBgComphexCol(parameters: string) =
  discard
proc addedLineBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  addedLineBgComphexCol(params)
proc deletedLineComphexCol(parameters: string) =
  discard
proc deletedLine(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  deletedLineComphexCol(params)
proc deletedLineBgComphexCol(parameters: string) =
  discard
proc deletedLineBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  deletedLineBgComphexCol(params)
proc currentSettingComphexCol(parameters: string) =
  discard
proc currentSetting(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  currentSettingComphexCol(params)
proc currentSettingBgComphexCol(parameters: string) =
  discard
proc currentSettingBg(hexCol: string) =
  var params = ""
  addToBuffer(hexCol, params)
  currentSettingBgComphexCol(params)
proc editorColorThemeCompval(parameters: string) =
  discard
proc editorColorTheme(val: ColorTheme) =
  var params = ""
  addToBuffer(val, params)
  editorColorThemeCompval(params)
proc statusBarenableCompval(parameters: string) =
  discard
proc statusBarenable(val: bool) =
  var params = ""
  addToBuffer(val, params)
  statusBarenableCompval(params)
proc statusBarmergeCompval(parameters: string) =
  discard
proc statusBarmerge(val: bool) =
  var params = ""
  addToBuffer(val, params)
  statusBarmergeCompval(params)
proc statusBarmodeCompval(parameters: string) =
  discard
proc statusBarmode(val: bool) =
  var params = ""
  addToBuffer(val, params)
  statusBarmodeCompval(params)
proc statusBarfilenameCompval(parameters: string) =
  discard
proc statusBarfilename(val: bool) =
  var params = ""
  addToBuffer(val, params)
  statusBarfilenameCompval(params)
proc statusBarchanedMarkCompval(parameters: string) =
  discard
proc statusBarchanedMark(val: bool) =
  var params = ""
  addToBuffer(val, params)
  statusBarchanedMarkCompval(params)
proc statusBarlineCompval(parameters: string) =
  discard
proc statusBarline(val: bool) =
  var params = ""
  addToBuffer(val, params)
  statusBarlineCompval(params)
proc statusBarcolumnCompval(parameters: string) =
  discard
proc statusBarcolumn(val: bool) =
  var params = ""
  addToBuffer(val, params)
  statusBarcolumnCompval(params)
proc statusBarcharacterEncodingCompval(parameters: string) =
  discard
proc statusBarcharacterEncoding(val: bool) =
  var params = ""
  addToBuffer(val, params)
  statusBarcharacterEncodingCompval(params)
proc statusBarlanguageCompval(parameters: string) =
  discard
proc statusBarlanguage(val: bool) =
  var params = ""
  addToBuffer(val, params)
  statusBarlanguageCompval(params)
proc statusBardirectoryCompval(parameters: string) =
  discard
proc statusBardirectory(val: bool) =
  var params = ""
  addToBuffer(val, params)
  statusBardirectoryCompval(params)
proc statusBarmultipleStatusBarCompval(parameters: string) =
  discard
proc statusBarmultipleStatusBar(val: bool) =
  var params = ""
  addToBuffer(val, params)
  statusBarmultipleStatusBarCompval(params)
proc statusBargitbranchNameCompval(parameters: string) =
  discard
proc statusBargitbranchName(val: bool) =
  var params = ""
  addToBuffer(val, params)
  statusBargitbranchNameCompval(params)
proc statusBarshowGitInactiveCompval(parameters: string) =
  discard
proc statusBarshowGitInactive(val: bool) =
  var params = ""
  addToBuffer(val, params)
  statusBarshowGitInactiveCompval(params)
proc statusBarshowModeInactiveCompval(parameters: string) =
  discard
proc statusBarshowModeInactive(val: bool) =
  var params = ""
  addToBuffer(val, params)
  statusBarshowModeInactiveCompval(params)
proc tabLineuseTabCompval(parameters: string) =
  discard
proc tabLineuseTab(val: bool) =
  var params = ""
  addToBuffer(val, params)
  tabLineuseTabCompval(params)
proc tabLineallbufferCompval(parameters: string) =
  discard
proc tabLineallbuffer(val: bool) =
  var params = ""
  addToBuffer(val, params)
  tabLineallbufferCompval(params)
proc viewlineNumberCompval(parameters: string) =
  discard
proc viewlineNumber(val: bool) =
  var params = ""
  addToBuffer(val, params)
  viewlineNumberCompval(params)
proc viewcurrentLineNumberCompval(parameters: string) =
  discard
proc viewcurrentLineNumber(val: bool) =
  var params = ""
  addToBuffer(val, params)
  viewcurrentLineNumberCompval(params)
proc viewcursorLineCompval(parameters: string) =
  discard
proc viewcursorLine(val: bool) =
  var params = ""
  addToBuffer(val, params)
  viewcursorLineCompval(params)
proc viewindentationLinesCompval(parameters: string) =
  discard
proc viewindentationLines(val: bool) =
  var params = ""
  addToBuffer(val, params)
  viewindentationLinesCompval(params)
proc viewtabStopCompval(parameters: string) =
  discard
proc viewtabStop(val: int) =
  var params = ""
  addToBuffer(val, params)
  viewtabStopCompval(params)
proc syntaxCompval(parameters: string) =
  discard
proc syntax(val: bool) =
  var params = ""
  addToBuffer(val, params)
  syntaxCompval(params)
proc autoCloseParenCompval(parameters: string) =
  discard
proc autoCloseParen(val: bool) =
  var params = ""
  addToBuffer(val, params)
  autoCloseParenCompval(params)
proc autoIndentCompval(parameters: string) =
  discard
proc autoIndent(val: bool) =
  var params = ""
  addToBuffer(val, params)
  autoIndentCompval(params)
proc tabStopCompval(parameters: string) =
  discard
proc tabStop(val: int) =
  var params = ""
  addToBuffer(val, params)
  tabStopCompval(params)
proc ignorecaseCompval(parameters: string) =
  discard
proc ignorecase(val: bool) =
  var params = ""
  addToBuffer(val, params)
  ignorecaseCompval(params)
proc smartcaseCompval(parameters: string) =
  discard
proc smartcase(val: bool) =
  var params = ""
  addToBuffer(val, params)
  smartcaseCompval(params)
proc disableChangeCursorCompval(parameters: string) =
  discard
proc disableChangeCursor(val: bool) =
  var params = ""
  addToBuffer(val, params)
  disableChangeCursorCompval(params)
proc defaultCursorCompval(parameters: string) =
  discard
proc defaultCursor(val: CursorType) =
  var params = ""
  addToBuffer(val, params)
  defaultCursorCompval(params)
proc normalModeCursorCompval(parameters: string) =
  discard
proc normalModeCursor(val: CursorType) =
  var params = ""
  addToBuffer(val, params)
  normalModeCursorCompval(params)
proc insertModeCursorCompval(parameters: string) =
  discard
proc insertModeCursor(val: CursorType) =
  var params = ""
  addToBuffer(val, params)
  insertModeCursorCompval(params)
proc autoSaveCompval(parameters: string) =
  discard
proc autoSave(val: bool) =
  var params = ""
  addToBuffer(val, params)
  autoSaveCompval(params)
proc autoSaveIntervalCompval(parameters: string) =
  discard
proc autoSaveInterval(val: int) =
  var params = ""
  addToBuffer(val, params)
  autoSaveIntervalCompval(params)
proc liveReloadOfConfCompval(parameters: string) =
  discard
proc liveReloadOfConf(val: bool) =
  var params = ""
  addToBuffer(val, params)
  liveReloadOfConfCompval(params)
proc incrementalSearchCompval(parameters: string) =
  discard
proc incrementalSearch(val: bool) =
  var params = ""
  addToBuffer(val, params)
  incrementalSearchCompval(params)
proc popUpWindowInExmodeCompval(parameters: string) =
  discard
proc popUpWindowInExmode(val: bool) =
  var params = ""
  addToBuffer(val, params)
  popUpWindowInExmodeCompval(params)
proc autoDeleteParenCompval(parameters: string) =
  discard
proc autoDeleteParen(val: bool) =
  var params = ""
  addToBuffer(val, params)
  autoDeleteParenCompval(params)
proc smoothScrollCompval(parameters: string) =
  discard
proc smoothScroll(val: bool) =
  var params = ""
  addToBuffer(val, params)
  smoothScrollCompval(params)
proc smoothScrollSpeedCompval(parameters: string) =
  discard
proc smoothScrollSpeed(val: int) =
  var params = ""
  addToBuffer(val, params)
  smoothScrollSpeedCompval(params)
proc systemClipboardCompval(parameters: string) =
  discard
proc systemClipboard(val: bool) =
  var params = ""
  addToBuffer(val, params)
  systemClipboardCompval(params)
proc buildOnSaveenableCompval(parameters: string) =
  discard
proc buildOnSaveenable(val: bool) =
  var params = ""
  addToBuffer(val, params)
  buildOnSaveenableCompval(params)
proc workSpaceworkSpaceLineCompval(parameters: string) =
  discard
proc workSpaceworkSpaceLine(val: bool) =
  var params = ""
  addToBuffer(val, params)
  workSpaceworkSpaceLineCompval(params)
proc filershowIconsCompval(parameters: string) =
  discard
proc filershowIcons(val: bool) =
  var params = ""
  addToBuffer(val, params)
  filershowIconsCompval(params)
proc autocompleteenableCompval(parameters: string) =
  discard
proc autocompleteenable(val: bool) =
  var params = ""
  addToBuffer(val, params)
  autocompleteenableCompval(params)
proc autoBackupenableCompval(parameters: string) =
  discard
proc autoBackupenable(val: bool) =
  var params = ""
  addToBuffer(val, params)
  autoBackupenableCompval(params)
proc autoBackupidleTimeCompval(parameters: string) =
  discard
proc autoBackupidleTime(val: int) =
  var params = ""
  addToBuffer(val, params)
  autoBackupidleTimeCompval(params)
proc autoBackupintervalCompval(parameters: string) =
  discard
proc autoBackupinterval(val: int) =
  var params = ""
  addToBuffer(val, params)
  autoBackupintervalCompval(params)
proc quickRunsaveBufferWhenQuickRunCompval(parameters: string) =
  discard
proc quickRunsaveBufferWhenQuickRun(val: bool) =
  var params = ""
  addToBuffer(val, params)
  quickRunsaveBufferWhenQuickRunCompval(params)
proc quickRuntimeoutCompval(parameters: string) =
  discard
proc quickRuntimeout(val: int) =
  var params = ""
  addToBuffer(val, params)
  quickRuntimeoutCompval(params)
proc notificationscreenNotificationsCompval(parameters: string) =
  discard
proc notificationscreenNotifications(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationscreenNotificationsCompval(params)
proc notificationlogNotificationsCompval(parameters: string) =
  discard
proc notificationlogNotifications(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationlogNotificationsCompval(params)
proc notificationautoBackupScreenNotifyCompval(parameters: string) =
  discard
proc notificationautoBackupScreenNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationautoBackupScreenNotifyCompval(params)
proc notificationautoBackupLogNotifyCompval(parameters: string) =
  discard
proc notificationautoBackupLogNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationautoBackupLogNotifyCompval(params)
proc notificationautoSaveScreenNotifyCompval(parameters: string) =
  discard
proc notificationautoSaveScreenNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationautoSaveScreenNotifyCompval(params)
proc notificationautoSaveLogNotifyCompval(parameters: string) =
  discard
proc notificationautoSaveLogNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationautoSaveLogNotifyCompval(params)
proc notificationyankScreenNotifyCompval(parameters: string) =
  discard
proc notificationyankScreenNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationyankScreenNotifyCompval(params)
proc notificationyankLogNotifyCompval(parameters: string) =
  discard
proc notificationyankLogNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationyankLogNotifyCompval(params)
proc notificationdeleteScreenNotifyCompval(parameters: string) =
  discard
proc notificationdeleteScreenNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationdeleteScreenNotifyCompval(params)
proc notificationdeleteLogNotifyCompval(parameters: string) =
  discard
proc notificationdeleteLogNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationdeleteLogNotifyCompval(params)
proc notificationsaveScreenNotifyCompval(parameters: string) =
  discard
proc notificationsaveScreenNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationsaveScreenNotifyCompval(params)
proc notificationsaveLogNotifyCompval(parameters: string) =
  discard
proc notificationsaveLogNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationsaveLogNotifyCompval(params)
proc notificationworkspaceScreenNotifyCompval(parameters: string) =
  discard
proc notificationworkspaceScreenNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationworkspaceScreenNotifyCompval(params)
proc notificationworkspaceLogNotifyCompval(parameters: string) =
  discard
proc notificationworkspaceLogNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationworkspaceLogNotifyCompval(params)
proc notificationquickRunScreenNotifyCompval(parameters: string) =
  discard
proc notificationquickRunScreenNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationquickRunScreenNotifyCompval(params)
proc notificationquickRunLogNotifyCompval(parameters: string) =
  discard
proc notificationquickRunLogNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationquickRunLogNotifyCompval(params)
proc notificationbuildOnSaveScreenNotifyCompval(parameters: string) =
  discard
proc notificationbuildOnSaveScreenNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationbuildOnSaveScreenNotifyCompval(params)
proc notificationbuildOnSaveLogNotifyCompval(parameters: string) =
  discard
proc notificationbuildOnSaveLogNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationbuildOnSaveLogNotifyCompval(params)
proc notificationfilerScreenNotifyCompval(parameters: string) =
  discard
proc notificationfilerScreenNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationfilerScreenNotifyCompval(params)
proc notificationfilerLogNotifyCompval(parameters: string) =
  discard
proc notificationfilerLogNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationfilerLogNotifyCompval(params)
proc notificationrestoreScreenNotifyCompval(parameters: string) =
  discard
proc notificationrestoreScreenNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationrestoreScreenNotifyCompval(params)
proc notificationrestoreLogNotifyCompval(parameters: string) =
  discard
proc notificationrestoreLogNotify(val: bool) =
  var params = ""
  addToBuffer(val, params)
  notificationrestoreLogNotifyCompval(params)
proc debugModeworkSpaceenableCompval(parameters: string) =
  discard
proc debugModeworkSpaceenable(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModeworkSpaceenableCompval(params)
proc debugModeworkSpacenumOfWorkSpacesCompval(parameters: string) =
  discard
proc debugModeworkSpacenumOfWorkSpaces(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModeworkSpacenumOfWorkSpacesCompval(params)
proc debugModeworkSpacecurrentWorkSpaceIndexCompval(parameters: string) =
  discard
proc debugModeworkSpacecurrentWorkSpaceIndex(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModeworkSpacecurrentWorkSpaceIndexCompval(params)
proc debugModewindowNodeenableCompval(parameters: string) =
  discard
proc debugModewindowNodeenable(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodeenableCompval(params)
proc debugModewindowNodecurrentWindowCompval(parameters: string) =
  discard
proc debugModewindowNodecurrentWindow(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodecurrentWindowCompval(params)
proc debugModewindowNodeindexCompval(parameters: string) =
  discard
proc debugModewindowNodeindex(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodeindexCompval(params)
proc debugModewindowNodewindowIndexCompval(parameters: string) =
  discard
proc debugModewindowNodewindowIndex(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodewindowIndexCompval(params)
proc debugModewindowNodebufferIndexCompval(parameters: string) =
  discard
proc debugModewindowNodebufferIndex(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodebufferIndexCompval(params)
proc debugModewindowNodeparentIndexCompval(parameters: string) =
  discard
proc debugModewindowNodeparentIndex(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodeparentIndexCompval(params)
proc debugModewindowNodechildLenCompval(parameters: string) =
  discard
proc debugModewindowNodechildLen(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodechildLenCompval(params)
proc debugModewindowNodesplitTypeCompval(parameters: string) =
  discard
proc debugModewindowNodesplitType(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodesplitTypeCompval(params)
proc debugModewindowNodehaveCursesWinCompval(parameters: string) =
  discard
proc debugModewindowNodehaveCursesWin(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodehaveCursesWinCompval(params)
proc debugModewindowNodeyCompval(parameters: string) =
  discard
proc debugModewindowNodey(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodeyCompval(params)
proc debugModewindowNodexCompval(parameters: string) =
  discard
proc debugModewindowNodex(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodexCompval(params)
proc debugModewindowNodehCompval(parameters: string) =
  discard
proc debugModewindowNodeh(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodehCompval(params)
proc debugModewindowNodewCompval(parameters: string) =
  discard
proc debugModewindowNodew(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodewCompval(params)
proc debugModewindowNodecurrentLineCompval(parameters: string) =
  discard
proc debugModewindowNodecurrentLine(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodecurrentLineCompval(params)
proc debugModewindowNodecurrentColumnCompval(parameters: string) =
  discard
proc debugModewindowNodecurrentColumn(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodecurrentColumnCompval(params)
proc debugModewindowNodeexpandedColumnCompval(parameters: string) =
  discard
proc debugModewindowNodeexpandedColumn(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodeexpandedColumnCompval(params)
proc debugModewindowNodecursorCompval(parameters: string) =
  discard
proc debugModewindowNodecursor(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModewindowNodecursorCompval(params)
proc debugModebufStatusenableCompval(parameters: string) =
  discard
proc debugModebufStatusenable(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModebufStatusenableCompval(params)
proc debugModebufStatusbufferIndexCompval(parameters: string) =
  discard
proc debugModebufStatusbufferIndex(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModebufStatusbufferIndexCompval(params)
proc debugModebufStatuspathCompval(parameters: string) =
  discard
proc debugModebufStatuspath(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModebufStatuspathCompval(params)
proc debugModebufStatusopenDirCompval(parameters: string) =
  discard
proc debugModebufStatusopenDir(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModebufStatusopenDirCompval(params)
proc debugModebufStatuscurrentModeCompval(parameters: string) =
  discard
proc debugModebufStatuscurrentMode(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModebufStatuscurrentModeCompval(params)
proc debugModebufStatusprevModeCompval(parameters: string) =
  discard
proc debugModebufStatusprevMode(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModebufStatusprevModeCompval(params)
proc debugModebufStatuslanguageCompval(parameters: string) =
  discard
proc debugModebufStatuslanguage(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModebufStatuslanguageCompval(params)
proc debugModebufStatusencodingCompval(parameters: string) =
  discard
proc debugModebufStatusencoding(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModebufStatusencodingCompval(params)
proc debugModebufStatuscountChangeCompval(parameters: string) =
  discard
proc debugModebufStatuscountChange(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModebufStatuscountChangeCompval(params)
proc debugModebufStatuscmdLoopCompval(parameters: string) =
  discard
proc debugModebufStatuscmdLoop(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModebufStatuscmdLoopCompval(params)
proc debugModebufStatuslastSaveTimeCompval(parameters: string) =
  discard
proc debugModebufStatuslastSaveTime(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModebufStatuslastSaveTimeCompval(params)
proc debugModebufStatusbufferLenCompval(parameters: string) =
  discard
proc debugModebufStatusbufferLen(val: bool) =
  var params = ""
  addToBuffer(val, params)
  debugModebufStatusbufferLenCompval(params)
proc highlightreplaceTextCompval(parameters: string) =
  discard
proc highlightreplaceText(val: bool) =
  var params = ""
  addToBuffer(val, params)
  highlightreplaceTextCompval(params)
proc highlightpairOfParenCompval(parameters: string) =
  discard
proc highlightpairOfParen(val: bool) =
  var params = ""
  addToBuffer(val, params)
  highlightpairOfParenCompval(params)
proc highlightcurrentWordCompval(parameters: string) =
  discard
proc highlightcurrentWord(val: bool) =
  var params = ""
  addToBuffer(val, params)
  highlightcurrentWordCompval(params)
proc highlightfullWidthSpaceCompval(parameters: string) =
  discard
proc highlightfullWidthSpace(val: bool) =
  var params = ""
  addToBuffer(val, params)
  highlightfullWidthSpaceCompval(params)
proc highlighttrailingSpacesCompval(parameters: string) =
  discard
proc highlighttrailingSpaces(val: bool) =
  var params = ""
  addToBuffer(val, params)
  highlighttrailingSpacesCompval(params)
