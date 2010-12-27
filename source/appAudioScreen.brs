Function showAudioPlayer(episode As Object)

    if type(episode) <> "roAssociativeArray" then
        print "invalid data passed to showVideoScreen"
        return -1
    endif

    port = CreateObject("roMessagePort")
    player = CreateObject("roAudioPlayer")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    player.SetMessagePort(port)

    'screen.SetPositionNotificationPeriod(30)
    player.addcontent(episode)
    player.play()
    screen.Show()

    'Uncomment his line to dump the contents of the episode to be played
    PrintAA(episode)

    while true
        msg = wait(0, port)

        if type(msg) = "roPosterScreenEvent" then
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
                screen.stop()
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

