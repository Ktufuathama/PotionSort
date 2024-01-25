using namespace System.Management.Automation.Host

class SerializedBufferCellArray
{
  <#
    Transforms the multidimensional buffer cell array to something that can be exported.
  #>
  
  [int]$Index = 0
  [buffercell[]]$Cells
  

  SerializedBufferCellArray() { }

  SerializedBufferCellArray([int]$index)
  {
    $this.Index = $index
  }

  SerializedBufferCellArray([int]$index, [buffercell[]]$bufferCellArray)
  {
    $this.Index = $index
    $this.Cells = $bufferCellArray
  }

  [void] SetCharacter([int]$row, [char]$char)
  {
    $cell = $this.Cells[$row]
    $cell.Character = $char
    $this.Cells[$row] = $cell
  }

  [void] SetForegroundColor([int]$row, [consolecolor]$color)
  {
    $cell = $this.Cells[$row]
    $cell.ForegroundColor = $color
    $this.Cells[$row] = $cell
  }

  [void] SetBackgroundColor([int]$row, [consolecolor]$color)
  {
    $cell = $this.Cells[$row]
    $cell.BackgroundColor = $color
    $this.Cells[$row] = $cell
  }
  
  [void] SetBufferCellType([int]$row, [consolecolor]$celltype)
  {
    $cell = $this.Cells[$row]
    $cell.BufferCellType = $celltype
    $this.Cells[$row] = $cell
  }

  [string] ToString()
  {
    return [string]($this.Cells.Character -join '')
  }
}

function ConvertTo-SerializedBufferCellArray {
  [cmdletbinding()]
  param(
    [object]$BufferCellArray
  )
  $BCA = $BufferCellArray
  for ($y = 0; $y -le $BCA.getUpperBound(0); $y++) {
    $SBCA = [serializedbuffercellarray]::new($y)
    for ($x = 0; $x -le $BCA.getUpperBound(1); $x++) {
      $SBCA.Cells += [system.management.automation.host.buffercell]($BCA[$y, $x])
    }
    [serializedbuffercellarray[]]$SBCAs += $SBCA
  }
  return $SBCAs
}

function ConvertFrom-SerializedBufferCellArray {
  [cmdletbinding()]
  param(
    [object[]]$SerializedBufferCellArray
  )
  $SBCA = $SerializedBufferCellArray
  $Coord = @{X=($SBCA[0].Cells.Count - 1); Y=($SBCA.Count - 1)}
  $BCA = [system.management.automation.host.buffercell[,]]::new(($Coord.Y + 1), ($Coord.X + 1))
  for ($y = 0; $y -le $Coord.Y; $y++) {
    for ($x = 0; $x -le $Coord.X; $x++) {
      if ($y -eq $Coord.Y) {
        $BCA[$y, $x] = [system.management.automation.host.buffercell]$SBCA[$y].Cells[$x]
      }
      else {
        $BCA[$y, $x] = [system.management.automation.host.buffercell]$SBCA[$y].Cells[$x]
      }
    }
  }
  return ,$BCA
}

function Import-SerializedBufferCellArray {
  [cmdletbinding()]
  param(
    [string]$Path,
    [switch]$ToBufferCellArray
  )
  $Xml = Get-Content -path $Path -raw -errorAction 'Stop'
  $SBCA = [system.management.automation.psserializer]::deserialize($Xml)
  if ($ToBufferCellArray) {
    $BCA = ConvertFrom-SerializedBufferCellArray -serializedBufferCellArray $SBCA
    return ,$BCA
  }
  return $SBCA
}

function Export-SerializedBufferCellArray {
  [cmdletbinding()]
  param(
      [parameter(mandatory, parametersetname='BCA')]
    [system.management.automation.host.buffercell[,]]$BufferCellArray,
      [parameter(mandatory, parametersetname='SBCA')]
    [serializedbuffercellarray]$SerializedBufferCellArray,
      [parameter(parametersetname='BCA')]
      [parameter(parametersetname='SBCA')]
    [string]$Path
  )
  if ($PSCmdlet.ParameterSetName -eq 'BCA') {
    $SerializedBufferCellArray = ConvertTo-SerializedBufferCellArray -bufferCellArray $BufferCellArray
  }
  $Xml = [system.management.automation.psserializer]::serialize($SerializedBufferCellArray, 3)
  Set-Content -value $Xml -path $Path -errorAction 'Stop'
}

class PotionGraphics
{
  [object]$EmptyVial
  [object]$SelectedVial
  [object]$CurrentVial
  [object]$HighlightedVial
  
  
  GraphicElements() { }

  [void] Import()
  {
    # Needs to be updated.
    $HardcodePath = "C:\_\Sandbox\PotionSort\"
    $this.EmptyVial = Import-SerializedBufferCellArray -Path "$($HardcodePath)_potion_empty.sbca.xml" -ToBufferCellArray
    $this.SelectedVial = Import-SerializedBufferCellArray -Path "$($HardcodePath)_potion_selected.sbca.xml" -ToBufferCellArray
    $this.CurrentVial = Import-SerializedBufferCellArray -Path "$($HardcodePath)_potion_current.sbca.xml" -ToBufferCellArray
    $this.HighlightedVial = Import-SerializedBufferCellArray -Path "$($HardcodePath)_potion_outline.sbca.xml" -ToBufferCellArray
  }
}

################################################################################
# Potions

class Coordinates
{
  # Actual buffer coord.
  [system.management.automation.host.coordinates]$Act
  # Relative coord to other objects.
  [system.management.automation.host.coordinates]$Rel


