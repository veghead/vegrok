
Sub Main()
    'initialize theme attributes like titles, logos and overhang color
    initTheme()

    'prepare the screen for display and get ready to begin
    screen=preShowHomeScreen("", "")
    if screen=invalid then
        print "unexpected error in preShowHomeScreen"
        return
    end if

    'set to go, time to get started
    showHomeScreen(screen)
End Sub


Sub initTheme()
    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangOffsetSD_X = "72"
    theme.OverhangOffsetSD_Y = "31"
    theme.OverhangSliceSD = "pkg:/images/Overhang_Background_SD.png"
    theme.OverhangLogoSD  = "pkg:/images/Overhang_Logo_SD.png"

    theme.OverhangOffsetHD_X = "125"
    theme.OverhangOffsetHD_Y = "35"
    theme.OverhangSliceHD = "pkg:/images/Overhang_Background_HD.png"
    theme.OverhangLogoHD  = "pkg:/images/Overhang_Logo_HD.png"

    app.SetTheme(theme)
End Sub


Function preShowHomeScreen(breadA=invalid, breadB=invalid) As Object
    if validateParam(breadA, "roString", "preShowHomeScreen", true) = false return -1

    port=CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
    end if

    screen.SetListStyle("flat-category")
    screen.setAdDisplayMode("scale-to-fit")
    return screen
End Function



Function showAudioPlayer(episode As Object)
    if type(episode) <> "roAssociativeArray" then
        print "invalid data passed to showVideoScreen"
        return -1
    endif

    port = CreateObject("roMessagePort")
    player = CreateObject("roAudioPlayer")
    screen = CreateObject("roParagraphScreen")
    screen.SetTitle("Please Wait...")
    screen.Addheadertext(episode.title)
    screen.AddParagraph(episode.description)
    screen.AddButton(1, "Exit")
    screen.SetMessagePort(port)
    player.SetMessagePort(port)

    'screen.SetPositionNotificationPeriod(30)
    player.addcontent(episode)
    player.play()
    player.SetLoop(true)
    screen.Show()

    'Uncomment his line to dump the contents of the episode to be played
    PrintAA(episode)

    while true
        msg = wait(0, port)

        if type(msg) = "roParagraphScreenEvent" then
            if msg.isButtonPressed() then 
                return 0
            end if
        elseif type(msg) = "roAudioPlayerEvent" then
                if msg.isStatusMessage() then 
                    if msg.getmessage() = "start of play" then
                        screen.SetTitle("Playing Radio Meanness")
                        screen.Show()
                    end if
                    print "roAudioPlayerEvent: "; msg.getmessage() 
                endif
        else 
            print "Unexpected message class: "; type(msg)
        end if
    end while
End Function


Function preShowDetailScreen(breadA=invalid, breadB=invalid) As Object
    port=CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")
    screen.SetDescriptionStyle("video") 
    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
    end if

    return screen
End Function


Function showDetailScreen(screen As Object, showList As Object, showIndex as Integer) As Integer
    if validateParam(screen, "roSpringboardScreen", "showDetailScreen") = false return -1
    if validateParam(showList, "roArray", "showDetailScreen") = false return -1

    refreshShowDetail(screen, showList, showIndex)

    'remote key id's for left/right navigation
    remoteKeyLeft  = 4
    remoteKeyRight = 5
 
    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roSpringboardScreenEvent" then
            if msg.isScreenClosed()
                print "Screen closed"
                exit while
            else if msg.isRemoteKeyPressed() 
                print "Remote key pressed"
                if msg.GetIndex() = remoteKeyLeft then
                        showIndex = getPrevShow(showList, showIndex)
                        if showIndex <> -1
                            refreshShowDetail(screen, showList, showIndex)
                        end if
                else if msg.GetIndex() = remoteKeyRight
                    showIndex = getNextShow(showList, showIndex)
                        if showIndex <> -1
                           refreshShowDetail(screen, showList, showIndex)
                        end if
                endif
            else if msg.isButtonPressed() 
                print "ButtonPressed"
                print "ButtonPressed"
                if msg.GetIndex() = 1
                    PlayStart = RegRead(showList[showIndex].ContentId)
                    if PlayStart <> invalid then
                        showList[showIndex].PlayStart = PlayStart.ToInt()
                    endif
                    print "Resuming"
                    showVideoScreen(showList[showIndex])
                endif
                if msg.GetIndex() = 2
                    showList[showIndex].PlayStart = 0
                        print "Play"
                        print showList[showIndex].streamFormat
                    if showList[showIndex].streamFormat = "mp3"
                        showAudioPlayer(showList[showIndex])
                    else
                        showVideoScreen(showList[showIndex])
                    endif
                endif
                if msg.GetIndex() = 3
                endif
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
            end if
        else
            print "Unexpected message class: "; type(msg)
        end if
    end while
    return showIndex
End Function


Function refreshShowDetail(screen As Object, showList As Object, showIndex as Integer) As Integer
    if validateParam(screen, "roSpringboardScreen", "refreshShowDetail") = false return -1
    if validateParam(showList, "roArray", "refreshShowDetail") = false return -1

    show = showList[showIndex]

    'Uncomment this statement to dump the details for each show
    'PrintAA(show)

    screen.ClearButtons()
    screen.AddButton(1, "resume playing")    
    screen.AddButton(2, "play from beginning")    
    screen.SetContent(show)
    screen.Show()
End Function


Function getNextShow(showList As Object, showIndex As Integer) As Integer
    if validateParam(showList, "roArray", "getNextShow") = false return -1

    nextIndex = showIndex + 1
    if nextIndex >= showList.Count() or nextIndex < 0 then
       nextIndex = 0 
    end if

    show = showList[nextIndex]
    if validateParam(show, "roAssociativeArray", "getNextShow") = false return -1 

    return nextIndex
End Function


Function getPrevShow(showList As Object, showIndex As Integer) As Integer
    if validateParam(showList, "roArray", "getPrevShow") = false return -1 

    prevIndex = showIndex - 1
    if prevIndex < 0 or prevIndex >= showList.Count() then
        if showList.Count() > 0 then
            prevIndex = showList.Count() - 1 
        else
            return -1
        end if
    end if

    show = showList[prevIndex]
    if validateParam(show, "roAssociativeArray", "getPrevShow") = false return -1 

    return prevIndex
End Function



