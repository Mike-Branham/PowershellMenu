# PowershellMenu
Console menu system for Powershell

#Features:
  - Cursor Up / Down to select
  - Optionally add a character to the menu item for selection
  - Optionally add help text that displays in a defined help area on the screen
  - Separate color settings for title, headers, menu items, and selected menu items
  - Tests console width and height to make sure menu and optional help will fit
  
Setting up a menu.  Here is a sample menu.
```
$Menu = [Menu]::new("================= Select option ==================")
$Menu.AddMenuItem("", "", "", "")
$Menu.AddMenuItem(".Information", "", "", "")
$Menu.AddMenuItem("Information item 1.", "i1", "0", "This is the first item that is selectable in the menu.  This help text should wrap on to a couple of lines.")
$Menu.AddMenuItem("Information Item 2.", "i2", "1", "Help for Item 2.")
$Menu.AddMenuItem("Information Item 3.", "i3", "2", "Help for Item 3.")
$Menu.AddMenuItem("", "", "", "")
$Menu.AddMenuItem(".Setup", "", "", "")
$Menu.AddMenuItem("Setup somthing.", "s1", "3", "")
$Menu.AddMenuItem("Setup something else.", "s2", "4", "")
$Menu.AddMenuItem("", "", "", "")
$Menu.AddMenuItem(".Backup and restore", "", "", "")
$Menu.AddMenuItem("Backup some configuration.", "b1", "5", "")
$Menu.AddMenuItem("Backup something else.", "b2", "6", "")
$Menu.AddMenuItem("", "", "", "")
$Menu.AddMenuItem(".Other", "", "", "")
$Menu.AddMenuItem("Do some other thing.", "o1", "7", "")
$Menu.AddMenuItem("Do this and that.", "o2", "8", "")
$Menu.AddMenuItem("Test something.", "o3", "9", "")
$Menu.AddMenuItem("", "", "", "")
$Menu.AddMenuItem("Quit.", "q", "q", "")
```
The new constructor for the menu takes a string as a menu title.

Each AddMenuItem has the following format:
```
  String $Prompt - Menu item prompt that is displayed on the screen.  
                  If blank, leaves a blank non-selectable line.
                  If the prompt starts with a period, it is considered a header and non-selectable.
  String $Value - The value that is returned if that item is selected.
  String $Key   - The optional character used to select the item without moving the "cursor" and selecting with enter.
  String $Help  - Optional text that will display in the defined help area if an item is highlighted by cursor (up/down) keys.
  ```
