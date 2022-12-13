module app

import sdl
import locale

pub enum DisplayMode
{
	other
	terminal
	sdl
}

pub struct GraphicsConfig
{
pub mut:
	width			int	= 960
	height			int = 540
	window_title	string = "VBox"
	display_mode 	DisplayMode = .other
}

struct Graphics
{
mut:
	display_mode 	DisplayMode
	sdl_window 		&sdl.Window = sdl.null
	sdl_renderer	&sdl.Renderer = sdl.null
}

fn (self &Graphics) destroy()
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

fn new_gfx(cfg GraphicsConfig) ?&Graphics
{
	// Init the graphics with the settings from the config.
	mut gfx := &Graphics {
		display_mode: cfg.display_mode
	}

	// Do different stuff depending on the display driver.
	match cfg.display_mode
	{
		.terminal
		{
			// Do nothing about it for now...
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
				return error(locale.message_sdl_could_not_create_window)
			}

			// Create renderer
			gfx.sdl_renderer = sdl.create_renderer(
				gfx.sdl_window,
				-1,
				u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync)
			)
			if gfx.sdl_renderer == sdl.null
			{
				return error(locale.message_sdl_could_not_create_renderer)
			}
		}

		else
		{
			return error(locale.message_unknown_graphics_selected)
		}
	}

	return gfx
}