Function showHomeScreen(screen) As Integer
    if validateParam(screen, "roPosterScreen", "showHomeScreen") = false return -1

    topLevel = CreateObject("roArray",3, false)
    o = init_category_item()
    o.Title       = "Audio"
    o.Description = "Audio"
    o.ShortDescriptionLine1 = "Audio"
    o.SDPosterURL = "file://pkg:/images/audio.png"
    o.HDPosterURL = o.SDPosterURL
    topLevel.Push(o)
    o = init_category_item()
    o.Title       = "Video"
    o.Description = "Video"
    o.SDPosterURL = "file://pkg:/images/video.png"
    o.HDPosterURL = o.SDPosterURL
    o.ShortDescriptionLine1 = "Video"
    topLevel.Push(o)
    o = init_category_item()
    o.Title       = "Settings"
    o.Description = "Set Server IP address"
    o.SDPosterURL = "file://pkg:/images/settings.png"
    o.HDPosterURL = o.SDPosterURL
    o.ShortDescriptionLine1 = "Settings"
    topLevel.Push(o)

    screen.SetContentList(topLevel)
    screen.SetFocusedListItem(0)
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roPosterScreenEvent" then
            print "showHomeScreen | msg = "; msg.GetMessage() " | index = "; msg.GetIndex()
            if msg.isListFocused() then
                print "list focused | index = "; msg.GetIndex(); " | category = "; m.curCategory
            else if msg.isListItemSelected() then
                print "list item selected | index = "; msg.GetIndex()
                if msg.GetIndex() = 0
                    displayAudio()
                else if msg.GetIndex() = 1
                    displayAZVideo()
                else 
                    displaySettings()
                end if
            else if msg.isScreenClosed() then
                return -1
            end if
        end If
    end while
    return 0
End Function


Function displayCategoryPosterScreen(category As Object) As Dynamic
    if validateParam(category, "roAssociativeArray", "displayCategoryPosterScreen") = false return -1
    screen = preShowPosterScreen(category.Title, "")
    showPosterScreen(screen, category)
    return 0
End Function


Function displaySpecialCategoryScreen() As Dynamic
    ' do nothing, this is intended to just show how
    ' you might add a special category ionto the feed

    return 0
End Function


'************************************************************
'** initialize the category tree.  We fetch a category list
'** from the server, parse it into a hierarchy of nodes and
'** then use this to build the home screen and pass to child
'** screen in the heirarchy. Each node terminates at a list
'** of content for the sub-category describing individual videos
'************************************************************
Function initCategoryList(t as String) As Void
    print t
    conn = InitCategoryFeedConnection(t)
    m.Categories = conn.LoadCategoryFeed(conn)
    m.CategoryNames = conn.GetCategoryNames(m.Categories)
End Function


Function preShowPosterScreen(breadA=invalid, breadB=invalid) As Object
    if validateParam(breadA, "roString", "preShowPosterScreen", true) = false return -1
    if validateParam(breadB, "roString", "preShowPosterScreen", true) = false return -1

    port=CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
    end if

    screen.SetListStyle("arced-landscape")
    return screen
End Function


Function showPosterScreen(screen As Object, category As Object) As Integer
    if validateParam(screen, "roPosterScreen", "showPosterScreen") = false return -1
    if validateParam(category, "roAssociativeArray", "showPosterScreen") = false return -1

    m.curCategory = 0
    m.curShow     = 0

    screen.SetListNames(getCategoryList(category))
    screen.SetContentList(getShowsForCategoryItem(category, m.curCategory))
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roPosterScreenEvent" then
            print "showPosterScreen | msg = "; msg.GetMessage() " | index = "; msg.GetIndex()
            if msg.isListFocused() then
                m.curCategory = msg.GetIndex()
                m.curShow = 0
                screen.SetFocusedListItem(m.curShow)
                screen.SetContentList(getShowsForCategoryItem(category, m.curCategory))
                print "list focused | current category = "; m.curCategory
            else if msg.isListItemSelected() then
                m.curShow = msg.GetIndex()
                print "list item selected | current show = "; m.curShow
                m.curShow = displayShowDetailScreen(category, m.curShow)
                screen.SetFocusedListItem(m.curShow)
                print "list item updated  | new show = "; m.curShow
            else if msg.isScreenClosed() then
                return -1
            end if
        end If
    end while


End Function

Function displayShowDetailScreen(category as Object, showIndex as Integer) As Integer

    if validateParam(category, "roAssociativeArray", "displayShowDetailScreen") = false return -1

    shows = getShowsForCategoryItem(category, m.curCategory)
    screen = preShowDetailScreen(category.Title, category.kids[m.curCategory].Title)
    showIndex = showDetailScreen(screen, shows, showIndex)

    return showIndex
End Function


Function getCategoryList(topCategory As Object) As Object

    if validateParam(topCategory, "roAssociativeArray", "getCategoryList") = false return -1

    if type(topCategory) <> "roAssociativeArray" then
        print "incorrect type passed to getCategoryList"
        return -1
    endif

    categoryList = CreateObject("roArray", 100, true)
    for each subCategory in topCategory.Kids
        categoryList.Push(subcategory.Title)
    next
    return categoryList

End Function

Function getShowsForCategoryItem(category As Object, item As Integer) As Object

    if validateParam(category, "roAssociativeArray", "getCategoryList") = false return invalid 

    conn = InitShowFeedConnection(category.kids[item])
    showList = conn.LoadShowFeed(conn)
    return showList

End Function

Function showVideoScreen(episode As Object)

    if type(episode) <> "roAssociativeArray" then
        print "invalid data passed to showVideoScreen"
        return -1
    endif

    port = CreateObject("roMessagePort")
    screen = CreateObject("roVideoScreen")
    screen.SetMessagePort(port)

    screen.Show()
    screen.SetPositionNotificationPeriod(30)
    screen.SetContent(episode)
    screen.Show()

    'Uncomment his line to dump the contents of the episode to be played
    'PrintAA(episode)

    while true
        msg = wait(0, port)

        if type(msg) = "roVideoScreenEvent" then
            print "showHomeScreen | msg = "; msg.getMessage() " | index = "; msg.GetIndex()
            if msg.isScreenClosed()
                print "Screen closed"
                exit while
            elseif msg.isRequestFailed()
                print "Video request failure: "; msg.GetIndex(); " " msg.GetData() 
            elseif msg.isStatusMessage()
                print "Video status: "; msg.GetIndex(); " " msg.GetData() 
            elseif msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
            elseif msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
                RegWrite(episode.ContentId, nowpos.toStr())
            else
                print "Unexpected event type: "; msg.GetType()
            end if
        else
            print "Unexpected message class: "; type(msg)
        end if
    end while

