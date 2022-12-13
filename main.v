import app

fn main()
{
	// Config for app info.
	mut config := app.AppConfig {}
	config.gfx_config.display_mode = .terminal

	// App instantiation
	mut app := app.new_app(config)
	app.start()
	app.quit()
}