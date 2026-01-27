extends Object

class_name Spool

var max_threads: int
var open_threads: Array[Thread] = []
var tree: SceneTree = Engine.get_main_loop()


func _init(_max_threads: int = OS.get_processor_count() / 2) -> void:
	max_threads = _max_threads
	for n in max_threads:
		open_threads.append(Thread.new())


func single(callable: Callable, ...args) -> Variant:
	while open_threads.is_empty():
		await tree.process_frame
	var thread: Thread = open_threads.pop_back()
	if args.is_empty(): thread.start(callable)
	else: thread.start(callable.bind(args))
	while thread.is_alive():
		await tree.process_frame
	var value = thread.wait_to_finish()
	open_threads.append(thread)
	return value
	
	
func multiple(callable: Callable, amount: int, ...args) -> void:
	var active_threads: Array[Thread] = []
	for n in amount:
		while open_threads.is_empty():
			for active in active_threads:
				if !active.is_alive():
					active.wait_to_finish()
					active_threads.erase(active)
					open_threads.append(active)
			await tree.process_frame
		var thread: Thread = open_threads.pop_back()
		active_threads.append(thread)
		if args.is_empty(): thread.start(callable)
		else: thread.start(callable.bind(args))
	
	while !active_threads.is_empty():
		for active in active_threads:
			if !active.is_alive():
				active.wait_to_finish()
				active_threads.erase(active)
				open_threads.append(active)
		await tree.process_frame
	return
	
	
func link_single(callable: Callable, return_callable: Callable, ...args) -> void:
	while open_threads.is_empty():
		await tree.process_frame
	var thread: Thread = open_threads.pop_back()
	if args.is_empty(): thread.start(callable)
	else: thread.start(callable.bind(args))
	while thread.is_alive():
		await tree.process_frame
	return_callable.call(thread.wait_to_finish())
	open_threads.append(thread)
	return
	
	
func link_multiple(callable: Callable, return_callable: Callable, amount: int, ...args) -> void:
	var active_threads: Array[Thread] = []
	for n in amount:
		while open_threads.is_empty():
			for active in active_threads:
				if !active.is_alive():
					return_callable.call(active.wait_to_finish())
					active_threads.erase(active)
					open_threads.append(active)
			await tree.process_frame
		var thread: Thread = open_threads.pop_back()
		active_threads.append(thread)
		if args.is_empty(): thread.start(callable)
		else: thread.start(callable.bind(args))
	
	while !active_threads.is_empty():
		for active in active_threads:
			if !active.is_alive():
				return_callable.call(active.wait_to_finish())
				active_threads.erase(active)
				open_threads.append(active)
		await tree.process_frame
	return