End Function



Function displayAZVideo() As Object
    initCategoryList("video")
    port=CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    screen.SetListStyle("flat-category")
    screen.setAdDisplayMode("scale-to-fit")
    screen.setContentList(m.Categories.Kids)
    screen.show()

    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roPosterScreenEvent" then
            print "showVideoSelector | msg = "; msg.GetMessage() " | index = "; msg.GetIndex()
            if msg.isListFocused() then
                print "list focused | index = "; msg.GetIndex(); " | category = "; m.curCategory
            else if msg.isListItemSelected() then
                print "list item selected | index = "; msg.GetIndex()
                kid = m.Categories.Kids[msg.GetIndex()]
                displayCategoryPosterScreen(kid)
            else if msg.isScreenClosed() then
                return -1
            end if
        end If
    end while
End Function


Function displayAudio() As Object
    serverIP = RegRead("vegServerIP")
    if (serverIP = invalid)
        print "Invalid"
        serverIP = "192.168.128.5"
    endif
    str = CreateObject("roAssociativeArray")
    str.title = "Radio Meanness"
    str.description = "What's playing on Radio Teapot"
    str.streamformat = "mp3"
    str.contentquality = "SD"
    
    str.streamurls = CreateObject("roArray",1,false)
    str.streamqualities = CreateObject("roArray",1,false)
    str.streambitrates = CreateObject("roArray",1,false)
    str.streamurls.Push("http://" + serverIP + ":8000/stream")
    str.streamqualities.Push("SD")
    str.streambitrates.Push(0)
    print "Audio stream: " + str.streamurls[0]
    showAudioPlayer(str)
End Function


Function displaySettings() As Void 
    serverIP = RegRead("vegServerIP")
    if (serverIP = invalid) 
        print "Invalid"
        serverIP = "192.168.128.5"
    endif
    print serverIP

    screen = CreateObject("roKeyboardScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetTitle("Video Server Address")
    screen.SetText(serverIP)
    screen.SetDisplayText("Enter Host Name or IP Address")
    screen.SetMaxLength(25)
    screen.AddButton(1, "OK")
    screen.AddButton(2, "Cancel")
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())
        print "message received"
        if type(msg) = "roKeyboardScreenEvent"
            if msg.isScreenClosed()
                return
            else if msg.isButtonPressed() then
                print "Evt: ";msg.GetMessage();" idx:"; msg.GetIndex()
                if msg.GetIndex() = 1
                    searchText = screen.GetText()
                    print "search text: "; searchText
                    RegWrite("vegServerIP", searchText)
                    return
                else if msg.GetIndex() = 2
                    return
                endif
            endif
        endif
    end while
End Function



Function InitCategoryFeedConnection(t as String) As Object

    conn = CreateObject("roAssociativeArray")
    serverIP = RegRead("vegServerIP")

    if (serverIP = invalid) then
        serverIP = "192.168.128.5"
    endif

    conn.UrlPrefix   = "http://"+ serverIP + "/meeja/"
    conn.UrlCategoryFeed = conn.UrlPrefix + "?type=" + t

    conn.Timer = CreateObject("roTimespan")

    conn.LoadCategoryFeed    = load_category_feed
    conn.GetCategoryNames    = get_category_names

    print "created feed connection for " + conn.UrlCategoryFeed

    return conn
End Function

Function get_category_names(categories As Object) As Dynamic

    categoryNames = CreateObject("roArray", 100, true)

    for each category in categories.kids
        'print category.Title
        categoryNames.Push(category.Title)
    next

    return categoryNames

End Function


Function load_category_feed(conn As Object) As Dynamic

    http = NewHttp(conn.UrlCategoryFeed)

    Dbg("url: ", http.Http.GetUrl())

    m.Timer.Mark()
    rsp = http.GetToStringWithRetry()
    Dbg("Took: ", m.Timer)

    m.Timer.Mark()
    xml=CreateObject("roXMLElement")
    if not xml.Parse(rsp) then
         print "Can't parse feed"
        return invalid
    endif
    Dbg("Parse Took: ", m.Timer)

    m.Timer.Mark()
    if xml.category = invalid then
        print "no categories tag"
        return invalid
    endif

    if islist(xml.category) = false then
        print "invalid feed body"
        return invalid
    endif

    if xml.category[0].GetName() <> "category" then
        print "no initial category tag"
        return invalid
    endif

    topNode = MakeEmptyCatNode()
    topNode.Title = "root"
    topNode.isapphome = true

    print "begin category node parsing"

    categories = xml.GetChildElements()
    print "number of categories: " + itostr(categories.Count())
    for each e in categories 
        o = ParseCategoryNode(e)
        if o <> invalid then
            topNode.AddKid(o)
            print "added new child node"
        else
            print "parse returned no child node"
        endif
    next
    Dbg("Traversing: ", m.Timer)

    return topNode

End Function

Function MakeEmptyCatNode() As Object
    return init_category_item()
End Function


Function ParseCategoryNode(xml As Object) As dynamic
    o = init_category_item()

    print "ParseCategoryNode: " + xml.GetName()
    'PrintXML(xml, 5)

    'parse the curent node to determine the type. everything except
    'special categories are considered normal, others have unique types 
    if xml.GetName() = "category" then
        print "category: " + xml@title + " | " + xml@description
        o.Type = "normal"
        o.Title = xml@title
        o.Description = xml@Description
        o.ShortDescriptionLine1 = xml@Title
        o.ShortDescriptionLine2 = xml@Description
        o.SDPosterURL = xml@sd_img