  Coordinates([int]$xAct, [int]$yAct, [int]$xRel, [int]$yRel)
  {
    $this.Act = [system.management.automation.host.coordinates]@{X=$xAct;Y=$yAct}
    $this.Rel = [system.management.automation.host.coordinates]@{X=$xRel;Y=$yRel}
  }

  Coordinates([hashtable]$act, [hashtable]$rel)
  {
    $this.Act = [system.management.automation.host.coordinates]$act
    $this.Rel = [system.management.automation.host.coordinates]$rel
  }
}

class Potion {
  [int]$Id
  [int]$Size = 4
  [int[]]$Contents
  [coordinates]$Coord
  [bool]$IsSelected = $false 


  Potion() { }

  [void] AddPotion([consolecolor]$color)
  {
    
  }

  [bool] IsFull()
  {
    return $this.Contents.Count -eq $this.Size
  }

  [bool] IsEmpty()
  {
    return $this.Contents.Count -eq 0
  }

  [void] Show()
  {
    $this.Contents.foreach({
      Write-Host "  " -BackgroundColor ($_ -as [consolecolor]) -NoNewLine
    })
  }
}

class PotionMgmt
{
  [potion[]]$Potions
  [potiongraphics]$Graphics
  [int]$Current
  [int]$Selected

  hidden [int]$Width = 5
  hidden [system.management.automation.host.coordinates]$InitCoord = @{X=10;Y=10}
  

  PotionMgmt()
  {
    $this.Graphics = [potiongraphics]::new()
    $this.Graphics.import()
  }

  <#
    [void] BuildShelf()
    {
      $this.Positions = $null
      $x = $this.P.X
      $y = $this.P.Y
      for ($i = 1; $i -le $this.Potions.Count; $i++) {
        $this.Positions += @{X=$x;Y=$y}
        if (($i % $this.Width) -eq 0) {
          $x = $this.P.X
          $y = $y + 5
        }
        else {
          $x = $x + 4
        }
      }
    }
  #>

  [void] NewPotion()
  {
    # Create new potion.
    $Potion = [potion]::new()
    if ($this.Potions.Count -eq 0) {
      $Potion.Id = 0
    }
    else {
      $Potion.Id = $this.Potions.Count + 1
    }
    $this.addPotion($potion)    
  }

  [void] AddPotion([potion]$newPotion)
  {
    $Potion = $newPotion
    if ($this.Potions.Count -eq 0) {
      $Potion.Coord = [coordinates]::new($this.InitCoord.X, $this.InitCoord.Y, 0, 0)
    }
    else {
      $P = $this.Potions[-1].Coord
      if (($this.Potions.Count % $this.Width) -eq 0) {
        $Potion.Coord = [coordinates]::new($this.InitCoord.X, $P.Act.Y + 5, $P.Rel.X + 1, 0)
      }
      else {
        $Potion.Coord = [coordinates]::new($P.Act.X + 4, $P.Act.Y, $P.Rel.X, $P.Rel.Y + 1)
      }
    }
    $this.Potions += $Potion
  }

  [void] RemovePotion([int]$potionId)
  {
    # Not implimented. Removing one potion would require the postions to be regenerated.
  }

  [void] DrawPotions()
  {
    $this.Potions.foreach({ $global:host.UI.RawUI.setBufferContents($_.Coord.Act, $this.Graphics.EmptyVial) })
  }
}

################################################################################
# Main

function Start-PotionSort {
  [cmdletbinding()]
  param()

  #$y = $host.UI.RawUI.CursorPosition.Y + 1
  #$x = $host.UI.RawUI.WindowSize.Width - 1

  # Create instance.
  $PotionMgmt = [PotionMgmt]::new()
  (0..8).foreach({
    $PotionMgmt.newPotion()
  })
  $PotionMgmt.drawPotions()

  # Set starting position
  $global:host.UI.RawUI.setBufferContents($PotionMgmt.Potions[0].Coord.Act, $PotionMgmt.Graphics.CurrentVial)
  $PotionMgmt.Current = 1
  $PotionMgmt.Potions[0].IsSelected = $true
  
  while ($true) {
    $k = [console]::readKey($true)
    switch -regex ($k.Key) {
      'W|UpArrow' {

      }
      'A|LeftArrow' {
        
      }
      'S|DownArrow' {
        
      }
      'D|RightArrow' {
        
      }
      'Spacebar|Enter' {
        
      }
      default {}
    }
    # Draw Potions
    # Read Input
    # Validate Changes
    # Edit Potions
    # Evaluate Win Conditions
  }
}


























class GraphicsTest
{
  [string]$HorizontalBoxDoubleChar  = [string][char]9552
  [string]$VerticalBoxDoubleChar    = [string][char]9553
  [string]$TopLeftBoxDoubleChar     = [string][char]9556
  [string]$TopRightBoxDoubleChar    = [string][char]9559
  [string]$BottomLeftBoxDoubleChar  = [string][char]9562
  [string]$BottomRightBoxDoubleChar = [string][char]9565

  [string]$HorizontalBoxSingleChar  = [string][char]9472
  [string]$VerticalBoxSingleChar    = [string][char]9474
  [string]$TopLeftBoxSingleChar     = [string][char]9484
  [string]$TopRightBoxSingleChar    = [string][char]9488
  [string]$BottomLeftBoxSingleChar  = [string][char]9492
  [string]$BottomRightBoxSingleChar = [string][char]9496

  [string]$HorizontalDottedChar     = [string][char]9476
  [string]$VerticalDottedChar       = [string][char]9478
  [string]$HorizontalDottedChar2    = [string][char]9480
  [string]$VerticalDottedChar2      = [string][char]9482

  GraphicsTest() { }
}
