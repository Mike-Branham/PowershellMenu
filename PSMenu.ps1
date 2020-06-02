# Constants for the help text area
# If helpenabled is set to $False, then the help area is never cleared or rendered
New-Variable -Name 'HElPSTARTROW' -Value 1 -Option Constant
New-Variable -Name 'HELPSTARTCOL' -Value 60 -Option Constant
New-Variable -Name 'HELPWIDTH' -Value 40 -Option Constant
New-Variable -Name 'HELPMAXROWS' -Value 20 -Option Constant
New-Variable -Name 'HELPENABLED' -Value $True -Option Constant
New-Variable -Name 'HELPCOLOR' -Value white -Option Constant

# Constants for the menu display
# AllowKeys - if set, it will use the character in the prompt, and allow selection with a key press.
New-Variable -Name 'ALLOWKEYS' -Value $True -Option Constant

# Colors
#  Title color is for the menu title at the top of the screen
#  Header color is used for any menu items that start with a period.  They are not selectable.
#  Prompt color is the basic menu item prompt text color
#  Prompt fg and bg colors define the colors for the selected item.
New-Variable -Name 'TITLECOLOR' -Value white -Option Constant
New-Variable -Name 'HEADERCOLOR' -Value blue -Option Constant
New-Variable -Name 'PROMPTCOLOR' -Value cyan -Option Constant
New-Variable -Name 'PROMPTFGCOLOR' -Value black -Option Constant
New-Variable -Name 'PROMPTBGCOLOR' -Value cyan -Option Constant

# MenuItem class
#   $Prompt is the menu item text
#   $Value is the returned value when selected
#   $Help is the optional help text to display in the help area
Class MenuItem {
    [string] $Prompt = ""   # What is displayed on the screen
    [string] $Value = ""    # What is returned if this item is selected
    [string] $Key = ""      # Key to use as a short-cut instead of arrows and enter
    [string] $Help = ""     # Optional help text to display in the heip text area

    # MenuItem constructor
    MenuItem([string] $Prompt, [string] $Value, [string] $Key, [string] $Help) {
        $this.Prompt = $Prompt
        $this.Value = $Value
        $this.Key = $Key
        $this.Help = $Help
    }
}

# Menu class
#   This class contains an array of menu items for display
#   To put a blank separator in the menu, simply have blank "" string for the Prompt
#   To put a heading (non-selectable item) in the menu use a period as the first character.
Class Menu {
    [string] $Title = ""                            # Menu title displayed on the screen
    [System.Collections.ArrayList]$MenuItems = @()  # Array list of menu items

    # Constructor, sets the title
    Menu([string] $Title) {
        $this.Title = $Title
    }

    # Add item helper function
    AddMenuItem([string] $Prompt, [string] $Value, [string] $Key, [string] $Help) {
        $newMenuItem = [MenuItem]::new($Prompt, $Value, $Key, $Help)
        $this.MenuItems.Add($newMenuItem)
    }
}

# Check screen width and height
Function Test-Screen([Menu] $menu) {
    $widthNeeded = 0
    $heightNeeded = 0
    
    # Get the current sindow size
    [int]$width = $Host.UI.RawUI.WindowSize.Width
    [int]$height = $Host.UI.RawUI.WindowSize.Height

    # Calculate size needed.
    # Using the help area?
    if($HELPENABLED) {
        # width needed is help start plus help width plus buffer
        $widthNeeded = $HELPSTARTCOL + $HELPWIDTH + 2
    } else {
        # Get the width of the longest menu prompt, and count lines for height
        foreach($item in $menu) {
            if($item.Prompt.Length -gt $widthNeeded) {
                $widthNeeded = $item.Prompt.Length
            }
        }
    }

    # height is title line plus number of menu items plus cursor line
    $heightNeeded = $Menu.MenuItems.count + 2

    # test to make sure console is appropriately sized
    if(($width -lt $widthNeeded) -Or ($height -lt $heightNeeded)) {
        Write-Host "Current screen size is w: $width, h: $height.  You need to adjust to w: $widthNeeded, h: $heightNeeded"
        exit
    }
}


# Write out the help item.
# Clears the text area first, then word-wraps the help text into the defined area
Function Write-Help( $text)
{
    # Don't bother if not enabled
    if(-Not $HELPENABLED) {return}

    # Split text on white space
    $words = $text -split "\s+"
    $col = 0                    # Start at area's column 0
    $line = ""                  # Initial text is blank
    $curRow = $HELPSTARTROW     # Set starting row

    # First clear the help area
    $blanks = " " * $HELPWIDTH
    for($i = 0; $i -lt $HELPMAXROWS + 1; $i++) {
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $HELPSTARTCOL, ($curRow + $i)
        Write-Host $blanks
    }

    # Write out the help text
    foreach ( $word in $words )
    {
        $col += $word.Length + 2    # padding for words that start one char before the width
        # Check for wrap length, or last word in string
        if ( $col -ge $HELPWIDTH -Or $word -eq $words[-1])
        {
            # If last word, make sure to add it into the line
            if($word -eq $words[-1]) { $line += "$word "}

            # Set the cursor and write the text
            #$curPos = $Host.UI.RawUI.CursorPosition 
            $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $HELPSTARTCOL, $curRow
            Write-Host -NoNewLine "$line" -ForegroundColor $HELPCOLOR
    
            # Move to the next line, and start the next line text with any spill from the line printed
            $curRow++
            $col = 0
            $line = "$word "
        } else {
            # Add the word to the current line with a space.
            $line += "$word "
        }
    }
}