print o.SDPosterURL
        o.HDPosterURL = xml@hd_img
    elseif xml.GetName() = "categoryLeaf" then
        o.Type = "normal"
    elseif xml.GetName() = "specialCategory" then
        if invalid <> xml.GetAttributes() then
            for each a in xml.GetAttributes()
                if a = "type" then
                    o.Type = xml.GetAttributes()[a]
                    print "specialCategory: " + xml@type + "|" + xml@title + " | " + xml@description
                    o.Title = xml@title
                    o.Description = xml@Description
                    o.ShortDescriptionLine1 = xml@Title
                    o.ShortDescriptionLine2 = xml@Description
                    o.SDPosterURL = xml@sd_img
                    o.HDPosterURL = xml@hd_img
                endif
            next
        endif
    else
        print "ParseCategoryNode skip: " + xml.GetName()
        return invalid
    endif

    'only continue processing if we are dealing with a known type
    'if new types are supported, make sure to add them to the list
    'and parse them correctly further downstream in the parser 
    while true
        if o.Type = "normal" exit while
        if o.Type = "special_category" exit while
        print "ParseCategoryNode unrecognized feed type"
        return invalid
    end while 

    'get the list of child nodes and recursed
    'through everything under the current node
    for each e in xml.GetBody()
        name = e.GetName()
        if name = "category" then
            print "category: " + e@title + " [" + e@description + "]"
            kid = ParseCategoryNode(e)
            kid.Title = e@title
            kid.Description = e@Description
            kid.ShortDescriptionLine1 = xml@Description
            kid.SDPosterURL = xml@sd_img
            kid.HDPosterURL = xml@hd_img
            o.AddKid(kid)
        elseif name = "categoryLeaf" then
            print "categoryLeaf: " + e@title + " [" + e@description + "]"
            kid = ParseCategoryNode(e)
            kid.Title = e@title
            kid.Description = e@Description
            kid.Feed = e@feed
            o.AddKid(kid)
        elseif name = "specialCategory" then
            print "specialCategory: " + e@title + " [" + e@description + "]"
            kid = ParseCategoryNode(e)
            kid.Title = e@title
            kid.Description = e@Description
            kid.sd_img = e@sd_img
            kid.hd_img = e@hd_img
            kid.Feed = e@feed
            o.AddKid(kid)
        endif
    next

    return o
End Function


Function init_category_item() As Object
    o = CreateObject("roAssociativeArray")
    o.Title       = ""
    o.Type        = "normal"
    o.Description = ""
    o.Kids        = CreateObject("roArray", 100, true)
    o.Parent      = invalid
    o.Feed        = ""
    o.IsLeaf      = cn_is_leaf
    o.AddKid      = cn_add_kid
    return o
End Function


'********************************************************
'** Helper function for each node, returns true/false
'** indicating that this node is a leaf node in the tree
'********************************************************
Function cn_is_leaf() As Boolean
    if m.Kids.Count() > 0 return true
    if m.Feed <> "" return false
    return true
End Function


'*********************************************************
'** Helper function for each node in the tree to add a 
'** new node as a child to this node.
'*********************************************************
Sub cn_add_kid(kid As Object)
    if kid = invalid then
        print "skipping: attempt to add invalid kid failed"
        return
     endif
    
    kid.Parent = m
    m.Kids.Push(kid)
End Sub

'******************************************************
'Get our device version
'******************************************************

Function GetDeviceVersion()
    return CreateObject("roDeviceInfo").GetVersion()
End Function

'******************************************************
'Get our serial number
'******************************************************

Function GetDeviceESN()
    return CreateObject("roDeviceInfo").GetDeviceUniqueId()
End Function

'******************************************************
'Show basic message dialog without buttons
'Dialog remains up until caller releases the returned object
'******************************************************

Function ShowPleaseWait(title As dynamic, text As dynamic) As Object
    if not isstr(title) title = ""
    if not isstr(text) text = ""

    port = CreateObject("roMessagePort")
    dialog = invalid

    'the OneLineDialog renders a single line of text better
    'than the MessageDialog.
    if text = ""
        dialog = CreateObject("roOneLineDialog")
    else
        dialog = CreateObject("roMessageDialog")
        dialog.SetText(text)
    endif

    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.ShowBusyAnimation()
    dialog.Show()
    return dialog
End Function

'******************************************************
'Retrieve text for connection failed
'******************************************************

Function GetConnectionFailedText() as String
    return "We were unable to connect to the service.  Please try again in a few minutes."
End Function

'******************************************************
'Show connection error dialog
'
'Parameter: retry t/f - offer retry option
'Return 0 = retry, 1 = back
'******************************************************

Function ShowConnectionFailedRetry() as dynamic
    Dbg("Connection Failed Retry")
    title = "Can't connect to video service"
    text  = GetConnectionFailedText()
    return ShowDialog2Buttons(title, text, "try again", "back")
End Function

'******************************************************
'Show Amzon connection error dialog with only an OK button
'******************************************************

Sub ShowConnectionFailed()
    Dbg("Connection Failed")
    title = "Can't connect to video service"
    text  = GetConnectionFailedText()
    ShowErrorDialog(text, title)
End Sub

'******************************************************
'Show error dialog with OK button
'******************************************************

Sub ShowErrorDialog(text As dynamic, title=invalid as dynamic)
    if not isstr(text) text = "Unspecified error"
    if not isstr(title) title = ""
    ShowDialog1Button(title, text, "Done")
End Sub

'******************************************************
'Show 1 button dialog
'Return: nothing
'******************************************************

Sub ShowDialog1Button(title As dynamic, text As dynamic, but1 As String)
    if not isstr(title) title = ""
    if not isstr(text) text = ""

    Dbg("DIALOG1: ", title + " - " + text)

    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.SetText(text)
    dialog.AddButton(0, but1)
    dialog.Show()

    while true
        dlgMsg = wait(0, dialog.GetMessagePort())

        if type(dlgMsg) = "roMessageDialogEvent"
            if dlgMsg.isScreenClosed()
                print "Screen closed"
                return
            else if dlgMsg.isButtonPressed()
                print "Button pressed: "; dlgMsg.GetIndex(); " " dlgMsg.GetData()
                return
            endif
        endif
    end while
End Sub

'******************************************************
'Show 2 button dialog
'Return: 0=first button or screen closed, 1=second button
'******************************************************

Function ShowDialog2Buttons(title As dynamic, text As dynamic, but1 As String, but2 As String) As Integer
    if not isstr(title) title = ""
    if not isstr(text) text = ""

    Dbg("DIALOG2: ", title + " - " + text)

    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.SetText(text)
    dialog.AddButton(0, but1)
    dialog.AddButton(1, but2)
    dialog.Show()

    while true
        dlgMsg = wait(0, dialog.GetMessagePort())

        if type(dlgMsg) = "roMessageDialogEvent"
            if dlgMsg.isScreenClosed()
                print "Screen closed"
                dialog = invalid
                return 0
            else if dlgMsg.isButtonPressed()
                print "Button pressed: "; dlgMsg.GetIndex(); " " dlgMsg.GetData()
                dialog = invalid
                return dlgMsg.GetIndex()
            endif
        endif
    end while
End Function

'******************************************************
'Registry Helper Functions
'******************************************************
Function RegRead(key, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) then return sec.Read(key)
    return invalid
