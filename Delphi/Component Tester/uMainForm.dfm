object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 536
  ClientWidth = 1005
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 25
    Top = 463
    Width = 139
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
  end
  object RedFoxContainer1: TRedFoxContainer
    Left = 25
    Top = 8
    Width = 849
    Height = 425
    Color = '$FFCCCCCC'
    object VamTreeView1: TVamTreeView
      Left = 88
      Top = 120
      Width = 185
      Height = 121
      Opacity = 255
      Text = 'VamTreeView1'
      HitTest = True
      SelectedNodeColor = clBlack
      SelectedNodeAlpha = 35
      ChildIndent = 12
      DefaultNodeHeight = 16
      Options = []
      RootIndent = 4
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Visible = True
    end
    object VamTextBox1: TVamTextBox
      Left = 312
      Top = 128
      Width = 265
      Height = 185
      Opacity = 255
      HitTest = True
      Color = '$FF3E3E3E'
      ColorMouseOver = '$FF3E3E3E'
      ColorBorder = '$00000000'
      ShowBorder = False
      TextAlign = AlignNear
      TextVAlign = AlignNear
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Visible = True
    end
    object VamTabPanel1: TVamTabPanel
      Left = 640
      Top = 184
      Width = 129
      Height = 89
      Opacity = 255
      Text = 'VamTabPanel1'
      HitTest = True
      Color_Background = '$ff777776'
      Color_TabOff = '$ffC0C0C0'
      Color_TabOn = '$ffD3D3D3'
      TabHeight = 24
      TabOffset = 8
      TabPadding = 16
      TabSpace = 8
      TabPosition = tpAboveLeft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      TabIndex = -1
      Visible = True
    end
    object VamTabs1: TVamTabs
      Left = 608
      Top = 80
      Width = 113
      Height = 57
      Opacity = 255
      Text = 'VamTabs1'
      HitTest = True
      TabIndex = -1
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Visible = True
    end
    object VamShortMessageOverlay1: TVamShortMessageOverlay
      Left = 112
      Top = 56
      Width = 217
      Height = 49
      Opacity = 255
      HitTest = True
      AutoSizeBackground = True
      Color = '$FFFFFFFF'
      ColorBorder = '$FF000000'
      ColorText = '$FF000000'
      BorderWidth = 0
      ShowBorder = False
      CornerRadius1 = 3.000000000000000000
      CornerRadius2 = 3.000000000000000000
      CornerRadius3 = 3.000000000000000000
      CornerRadius4 = 3.000000000000000000
      TextAlign = AlignCenter
      TextVAlign = AlignCenter
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Visible = True
    end
    object VamScrollBox1: TVamScrollBox
      Left = 56
      Top = 256
      Width = 161
      Height = 121
      Opacity = 255
      Text = 'VamScrollBox1'
      HitTest = True
      Color_Border = '$FF000000'
      Color_Background = '$FF888888'
      Color_Foreground = '$FFCCCCCC'
      ScrollBars = ssBoth
      ScrollBarWidth = 16
      ScrollXIndexSize = 0.250000000000000000
      ScrollYIndexSize = 0.250000000000000000
      Visible = True
    end
    object VamScrollBar1: TVamScrollBar
      Left = 64
      Top = 64
      Width = 177
      Height = 89
      Opacity = 255
      Text = 'VamScrollBar1'
      HitTest = True
      IndexSize = 0.250000000000000000
      Color_Border = '$FF000000'
      Color_Background = '$FF888888'
      Color_Foreground = '$FFCCCCCC'
      SliderStyle = SquareCorners
      SliderType = stVertical
      Visible = True
    end
    object VamPanel1: TVamPanel
      Left = 480
      Top = 56
      Width = 113
      Height = 97
      Opacity = 255
      Text = 'VamPanel1'
      HitTest = True
      Color = '$FFCCCCCC'
      Transparent = False
      Visible = True
    end
    object VamMultiLineTextBox1: TVamMultiLineTextBox
      Left = 352
      Top = 56
      Width = 153
      Height = 121
      Opacity = 255
      HitTest = True
      Color = '$FF000000'
      TextAlign = AlignNear
      TextVAlign = AlignNear
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Visible = True
    end
    object VamMemo1: TVamMemo
      Left = 528
      Top = 48
      Width = 121
      Height = 137
      Opacity = 255
      HitTest = True
      Color = '$FF000000'
      ColorMouseOver = '$FF000000'
      TextAlign = AlignNear
      TextVAlign = AlignNear
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Visible = True
    end
    object VamDiv1: TVamDiv
      Left = 544
      Top = 80
      Width = 201
      Height = 217
      Opacity = 255
      Text = 'VamDiv1'
      HitTest = True
      Visible = True
    end
    object VamButton1: TVamButton
      Left = 568
      Top = 32
      Width = 185
      Height = 105
      Opacity = 255
      HitTest = True
      ShowBorder = False
      Color_Border = '$FF242B39'
      ColorOnA = '$FF96F9D3'
      ColorOnB = '$FF59F9BC'
      ColorOffA = '$FFF99595'
      ColorOffB = '$FFF96969'
      ButtonState = bsOff
      TextAlign = AlignNear
      TextVAlign = AlignNear
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Visible = True
    end
    object VamImage1: TVamImage
      Left = 624
      Top = 152
      Width = 193
      Height = 145
      Opacity = 255
      Text = 'VamImage1'
      HitTest = True
      Visible = True
    end
    object VamLabel1: TVamLabel
      Left = 544
      Top = 192
      Width = 241
      Height = 177
      Opacity = 255
      HitTest = True
      AutoSize = False
      TextAlign = AlignCenter
      TextVAlign = AlignCenter
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Visible = True
    end
    object VamMemo2: TVamMemo
      Left = 304
      Top = 240
      Width = 185
      Height = 161
      Opacity = 255
      HitTest = True
      Color = '$FF000000'
      ColorMouseOver = '$FF000000'
      TextAlign = AlignNear
      TextVAlign = AlignNear
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Visible = True
    end
  end
  object Button2: TButton
    Left = 23
    Top = 503
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 3
  end
  object Button3: TButton
    Left = 104
    Top = 503
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 4
  end
  object Button4: TButton
    Left = 185
    Top = 503
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 5
  end
  object Button5: TButton
    Left = 185
    Top = 463
    Width = 139
    Height = 25
    Caption = 'Button1'
    TabOrder = 6
  end
  object Memo1: TMemo
    Left = 592
    Top = 463
    Width = 353
    Height = 265
    Lines.Strings = (
      'Memo1')
    TabOrder = 1
  end
end
