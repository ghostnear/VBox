module core

import sdl
import term
import locale
import utilities as utils

[heap]
struct Graphics {
pub mut:
	parent       &App = unsafe { nil }
	display_mode DisplayMode
	sdl_window   &sdl.Window   = sdl.null
	sdl_renderer &sdl.Renderer = sdl.null
}

fn (self Graphics) destroy() ?bool {
	// Do different stuff depending on the display driver.
	match self.display_mode {
		.terminal {
			// Clear the terminal.
			term.clear()
		}
		.sdl {
			// Quit all SDL related stuff.
			if self.sdl_renderer != sdl.null {
				sdl.destroy_renderer(self.sdl_renderer)
			}
			if self.sdl_window != sdl.null {
				sdl.destroy_window(self.sdl_window)
			}
		}
		// This shouldn't happen.			
		else {
			return error(locale.get_string(self.parent.locale, 'message_unknown_graphics_selected'))
		}
	}

	return true
}

// Create a graphics instance using the specified configuration.
fn new_gfx(cfg GraphicsConfig, parent &App) ?&Graphics {
	mut gfx := &Graphics{
		parent: parent
		display_mode: cfg.display_mode
	}

	// Do different stuff depending on the display driver.
	match cfg.display_mode {
		.terminal {
			// Set up terminal
			term.clear()
			term.set_terminal_title(cfg.window_title)
		}
		.sdl {
			// Init everything SDL related.
			sdl.init(sdl.init_everything)

			// Create window
			gfx.sdl_window = sdl.create_window(cfg.window_title.str, sdl.windowpos_centered,
				sdl.windowpos_centered, cfg.width, cfg.height, 0)
			if gfx.sdl_window == sdl.null {
				return error(
					locale.get_string(parent.locale, 'message_sdl_could_not_create_window') + ' ' +
					utils.get_sdl_error())
			}

			// Create renderer
			gfx.sdl_renderer = sdl.create_renderer(gfx.sdl_window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync) | u32(sdl.RendererFlags.targettexture))
			if gfx.sdl_renderer == sdl.null {
				return error(
					locale.get_string(parent.locale, 'message_sdl_could_not_create_renderer') +
					' ' + utils.get_sdl_error())
			}
		}
		else {
			return error(locale.get_string(parent.locale, 'message_unknown_graphics_selected'))
		}
	}

	return gfx
}
