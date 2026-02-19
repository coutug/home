let
  colors = {
    bg = "#16181a";
    bg_highlight = "#3c4048";
    fg = "#ffffff";
    grey = "#7b8496";
    blue = "#5ea1ff";
    green = "#5eff6c";
    cyan = "#5ef1ff";
    red = "#ff6e5e";
    yellow = "#f1ff5e";
    pink = "#ff5ea0";
    orange = "#ffbd5e";
    purple = "#bd5eff";
  };
in
{
  k9s = {
    body = {
      fgColor = colors.fg;
      bgColor = "default";
      logoColor = colors.purple;
    };
    prompt = {
      fgColor = colors.fg;
      bgColor = "default";
      suggestColor = colors.blue;
    };
    help = {
      fgColor = colors.fg;
      bgColor = "default";
      sectionColor = colors.green;
      keyColor = colors.blue;
      numKeyColor = colors.red;
    };
    frame = {
      title = {
        fgColor = colors.cyan;
        bgColor = "default";
        highlightColor = colors.pink;
        counterColor = colors.yellow;
        filterColor = colors.green;
      };
      border = {
        fgColor = colors.purple;
        focusColor = colors.blue;
      };
      menu = {
        fgColor = colors.fg;
        keyColor = colors.blue;
        numKeyColor = colors.red;
      };
      crumbs = {
        fgColor = colors.bg;
        bgColor = "default";
        activeColor = colors.orange;
      };
      status = {
        newColor = colors.blue;
        modifyColor = colors.blue;
        addColor = colors.green;
        pendingColor = colors.orange;
        errorColor = colors.red;
        highlightColor = colors.cyan;
        killColor = colors.purple;
        completedColor = colors.grey;
      };
    };
    info = {
      fgColor = colors.orange;
      sectionColor = colors.fg;
    };
    views = {
      table = {
        fgColor = colors.fg;
        bgColor = "default";
        cursorFgColor = colors.bg;
        cursorBgColor = colors.bg_highlight;
        markColor = colors.pink;
        header = {
          fgColor = colors.grey;
          bgColor = "default";
          sorterColor = colors.cyan;
        };
      };
      xray = {
        fgColor = colors.fg;
        bgColor = "default";
        cursorColor = colors.bg_highlight;
        cursorTextColor = colors.bg;
        graphicColor = colors.pink;
      };
      charts = {
        bgColor = "default";
        chartBgColor = "default";
        dialBgColor = "default";
        defaultDialColors = [
          colors.green
          colors.red
        ];
        defaultChartColors = [
          colors.green
          colors.red
        ];
        resourceColors = {
          cpu = [
            colors.purple
            colors.blue
          ];
          mem = [
            colors.yellow
            colors.orange
          ];
        };
      };
      yaml = {
        keyColor = colors.blue;
        valueColor = colors.fg;
        colonColor = colors.grey;
      };
      logs = {
        fgColor = colors.fg;
        bgColor = "default";
        indicator = {
          fgColor = colors.blue;
          bgColor = "default";
          toggleOnColor = colors.green;
          toggleOffColor = colors.grey;
        };
      };
    };
    dialog = {
      fgColor = colors.yellow;
      bgColor = "default";
      buttonFgColor = colors.bg;
      buttonBgColor = "default";
      buttonFocusFgColor = colors.bg;
      buttonFocusBgColor = colors.pink;
      labelFgColor = colors.orange;
      fieldFgColor = colors.fg;
    };
  };
}
