module utilities

pub struct HookManager {
mut:
	hooks map[string]map[string]fn (voidptr)
}

// Adds a hook to be called upon an event occuring.
// ! Be careful to not have overlapping identfiers or inexistent events as those won't be called. !
[inline]
pub fn (mut self HookManager) add_hook(event string, identifier string, function fn (voidptr)) {
	self.hooks[event][identifier] = function
}

[inline]
pub fn (mut self HookManager) remove_hook(event string, identifier string) {
	self.hooks[event].delete(identifier)
}

[inline]
pub fn (mut self HookManager) call_all_hooks(identifier string, args voidptr) {
	for _, function in self.hooks[identifier] {
		function(args)
	}
}
