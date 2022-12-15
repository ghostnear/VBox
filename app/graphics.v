module app

import sdl
import term
import locale

pub enum DisplayMode
{
	other
	terminal
	sdl
}

pub fn (self DisplayMode) str() string
{
	match self
	{
		.other { return "?" }
		.terminal { return "terminal" }
		.sdl { return "sdl"}
	}
}

pub struct GraphicsConfig
{
pub mut:
	width			int	= 960
	height			int = 540
	window_title	string = "VBox"
	display_mode 	DisplayMode = .other
}

[heap]
struct Graphics
{
mut:
	parent			&App = unsafe { nil }
	display_mode 	DisplayMode
	sdl_window 		&sdl.Window = sdl.null
	sdl_renderer	&sdl.Renderer = sdl.null
}

fn (self &Graphics) destroy() ?bool
{
	// Do different stuff depending on the display driver.
	match self.display_mode
	{
		.terminal
		{
			// Clear the terminal
			term.clear()
		}

		.sdl
		{
			// Quit all SDL related stuff.
			if self.sdl_renderer != sdl.null
			{
				sdl.destroy_renderer(self.sdl_renderer)
			}
			if self.sdl_window != sdl.null
			{
				sdl.destroy_window(self.sdl_window)
			}
			sdl.quit()
		}

		// This shouldn't happen.			
		else { return error(locale.get_string(self.parent.locale, "message_unknown_graphics_selected")) }
	}

	return true
}

fn new_gfx(cfg GraphicsConfig, parent &App) ?&Graphics
{
	// Init the graphics with the settings from the config.
	mut gfx := &Graphics {
		parent: parent
		display_mode: cfg.display_mode
	}

	// Do different stuff depending on the display driver.
	match cfg.display_mode
	{
		.terminal
		{
			// Set up terminal
			term.clear()
			term.set_terminal_title(cfg.window_title)
		}

		.sdl
		{
			// Init SDL stuff
			sdl.init(sdl.init_video)

			// Create window
			gfx.sdl_window = sdl.create_window(
				cfg.window_title.str,
				sdl.windowpos_centered, sdl.windowpos_centered,
				cfg.width, cfg.height,
				0
			)
			if gfx.sdl_window == sdl.null
			{
				return error(locale.get_string(parent.locale, "message_sdl_could_not_create_window"))
			}

			// Create renderer
			gfx.sdl_renderer = sdl.create_renderer(
				gfx.sdl_window,
				-1,
				u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync)
			)
			if gfx.sdl_renderer == sdl.null
			{
				return error(locale.get_string(parent.locale, "message_sdl_could_not_create_renderer"))
			}
		}
		else
		{
			return error(locale.get_string(parent.locale, "message_unknown_graphics_selected"))
		}
	}

	return gfx
}