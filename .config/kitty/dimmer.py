from kittens.tui.loop import debug

from typing import Any, Dict, List

from kitty.boss import Boss
from kitty.keys import get_options
from kitty.window import Window, Color, DynamicColor

def on_focus_change(boss: Boss, window: Window, data: Dict[str, Any]) -> None:
    if data["focused"]:
        color = get_options().background.as_sgr
        window.set_dynamic_color(11, color) # 11 is the code for bg, see DYNAMIC_COLORS
    else:
        color = alpha_blend(0.95, get_options().foreground, get_options().background)
        window.set_dynamic_color(11, color) # 11 is the code for bg, see DYNAMIC_COLORS

def alpha_blend(a: float, fg: Color, bg: Color) -> str:
    return '#%02x%02x%02x' % (
        int((1-a) * fg.red + a * bg.red),
        int((1-a) * fg.green + a * bg.green),
        int((1-a) * fg.blue + a * bg.blue),
    )
