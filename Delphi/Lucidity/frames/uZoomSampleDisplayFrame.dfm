object ZoomSampleDisplayFrame: TZoomSampleDisplayFrame
  Left = 0
  Top = 0
  Width = 875
  Height = 240
  TabOrder = 0
  object Panel: TRedFoxContainer
    Left = 0
    Top = 0
    Width = 875
    Height = 240
    Color = '$FFEEEEEE'
    Align = alClient
    object BackgroundPanel: TVamPanel
      Left = 0
      Top = 0
      Width = 875
      Height = 240
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
      object SampleDisplayContainer: TVamPanel
        AlignWithMargins = True
        Left = 6
        Top = 6
        Width = 863
        Height = 228
        Opacity = 255
        HitTest = True
        Color = '$FFCCCCCC'
        Transparent = False
        Align = alClient
        Visible = True
        OnResize = SampleDisplayContainerResize
        object SampleDisplay: TVamSampleDisplay
          AlignWithMargins = True
          Left = 32
          Top = 28
          Width = 281
          Height = 85
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Opacity = 255
          HitTest = True
          LineColor = '$FFFF0000'
          Visible = True
        end
      end
    end
  end
end
