w = Ext.IMGUI.NewWindow("Scribe")
tabbar = w:AddTabBar("")

mouseoverTab = tabbar:AddTabItem("Main")
mouseoverTab:AddText("Num_1 = dump | Num_2 = dump file")
mouseoeerTab:AddSeparator()
mouseoverTab:AddText("Dump:")
dumpMouseover = mouseoeverTab:AddText("")