End Function

Function RegWrite(key, val, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val)
    sec.Flush() 'commit it
End Function

Function RegDelete(key, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
    sec.Flush()
End Function


'******************************************************
'Insertion Sort
'Will sort an array directly, or use a key function
'******************************************************
Sub Sort(A as Object, key=invalid as dynamic)

    if type(A)<>"roArray" then return

    if (key=invalid) then
        for i = 1 to A.Count()-1
            value = A[i]
            j = i-1
            while j>= 0 and A[j] > value
                A[j + 1] = A[j]
                j = j-1
            end while
            A[j+1] = value
        next

    else
        if type(key)<>"Function" then return
        for i = 1 to A.Count()-1
            valuekey = key(A[i])
            value = A[i]
            j = i-1
            while j>= 0 and key(A[j]) > valuekey
                A[j + 1] = A[j]
                j = j-1
            end while
            A[j+1] = value
        next

    end if

End Sub


'******************************************************
'Convert anything to a string
'
'Always returns a string
'******************************************************
Function tostr(any)
    ret = AnyToString(any)
    if ret = invalid ret = type(any)
    if ret = invalid ret = "unknown" 'failsafe
    return ret
End Function


'******************************************************
'Get a " char as a string
'******************************************************
Function Quote()
    q$ = Chr(34)
    return q$
End Function


'******************************************************
'isxmlelement
'
'Determine if the given object supports the ifXMLElement interface
'******************************************************
Function isxmlelement(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifXMLElement") = invalid return false
    return true
End Function


'******************************************************
'islist
'
'Determine if the given object supports the ifList interface
'******************************************************
Function islist(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifArray") = invalid return false
    return true
End Function


'******************************************************
'isint
'
'Determine if the given object supports the ifInt interface
'******************************************************
Function isint(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifInt") = invalid return false
    return true
End Function

'******************************************************
' validstr
'
' always return a valid string. if the argument is
' invalid or not a string, return an empty string
'******************************************************
Function validstr(obj As Dynamic) As String
    if isnonemptystr(obj) return obj
    return ""
End Function


'******************************************************
'isstr
'
'Determine if the given object supports the ifString interface
'******************************************************
Function isstr(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifString") = invalid return false
    return true
End Function


'******************************************************
'isnonemptystr
'
'Determine if the given object supports the ifString interface
'and returns a string of non zero length
'******************************************************
Function isnonemptystr(obj)
    if isnullorempty(obj) return false
    return true
End Function


'******************************************************
'isnullorempty
'
'Determine if the given object is invalid or supports
'the ifString interface and returns a string of non zero length
'******************************************************
Function isnullorempty(obj)
    if obj = invalid return true
    if not isstr(obj) return true
    if Len(obj) = 0 return true
    return false
End Function


'******************************************************
'isbool
'
'Determine if the given object supports the ifBoolean interface
'******************************************************
Function isbool(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifBoolean") = invalid return false
    return true
End Function


'******************************************************
'isfloat
'
'Determine if the given object supports the ifFloat interface
'******************************************************
Function isfloat(obj as dynamic) As Boolean
    if obj = invalid return false
    if GetInterface(obj, "ifFloat") = invalid return false
    return true
End Function


'******************************************************
'strtobool
'
'Convert string to boolean safely. Don't crash
'Looks for certain string values
'******************************************************
Function strtobool(obj As dynamic) As Boolean
    if obj = invalid return false
    if type(obj) <> "roString" return false
    o = strTrim(obj)
    o = Lcase(o)
    if o = "true" return true
    if o = "t" return true
    if o = "y" return true
    if o = "1" return true
    return false
End Function


'******************************************************
'itostr
'
'Convert int to string. This is necessary because
'the builtin Stri(x) prepends whitespace
'******************************************************
Function itostr(i As Integer) As String
    str = Stri(i)
    return strTrim(str)
End Function


'******************************************************
'Get remaining hours from a total seconds
'******************************************************
Function hoursLeft(seconds As Integer) As Integer
    hours% = seconds / 3600
    return hours%
End Function


'******************************************************
'Get remaining minutes from a total seconds
'******************************************************
Function minutesLeft(seconds As Integer) As Integer
    hours% = seconds / 3600
    mins% = seconds - (hours% * 3600)
    mins% = mins% / 60
    return mins%
End Function


'******************************************************
'Pluralize simple strings like "1 minute" or "2 minutes"
'******************************************************
Function Pluralize(val As Integer, str As String) As String
    ret = itostr(val) + " " + str
    if val <> 1 ret = ret + "s"
    return ret
End Function


'******************************************************
'Trim a string
'******************************************************
Function strTrim(str As String) As String
    st=CreateObject("roString")
    st.SetString(str)
    return st.Trim()
End Function


'******************************************************
'Tokenize a string. Return roList of strings
'******************************************************
Function strTokenize(str As String, delim As String) As Object
    st=CreateObject("roString")
    st.SetString(str)
    return st.Tokenize(delim)
End Function


'******************************************************
'Replace substrings in a string. Return new string
'******************************************************
Function strReplace(basestr As String, oldsub As String, newsub As String) As String
    newstr = ""

    i = 1
    while i <= Len(basestr)
        x = Instr(i, basestr, oldsub)
        if x = 0 then
            newstr = newstr + Mid(basestr, i)
            exit while
        endif

        if x > i then
            newstr = newstr + Mid(basestr, i, x-i)
            i = x
        endif

        newstr = newstr + newsub
        i = i + Len(oldsub)
    end while

    return newstr
End Function


'******************************************************
'Get all XML subelements by name
'
'return list of 0 or more elements
'******************************************************
Function GetXMLElementsByName(xml As Object, name As String) As Object
    list = CreateObject("roArray", 100, true)
    if islist(xml.GetBody()) = false return list

    for each e in xml.GetBody()
        if e.GetName() = name then
            list.Push(e)
        endif
    next

    return list
End Function


'******************************************************
'Get all XML subelement's string bodies by name
'
'return list of 0 or more strings
'******************************************************
Function GetXMLElementBodiesByName(xml As Object, name As String) As Object
    list = CreateObject("roArray", 100, true)
    if islist(xml.GetBody()) = false return list

    for each e in xml.GetBody()
        if e.GetName() = name then
            b = e.GetBody()
            if type(b) = "roString" list.Push(b)
        endif
    next

    return list
End Function


'******************************************************
'Get first XML subelement by name
'
'return invalid if not found, else the element
'******************************************************
Function GetFirstXMLElementByName(xml As Object, name As String) As dynamic
    if islist(xml.GetBody()) = false return invalid

    for each e in xml.GetBody()
        if e.GetName() = name return e
    next

    return invalid
End Function


'******************************************************
'Get first XML subelement's string body by name
'
'return invalid if not found, else the subelement's body string
'******************************************************
Function GetFirstXMLElementBodyStringByName(xml As Object, name As String) As dynamic
    e = GetFirstXMLElementByName(xml, name)
    if e = invalid return invalid
    if type(e.GetBody()) <> "roString" return invalid
    return e.GetBody()
End Function


'******************************************************
'Get the xml element as an integer
'
'return invalid if body not a string, else the integer as converted by strtoi
'******************************************************
Function GetXMLBodyAsInteger(xml As Object) As dynamic
    if type(xml.GetBody()) <> "roString" return invalid
    return strtoi(xml.GetBody())
End Function


'******************************************************
'Parse a string into a roXMLElement
'
'return invalid on error, else the xml object
'******************************************************
Function ParseXML(str As String) As dynamic
    if str = invalid return invalid
    xml=CreateObject("roXMLElement")
    if not xml.Parse(str) return invalid
    return xml
End Function


'******************************************************
'Get XML sub elements whose bodies are strings into an associative array.
'subelements that are themselves parents are skipped
'namespace :'s are replaced with _'s
'
'So an XML element like...
'
'<blah>
'    <This>abcdefg</This>
'    <Sucks>xyz</Sucks>
'    <sub>
'        <sub2>
'        ....
'        </sub2>
'    </sub>
'    <ns:doh>homer</ns:doh>
'</blah>
'
'returns an AA with:
'
'aa.This = "abcdefg"
'aa.Sucks = "xyz"
'aa.ns_doh = "homer"
'
'return an empty AA if nothing found
'******************************************************
Sub GetXMLintoAA(xml As Object, aa As Object)
    for each e in xml.GetBody()
        body = e.GetBody()
        if type(body) = "roString" then
            name = e.GetName()
            name = strReplace(name, ":", "_")
            aa.AddReplace(name, body)
        endif
    next
End Sub


'******************************************************
'Walk an AA and print it
'******************************************************
Sub PrintAA(aa as Object)
    print "---- AA ----"
    if aa = invalid
        print "invalid"
        return
    else
        cnt = 0
        for each e in aa
            x = aa[e]
            PrintAny(0, e + ": ", aa[e])
            cnt = cnt + 1
        next
        if cnt = 0
            PrintAny(0, "Nothing from for each. Looks like :", aa)
        endif
    endif
    print "------------"
End Sub


'******************************************************
'Walk a list and print it
'******************************************************
Sub PrintList(list as Object)
    print "---- list ----"
    PrintAnyList(0, list)
    print "--------------"
End Sub


'******************************************************
'Print an associativearray
'******************************************************
Sub PrintAnyAA(depth As Integer, aa as Object)
    for each e in aa
        x = aa[e]
        PrintAny(depth, e + ": ", aa[e])
    next
End Sub


'******************************************************
'Print a list with indent depth
'******************************************************
Sub PrintAnyList(depth As Integer, list as Object)
    i = 0
    for each e in list
        PrintAny(depth, "List(" + itostr(i) + ")= ", e)
        i = i + 1
    next
End Sub


'******************************************************
'Print anything
'******************************************************
Sub PrintAny(depth As Integer, prefix As String, any As Dynamic)
    if depth >= 10
        print "**** TOO DEEP " + itostr(5)
        return
    endif
    prefix = string(depth*2," ") + prefix
    depth = depth + 1
    str = AnyToString(any)
    if str <> invalid
        print prefix + str
        return
    endif
    if type(any) = "roAssociativeArray"
        print prefix + "(assocarr)..."
        PrintAnyAA(depth, any)
        return
    endif
    if islist(any) = true
        print prefix + "(list of " + itostr(any.Count()) + ")..."
        PrintAnyList(depth, any)
        return
    endif

    print prefix + "?" + type(any) + "?"
End Sub


'******************************************************
'Print an object as a string for debugging. If it is
'very long print the first 500 chars.
'******************************************************
Sub Dbg(pre As Dynamic, o=invalid As Dynamic)
    p = AnyToString(pre)
    if p = invalid p = ""
    if o = invalid o = ""
    s = AnyToString(o)
    if s = invalid s = "???: " + type(o)
    if Len(s) > 4000
        s = Left(s, 4000)
    endif
    print p + s
End Sub


'******************************************************
'Try to convert anything to a string. Only works on simple items.
'
'Test with this script...
'
'    s$ = "yo1"
'    ss = "yo2"
'    i% = 111
'    ii = 222
'    f! = 333.333
'    ff = 444.444
'    d# = 555.555
'    dd = 555.555
'    bb = true
'
'    so = CreateObject("roString")
'    so.SetString("strobj")
'    io = CreateObject("roInt")
'    io.SetInt(666)
'    tm = CreateObject("roTimespan")
'
'    Dbg("", s$ ) 'call the Dbg() function which calls AnyToString()
'    Dbg("", ss )
'    Dbg("", "yo3")
'    Dbg("", i% )
'    Dbg("", ii )
'    Dbg("", 2222 )
'    Dbg("", f! )
'    Dbg("", ff )
'    Dbg("", 3333.3333 )
'    Dbg("", d# )
'    Dbg("", dd )
'    Dbg("", so )
'    Dbg("", io )
'    Dbg("", bb )
'    Dbg("", true )
'    Dbg("", tm )
'
'try to convert an object to a string. return invalid if can't
'******************************************************
Function AnyToString(any As Dynamic) As dynamic
    if any = invalid return "invalid"
    if isstr(any) return any
    if isint(any) return itostr(any)
    if isbool(any)
        if any = true return "true"
        return "false"
    endif
    if isfloat(any) return Str(any)
    if type(any) = "roTimespan" return itostr(any.TotalMilliseconds()) + "ms"
    return invalid
End Function


'******************************************************
'Walk an XML tree and print it
'******************************************************
Sub PrintXML(element As Object, depth As Integer)
    print tab(depth*3);"Name: [" + element.GetName() + "]"
    if invalid <> element.GetAttributes() then
        print tab(depth*3);"Attributes: ";
        for each a in element.GetAttributes()
            print a;"=";left(element.GetAttributes()[a], 4000);
            if element.GetAttributes().IsNext() then print ", ";
        next
        print
    endif

    if element.GetBody()=invalid then
        ' print tab(depth*3);"No Body"
    else if type(element.GetBody())="roString" then
        print tab(depth*3);"Contains string: [" + left(element.GetBody(), 4000) + "]"
    else
        print tab(depth*3);"Contains list:"
        for each e in element.GetBody()
            PrintXML(e, depth+1)
        next
    endif
    print
end sub


'******************************************************
'Dump the bytes of a string
'******************************************************
Sub DumpString(str As String)
    print "DUMP STRING"
    print "---------------------------"
    print str
    print "---------------------------"
    l = Len(str)-1
    i = 0
    for i = 0 to l
        c = Mid(str, i)
        val = Asc(c)
        print itostr(val)
    next
    print "---------------------------"
End Sub


'******************************************************
'Validate parameter is the correct type
'******************************************************
Function validateParam(param As Object, paramType As String,functionName As String, allowInvalid = false) As Boolean
    if type(param) = paramType then
        return true
    endif

    if allowInvalid = true then
        if type(param) = invalid then
            return true
        endif
    endif

    print "invalid parameter of type "; type(param); " for "; paramType; " in function "; functionName
    return false
End Function

'******************************************************
'** Set up the show feed connection object
'** This feed provides the detailed list of shows for
'** each subcategory (categoryLeaf) in the category
'** category feed. Given a category leaf node for the
'** desired show list, we'll hit the url and get the
'** results.     
'******************************************************

Function InitShowFeedConnection(category As Object) As Object

    if validateParam(category, "roAssociativeArray", "initShowFeedConnection") = false return invalid 

    conn = CreateObject("roAssociativeArray")
    conn.UrlShowFeed  = category.feed 

    conn.Timer = CreateObject("roTimespan")

    conn.LoadShowFeed    = load_show_feed
    conn.ParseShowFeed   = parse_show_feed
    conn.InitFeedItem    = init_show_feed_item

    print "created feed connection for " + conn.UrlShowFeed
    return conn

End Function


'******************************************************
'Initialize a new feed object
'******************************************************
Function newShowFeed() As Object

    o = CreateObject("roArray", 100, true)
    return o

End Function


'***********************************************************
' Initialize a ShowFeedItem. This sets the default values
' for everything.  The data in the actual feed is sometimes
' sparse, so these will be the default values unless they
' are overridden while parsing the actual game data
'***********************************************************
Function init_show_feed_item() As Object
    o = CreateObject("roAssociativeArray")

    o.ContentId        = ""
    o.Title            = ""
    o.ContentType      = ""
    o.ContentQuality   = ""
    o.Synopsis         = ""
    o.Genre            = ""
    o.Runtime          = ""
    o.StreamQualities  = CreateObject("roArray", 5, true) 
    o.StreamBitrates   = CreateObject("roArray", 5, true)
    o.StreamUrls       = CreateObject("roArray", 5, true)

    return o
End Function


'*************************************************************
'** Grab and load a show detail feed. The url we are fetching 
'** is specified as part of the category provided during 
'** initialization. This feed provides a list of all shows
'** with details for the given category feed.
'*********************************************************
Function load_show_feed(conn As Object) As Dynamic

    if validateParam(conn, "roAssociativeArray", "load_show_feed") = false return invalid 

    print "url: " + conn.UrlShowFeed 
    http = NewHttp(conn.UrlShowFeed)

    m.Timer.Mark()
    rsp = http.GetToStringWithRetry()
    print "Request Time: " + itostr(m.Timer.TotalMilliseconds())

    feed = newShowFeed()
    xml=CreateObject("roXMLElement")
    if not xml.Parse(rsp) then
        print "Can't parse feed"
        return feed
    endif

    if xml.GetName() <> "feed" then
        print "no feed tag found"
        return feed
    endif

    if islist(xml.GetBody()) = false then
        print "no feed body found"
        return feed
    endif

    m.Timer.Mark()
    m.ParseShowFeed(xml, feed)
    print "Show Feed Parse Took : " + itostr(m.Timer.TotalMilliseconds())

    return feed

End Function


'**************************************************************************
'**************************************************************************
Function parse_show_feed(xml As Object, feed As Object) As Void

    showCount = 0
    showList = xml.GetChildElements()

    for each curShow in showList

        'for now, don't process meta info about the feed size
        if curShow.GetName() = "resultLength" or curShow.GetName() = "endIndex" then
            goto skipitem
        endif

        item = init_show_feed_item()

        'fetch all values from the xml for the current show
        item.hdImg            = validstr(curShow@hdImg) 
        item.sdImg            = validstr(curShow@sdImg) 
        item.ContentId        = validstr(curShow.contentId.GetText()) 
        item.Title            = validstr(curShow.title.GetText()) 
        item.Description      = validstr(curShow.description.GetText()) 
        item.ContentType      = validstr(curShow.contentType.GetText())
        item.ContentQuality   = validstr(curShow.contentQuality.GetText())
        item.Synopsis         = validstr(curShow.synopsis.GetText())
        item.Genre            = validstr(curShow.genres.GetText())
        item.Runtime          = validstr(curShow.runtime.GetText())
        item.HDBifUrl         = validstr(curShow.hdBifUrl.GetText())
        item.SDBifUrl         = validstr(curShow.sdBifUrl.GetText())
        item.StreamFormat = validstr(curShow.streamFormat.GetText())
        if item.StreamFormat = "" then  'set default streamFormat to mp4 if doesn't exist in xml
            item.StreamFormat = "mp4"
        endif
        
        'map xml attributes into screen specific variables
        item.ShortDescriptionLine1 = item.Title 
        item.ShortDescriptionLine2 = item.Description
        item.HDPosterUrl           = item.hdImg
        item.SDPosterUrl           = item.sdImg

        item.Length = strtoi(item.Runtime)
        item.Categories = CreateObject("roArray", 5, true)
        item.Categories.Push(item.Genre)
        item.Actors = CreateObject("roArray", 5, true)
        item.Actors.Push(item.Genre)
        item.Description = item.Synopsis
        
        'Set Default screen values for items not in feed
        item.HDBranded = false
        item.IsHD = false
        item.StarRating = "90"
        item.ContentType = "episode" 

        'media may be at multiple bitrates, so parse an build arrays
        for idx = 0 to 4
            e = curShow.media[idx]
            if e  <> invalid then
                item.StreamBitrates.Push(strtoi(validstr(e.streamBitrate.GetText())))
                item.StreamQualities.Push(validstr(e.streamQuality.GetText()))
                item.StreamUrls.Push(validstr(e.streamUrl.GetText()))
            endif
        next idx
        
        showCount = showCount + 1
        feed.Push(item)

        skipitem:

    next

End Function

Function CreateURLTransferObject(url As String) as Object
    obj = CreateObject("roUrlTransfer")
    obj.SetPort(CreateObject("roMessagePort"))
    obj.SetUrl(url)
    obj.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    obj.EnableEncodings(true)
    return obj
End Function

Function NewHttp(url As String) as Object
    obj = CreateObject("roAssociativeArray")
    obj.Http                        = CreateURLTransferObject(url)
    obj.FirstParam                  = true
    obj.AddParam                    = http_add_param
    obj.AddRawQuery                 = http_add_raw_query
    obj.GetToStringWithRetry        = http_get_to_string_with_retry
    obj.PrepareUrlForQuery          = http_prepare_url_for_query
    obj.GetToStringWithTimeout      = http_get_to_string_with_timeout
    obj.PostFromStringWithTimeout   = http_post_from_string_with_timeout

    if Instr(1, url, "?") > 0 then obj.FirstParam = false

    return obj
End Function


REM ******************************************************
REM Constucts a URL Transfer object 2
REM ******************************************************

Function CreateURLTransferObject2(url As String, contentHeader As String) as Object
    obj = CreateObject("roUrlTransfer")
    obj.SetPort(CreateObject("roMessagePort"))
    obj.SetUrl(url)
	obj.AddHeader("Content-Type", contentHeader)
    obj.EnableEncodings(true)
    return obj
End Function

REM ******************************************************
REM Url Query builder 2
REM so this is a quick and dirty name/value encoder/accumulator
REM ******************************************************

Function NewHttp2(url As String, contentHeader As String) as Object
    obj = CreateObject("roAssociativeArray")
    obj.Http                        = CreateURLTransferObject2(url, contentHeader)
    obj.FirstParam                  = true
    obj.AddParam                    = http_add_param
    obj.AddRawQuery                 = http_add_raw_query
    obj.GetToStringWithRetry        = http_get_to_string_with_retry
    obj.PrepareUrlForQuery          = http_prepare_url_for_query
    obj.GetToStringWithTimeout      = http_get_to_string_with_timeout
    obj.PostFromStringWithTimeout   = http_post_from_string_with_timeout

    if Instr(1, url, "?") > 0 then obj.FirstParam = false

    return obj
End Function


REM ******************************************************
REM HttpEncode - just encode a string
REM ******************************************************

Function HttpEncode(str As String) As String
    o = CreateObject("roUrlTransfer")
    return o.Escape(str)
End Function

REM ******************************************************
REM Prepare the current url for adding query parameters
REM Automatically add a '?' or '&' as necessary
REM ******************************************************

Function http_prepare_url_for_query() As String
    url = m.Http.GetUrl()
    if m.FirstParam then
        url = url + "?"
        m.FirstParam = false

    else
        url = url + "&"
    endif
    m.Http.SetUrl(url)
    return url
End Function

REM ******************************************************
REM Percent encode a name/value parameter pair and add the
REM the query portion of the current url
REM Automatically add a '?' or '&' as necessary
REM Prevent duplicate parameters
REM ******************************************************

Function http_add_param(name As String, val As String) as Void
    q = m.Http.Escape(name)
    q = q + "="
    url = m.Http.GetUrl()
    if Instr(1, url, q) > 0 return    'Parameter already present
    q = q + m.Http.Escape(val)
    m.AddRawQuery(q)
End Function

REM ******************************************************
REM Tack a raw query string onto the end of the current url
REM Automatically add a '?' or '&' as necessary
REM ******************************************************

Function http_add_raw_query(query As String) as Void
    url = m.PrepareUrlForQuery()
    url = url + query
    m.Http.SetUrl(url)
End Function

REM ******************************************************
REM Performs Http.AsyncGetToString() in a retry loop
REM with exponential backoff. To the outside
REM world this appears as a synchronous API.
REM ******************************************************

Function http_get_to_string_with_retry() as String
    timeout%         = 1500
    num_retries%     = 5

    str = ""
    while num_retries% > 0
'        print "httpget try " + itostr(num_retries%)
        if (m.Http.AsyncGetToString())
            event = wait(timeout%, m.Http.GetPort())
            if type(event) = "roUrlEvent"
                str = event.GetString()
                exit while        
            elseif event = invalid
                m.Http.AsyncCancel()
                REM reset the connection on timeouts
                m.Http = CreateURLTransferObject(m.Http.GetUrl())
                timeout% = 2 * timeout%
            else
                print "roUrlTransfer::AsyncGetToString(): unknown event"
            endif
        endif

        num_retries% = num_retries% - 1
    end while
    
    return str
End Function

REM ******************************************************
REM Performs Http.AsyncGetToString() with a single timeout in seconds
REM To the outside world this appears as a synchronous API.
REM ******************************************************

Function http_get_to_string_with_timeout(seconds as Integer) as String
    timeout% = 1000 * seconds

    str = ""
    m.Http.EnableFreshConnection(true) 'Don't reuse existing connections
    if (m.Http.AsyncGetToString())
        event = wait(timeout%, m.Http.GetPort())
        if type(event) = "roUrlEvent"
            str = event.GetString()
        elseif event = invalid
            Dbg("AsyncGetToString timeout")
            m.Http.AsyncCancel()
        else
            Dbg("AsyncGetToString unknown event", event)
        endif
    endif

    return str
End Function

REM ******************************************************
REM Performs Http.AsyncPostFromString() with a single timeout in seconds
REM To the outside world this appears as a synchronous API.
REM ******************************************************

Function http_post_from_string_with_timeout(val As String, seconds as Integer) as String
    timeout% = 1000 * seconds

    str = ""
'    m.Http.EnableFreshConnection(true) 'Don't reuse existing connections
    if (m.Http.AsyncPostFromString(val))
        event = wait(timeout%, m.Http.GetPort())
        if type(event) = "roUrlEvent"
			print "1"
			str = event.GetString()
        elseif event = invalid
			print "2"
            Dbg("AsyncPostFromString timeout")
            m.Http.AsyncCancel()
        else
			print "3"
            Dbg("AsyncPostFromString unknown event", event)
        endif
    endif

    return str
End Function
