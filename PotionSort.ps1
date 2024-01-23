using namespace System.Management.Automation.Host

class SerializedBufferCellArray
{
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

################################################################################
# Potions

class Potion {
  #[serializedbuffercellarray[]]$SBCA
  [int]$Id
  [int]$Size = 4
  [int[]]$Contents
  [hashtable]$Coord = @{X=0;Y=0;R=0}
  [bool]$IsSelected = $false
  

  Potion() { }
  
  <#
  PotionVial([serializedbuffercellarray[]]$sbca)
  {
    $this.SBCA = $sbca
  }
  #>

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

  <#
  [consolecolor[]] GetContents()
  {
    $c = @()
    for ($i = 0; $i -lt $this.SBCA.Length - 1; $i++) {
      $c += $this.SBCA[$i].Cells[1].BackgroundColor.where({$_ -ne [consolecolor]::Black})
    }
    return $c
  }
  #>

  [void] Show()
  {
    $this.Contents.foreach({
      Write-Host "  " -BackgroundColor ($_ -as [consolecolor])
    })
  }
}


class PotionShelf
{
  [potion[]]$Potions
  [system.management.automation.host.coordinates[]]$Positions
  [int]$Width = 5
  [array]$Current = 0
  [array]$Selected

  hidden [hashtable]$P = @{X=10;Y=10}
  hidden [system.management.automation.host.buffercell[,]]$EmptyVial
  hidden [system.management.automation.host.buffercell[,]]$SelectedVial
  hidden [system.management.automation.host.buffercell[,]]$CurrentVial
  hidden [system.management.automation.host.buffercell[,]]$HighlightedVial

  PotionShelf()
  {
    
  }

  [void] LoadGraphics()
  {
    $this.EmptyVial = Import-SerializedBufferCellArray -Path 'C:\_\Sandbox\PotionSort\_potion_empty.sbca.xml' -ToBufferCellArray
    $this.SelectedVial = Import-SerializedBufferCellArray -Path 'C:\_\Sandbox\PotionSort\_potion_selected.sbca.xml' -ToBufferCellArray
    $this.CurrentVial = Import-SerializedBufferCellArray -Path 'C:\_\Sandbox\PotionSort\_potion_current.sbca.xml' -ToBufferCellArray
    $this.HighlightedVial = Import-SerializedBufferCellArray -Path 'C:\_\Sandbox\PotionSort\_potion_outline.sbca.xml' -ToBufferCellArray
  }

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

  [void] NewPotion()
  {
    # Load potion SBCA.
    # Determine index and add.
  }

  [void] AddPotion()
  {
    $Potion = [potion]::new()
    $Potion.Id = $this.Potions.Count + 1

    if (($this.Potions.Count % $this.Width) -eq 0) {
      # Move to next row.
    }
  }

  [void] DrawPotions()
  {
    $this.Positions.foreach({ $global:host.UI.RawUI.setBufferContents($_, $this.EmptyVial) })
  }
}




class Coordinates
{
  [int]$X
  [int]$Y
  [int]$R
}

################################################################################
# Main

function Test-Potion {
  Clear-Host
  Write-Host "===== Potion Shelf ====="
  $BCA = Import-SerializedBufferCellArray -Path 'C:\_\Sandbox\PotionSort\_potion_empty.sbca.xml' -ToBufferCellArray
  (20,24,28,32,36).foreach({ $host.UI.RawUI.setBufferContents(@{x=$_; y=10}, $BCA) })
  (20,24,28,32,36).foreach({ $host.UI.RawUI.setBufferContents(@{x=$_; y=16}, $BCA) })
}

function Start-PotionSort {
  [cmdletbinding()]
  param()

  $y = $host.UI.RawUI.CursorPosition.Y + 1
  $x = $host.UI.RawUI.WindowSize.Width - 1
  $c = @{X=$x; Y=$y}

  # Create instance.
  $PotionVial = [potionvial]::new()
  $PotionShelf = [potionshelf]::new()
  $PotionShelf.loadGraphics()
  (0..8).foreach({
    $PotionShelf.Potions += $PotionVial
  })
  $PotionShelf.buildShelf()
  Clear-Host
  $PotionShelf.drawPotions()

  # Set starting position
  $global:host.UI.RawUI.setBufferContents($PotionShelf.Positions[0], $PotionShelf.CurrentVial)
  $PotionShelf.Potions[0].IsSelected = $true
  
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


# Placeholder ?
class GraphicElements
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
  
  GraphicElements()
  {
    
  }
}