# Display the menu and process user input
Function New-Menu () {
    Param(
        [Parameter(Mandatory=$True)][Menu]$Menu
    )

    # Variable initialization
    $MaxValue = $Menu.MenuItems.count-1
    $Selection = -1                 # We will pre-increment this so it will start at zero
    $PreviousSelection = -1         # Save previous, as above will get set appropriately after menu draws the first time
    $EnterPressed = $False
    
    # Initially clear the screen.
    # Cursor movement will only modify the current and previous selections
    # This eliminates the screen flicker of drawing the entire screen for each cursor move
    Clear-Host

    # Find and set the first selectable menu item
    do {
        $Selection += 1
        $item = $Menu.MenuItems[$Selection]
    } while ($item.Prompt -eq "" -Or $item.Prompt.StartsWith("."))

    # No previous selection to start with
    $PreviousSelection = $Selection

    # If we allow key entry create a hashtable of keys and values
    $keysHash = @{}

    if($ALLOWKEYS) {
        # go through the menu items and add the key / values to the hashtable
        foreach($item in $Menu.MenuItems) {
            $keysHash[$item.Key] = $item.Value
        }
    }
    
    # Draw menu title
    Write-Host "$($Menu.Title)" -ForegroundColor $TITLECOLOR

    # Draw each menu item
    For ($i=0; $i -le $MaxValue; $i++){
        $item = $Menu.MenuItems[$i]
        $prompt = $item.Prompt
        $key = ""

        # Add key value to the menu if allowed
        if ($ALLOWKEYS) {$key = "[$($item.Key)]"}

        # If the prompt is blank, blank the key as well
        if ($prompt -eq "") {$key = ""}
        if ($i -eq $Selection){
            # Highlight initial selectable item
            Write-Host -BackgroundColor $PROMPTBGCOLOR -ForegroundColor $PROMPTFGCOLOR " $key $prompt "
        } Else {
            # If the string starts with a period, remove it and render with the header color
            if($prompt.StartsWith(".")) {
                Write-Host $prompt.substring(1) -ForegroundColor $HEADERCOLOR
            } else {
                # Output the normal menu item
                Write-Host " $key $prompt " -ForegroundColor $PROMPTCOLOR
            }
        }
    }

    # Save the cursor position at the end of the menu
    # so we can return it after updating the screen.
    $cursorPos = $Host.UI.RawUI.CursorPosition 

    # Assume cursor moved to print the initial help
    $cursorMoved = $True

    # Process the menu
    While($EnterPressed -eq $False) {
        $row = 0
        For ($i=0; $i -le $MaxValue; $i++){
            $row += 1
            $item = $Menu.MenuItems[$i]
            $key = ""

            # Add key value to menu if allowed
            if ($ALLOWKEYS) {$key = "[$($item.Key)]"}

            $prompt = $item.Prompt
            If ($i -eq $Selection){
                # Highlight the current selection
                $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0, $row
                Write-Host -BackgroundColor $PROMPTBGCOLOR -ForegroundColor $PROMPTFGCOLOR " $key $prompt "
            } Else {
                if($i -eq $PreviousSelection) {
                    # Remove hightlight from the previous selection
                    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0, $row
                    Write-Host " $key $prompt " -ForegroundColor $PROMPTCOLOR
                }
            }
        }

        # Write help if enabled
        $item = $Menu.MenuItems[$Selection]
        if($cursorMoved) { Write-Help $item.Help }

        # Reset the cursor
        $Host.UI.RawUI.CursorPosition = $cursorPos
    
        $RawKey = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
        $KeyInput = $RawKey.virtualkeycode
        $KeyCode = $RawKey.Character

        Switch($KeyInput){
            13{     # enter
                $EnterPressed = $True
                Return $item.Value
                break
            }
            38{     # up arrow
                $cursorMoved = $True
                $PreviousSelection = $Selection
                do {
                    If ($Selection -eq 0){
                        $Selection = $MaxValue
                    } Else {
                        $Selection -= 1
                    }
                    $item = $Menu.MenuItems[$Selection]
                } while ($item.Prompt -eq "" -Or $item.Prompt.StartsWith("."))
                break
            }
            40{     # down arrow
                $cursorMoved = $True
                $PreviousSelection = $Selection
                do {
                    If ($Selection -eq $MaxValue){
                        $Selection = 0
                    } Else {
                        $Selection +=1
                    }
                    $item = $Menu.MenuItems[$Selection]
                } while ($item.Prompt -eq "" -Or $item.Prompt.StartsWith("."))
                break
            }
            Default{
                $cursorMoved = $False

                # If we allow keys
                if ($ALLOWKEYS) {
                    # See if the key is in the hashtable and return the value if found
                    foreach($key in $keysHash.keys) {
                        if($key -eq $KeyCode) {
                            $ret = $keysHash[$key]
                            Return $ret
                        }
                    }
                }
            }
        }
    }
}

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

Test-Screen $Menu

# In the real world the return value would be your validated value to use in a switch
# or other method for executing the selected item's function.
$val = New-Menu $Menu
Clear-Host
Write-Host $val
