object MiniSampleDisplayFrame: TMiniSampleDisplayFrame
  Left = 0
  Top = 0
  Width = 833
  Height = 366
  TabOrder = 0
  object Panel: TRedFoxContainer
    Left = 0
    Top = 0
    Width = 833
    Height = 366
    Color = '$FFEEEEEE'
    Align = alClient
    object BackgroundPanel: TVamPanel
      Left = 0
      Top = 0
      Width = 833
      Height = 366
      Opacity = 255
      HitTest = True
      Color = '$FFCCCCCC'
      Transparent = False
      Align = alClient
      Visible = True
      Padding.Left = 3
      Padding.Top = 3
      Padding.Right = 3
      Padding.Bottom = 3
      object InsidePanel: TVamPanel
        AlignWithMargins = True
        Left = 16
        Top = 16
        Width = 790
        Height = 251
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Opacity = 255
        HitTest = True
        Color = '$FF000000'
        CornerRadius1 = 3.000000000000000000
        CornerRadius2 = 3.000000000000000000
        Transparent = False
        Visible = True
        OnResize = InsidePanelResize
        Padding.Left = 8
        Padding.Top = 8
        Padding.Right = 8
        Padding.Bottom = 8
        object SampleDisplay: TVamSampleDisplay
          AlignWithMargins = True
          Left = 8
          Top = 8
          Width = 774
          Height = 188
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Opacity = 255
          HitTest = True
          LineColor = '$FF555555'
          Align = alClient
          Visible = True
          OnResize = SampleDisplayResize
          ExplicitLeft = 4
          ExplicitTop = 4
          ExplicitWidth = 782
          ExplicitHeight = 200
        end
        object SampleInfoBox: TVamDiv
          Left = 8
          Top = 196
          Width = 774
          Height = 47
          Opacity = 255
          HitTest = True
          Align = alBottom
          Visible = True
          ExplicitLeft = 4
          ExplicitTop = 204
          ExplicitWidth = 782
          object InfoDiv: TVamDiv
            AlignWithMargins = True
            Left = 0
            Top = 0
            Width = 774
            Height = 27
            Margins.Left = 0
            Margins.Top = 0
            Margins.Right = 0
            Margins.Bottom = 0
            Opacity = 255
            HitTest = True
            Align = alTop
            Visible = True
            OnResize = InfoDivResize
            ExplicitWidth = 782
            object SampleNameLabel: TVamLabel
              AlignWithMargins = True
              Left = 0
              Top = 0
              Width = 157
              Height = 27
              Margins.Left = 0
              Margins.Top = 0
              Margins.Right = 0
              Margins.Bottom = 0
              Opacity = 255
              Text = 'Awesome Sample.wav'
              HitTest = True
              AutoTrimText = True
              AutoSize = False
              TextAlign = AlignNear
              TextVAlign = AlignCenter
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWhite
              Font.Height = -11
              Font.Name = 'Tahoma'
              Font.Style = []
              Align = alLeft
              Visible = True
            end
            object SampleBeatsKnob: TVamCompoundNumericKnob
              Tag = 4
              Left = 706
              Top = 0
              Width = 68
              Height = 27
              Opacity = 255
              Text = 'Beats'
              HitTest = True
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Tahoma'
              Font.Style = []
              Color_Background = '$00000000'
              Color_Label = clSilver
              Color_Numeric = clWhite
              Color_Arrows1 = '$33FFFFFF'
              Color_Arrows2 = '$ccFFFFFF'
              KnobMin = 1
              KnobMax = 64
              KnobNumericStyle = nsInteger
              KnobDecimalPlaces = 2
              KnobSensitivity = 1.000000000000000000
              OnChanged = SampleKnobChanged
              Padding.Left = 3
              Padding.Top = 3
              Padding.Right = 3
              Padding.Bottom = 3
              Align = alRight
              Visible = True
              ExplicitLeft = 714
            end
            object SampleVolumeKnob: TVamCompoundNumericKnob
              Tag = 1
              AlignWithMargins = True
              Left = 370
              Top = 0
              Width = 78
              Height = 27
              Margins.Left = 0
              Margins.Top = 0
              Margins.Right = 10
              Margins.Bottom = 0
              Opacity = 255
              Text = 'Volume'
              HitTest = True
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Tahoma'
              Font.Style = []
              Units = ' dB'
              Color_Background = '$00000000'
              Color_Label = clSilver
              Color_Numeric = clWhite
              Color_Arrows1 = '$33FFFFFF'
              Color_Arrows2 = '$ccFFFFFF'
              KnobMin = -48
              KnobMax = 36
              KnobNumericStyle = nsInteger
              KnobDecimalPlaces = 2
              KnobSensitivity = 1.000000000000000000
              OnChanged = SampleKnobChanged
              Padding.Left = 3
              Padding.Top = 3
              Padding.Right = 3
              Padding.Bottom = 3
              Align = alRight
              Visible = True
              ExplicitLeft = 378
            end
            object SamplePanKnob: TVamCompoundNumericKnob
              Tag = 2
              AlignWithMargins = True
              Left = 458
              Top = 0
              Width = 62
              Height = 27
              Margins.Left = 0
              Margins.Top = 0
              Margins.Right = 10
              Margins.Bottom = 0
              Opacity = 255
              Text = 'Pan'
              HitTest = True
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Tahoma'
              Font.Style = []
              Units = '%'
              Color_Background = '$00000000'
              Color_Label = clLime
              Color_Numeric = clYellow
              Color_Arrows1 = '$33FFFFFF'
              Color_Arrows2 = '$ccFFFFFF'
              KnobMin = -100
              KnobMax = 100
              KnobNumericStyle = nsInteger
              KnobDecimalPlaces = 2
              KnobSensitivity = 1.000000000000000000
              OnChanged = SampleKnobChanged
              Padding.Left = 3
              Padding.Top = 3
              Padding.Right = 3
              Padding.Bottom = 3
              Align = alRight
              Visible = True
              ExplicitLeft = 466
            end
            object SampleFineKnob: TVamCompoundNumericKnob
              Tag = 6
              AlignWithMargins = True
              Left = 618
              Top = 0
              Width = 78
              Height = 27
              Margins.Left = 0
              Margins.Top = 0
              Margins.Right = 10
              Margins.Bottom = 0
              Opacity = 255
              Text = 'Fine'
              HitTest = True
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Tahoma'
              Font.Style = []
              Color_Background = '$00000000'
              Color_Label = clSilver
              Color_Numeric = clWhite
              Color_Arrows1 = '$33FFFFFF'
              Color_Arrows2 = '$ccFFFFFF'
              KnobMin = -100
              KnobMax = 100
              KnobNumericStyle = nsInteger
              KnobDecimalPlaces = 2
              KnobSensitivity = 1.000000000000000000
              OnChanged = SampleKnobChanged
              Padding.Left = 3
              Padding.Top = 3
              Padding.Right = 3
              Padding.Bottom = 3
              Align = alRight
              Visible = True
              ExplicitLeft = 626
            end
            object SampleTuneKnob: TVamCompoundNumericKnob
              Tag = 5
              AlignWithMargins = True
              Left = 530
              Top = 0
              Width = 78
              Height = 27
              Margins.Left = 0
              Margins.Top = 0
              Margins.Right = 10
              Margins.Bottom = 0
              Opacity = 255
              Text = 'Tune'
              HitTest = True
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Tahoma'
              Font.Style = []
              Units = ' st'
              Color_Background = '$00000000'
              Color_Label = clSilver
              Color_Numeric = clWhite
              Color_Arrows1 = '$33FFFFFF'
              Color_Arrows2 = '$ccFFFFFF'
              KnobMin = -48
              KnobMax = 48
              KnobNumericStyle = nsInteger
              KnobDecimalPlaces = 2
              KnobSensitivity = 1.000000000000000000
              OnChanged = SampleKnobChanged
              Padding.Left = 3
              Padding.Top = 3
              Padding.Right = 3
              Padding.Bottom = 3
              Align = alRight
              Visible = True
              ExplicitLeft = 538
            end
          end
        end
      end
      object ScrollBarDiv: TVamDiv
        Left = 20
        Top = 286
        Width = 782
        Height = 49
        Opacity = 255
        Text = 'ScrollBarDiv'
        HitTest = True
        Visible = True
        object ZoomScrollBar: TVamScrollBar
          Left = 35
          Top = 8
          Width = 616
          Height = 25
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Opacity = 255
          Text = 'ZoomScrollBar'
          HitTest = True
          IndexSize = 0.250000000000000000
          Color_Border = '$FF000000'
          Color_Background = '$FF888888'
          Color_Foreground = '$FFCCCCCC'
          SliderType = stHorizontal
          OnChanged = ZoomScrollBarChanged
          Visible = True
        end
        object ZoomInButton: TVamTextBox
          Tag = 1
          AlignWithMargins = True
          Left = 760
          Top = 0
          Width = 22
          Height = 49
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Opacity = 255
          Text = '+'
          HitTest = True
          AutoTrimText = False
          Color = '$FF3E3E3E'
          ColorMouseOver = '$FF3E3E3E'
          ColorBorder = '$00000000'
          ShowBorder = False
          TextAlign = AlignCenter
          TextVAlign = AlignCenter
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ImageOverlayVertAlign = AlignCenter
          ImageOverlayHorzAlign = AlignCenter
          ImageOverlayOffsetX = 0
          ImageOverlayOffsetY = 0
          Align = alRight
          Visible = True
        end
        object ZoomOutButton: TVamTextBox
          Tag = 2
          AlignWithMargins = True
          Left = 738
          Top = 0
          Width = 22
          Height = 49
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Opacity = 255
          Text = '-'
          HitTest = True
          AutoTrimText = False
          Color = '$FF3E3E3E'
          ColorMouseOver = '$FF3E3E3E'
          ColorBorder = '$00000000'
          ShowBorder = False
          TextAlign = AlignCenter
          TextVAlign = AlignCenter
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ImageOverlayVertAlign = AlignCenter
          ImageOverlayHorzAlign = AlignCenter
          ImageOverlayOffsetX = 0
          ImageOverlayOffsetY = 0
          Align = alRight
          Visible = True
        end
        object ZoomOutFullButton: TVamTextBox
          Tag = 3
          AlignWithMargins = True
          Left = 0
          Top = 0
          Width = 22
          Height = 49
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Opacity = 255
          Text = 'O'
          HitTest = True
          AutoTrimText = False
          Color = '$FF3E3E3E'
          ColorMouseOver = '$FF3E3E3E'
          ColorBorder = '$00000000'
          ShowBorder = False
          TextAlign = AlignCenter
          TextVAlign = AlignCenter
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ImageOverlayVertAlign = AlignCenter
          ImageOverlayHorzAlign = AlignCenter
          ImageOverlayOffsetX = 0
          ImageOverlayOffsetY = 0
          Align = alLeft
          Visible = True
        end
      end
    end
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 776
    Top = 24
  end
end
