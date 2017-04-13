module ActionView::Helpers
  module ChartrHelpers
    # easy way to include Chartr assets
    def chartr_includes
      return "<!--[if IE]>\n" +
        javascript_include_tag('chartr/excanvas.js', 'chartr/base64.js') +
        "\n<![endif]-->" +
        javascript_include_tag("chartr/canvas2image.js", "chartr/canvastext.js", "chartr/flotr-min")
    end
  end
end
