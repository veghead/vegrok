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


Function displayAZAudio() As Object
    initCategoryList("audio")
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
