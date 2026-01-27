## Adds a bit more functionality to the built-in Timers.
## 
## You can now call [member BetterTimer.time_elapsed] as a read-only variable.[br]
## [br]
## Setting [member BetterTimer.update_wait_time] is similar to setting the [member BetterTimer.wait_time], 
## but works while a timer is actively running without interrupting the process.
## It will stop/restart the timer and update the [member BetterTimer.wait_time] after the [member BetterTimer.update_wait_time] has elapsed.[br]
## [br]
## You can add any objects of class [Range], usually a [ProgressBar] or [TextureProgressBar], to this timer by adding it to
## [member BetterTimer.connected_progress_bars] or calling [method BetterTimer.add_progress_bar].
## This will automatically sync up the [member BetterTimer.update_wait_time] with the [member Range.max_value] and
## the [member BetterTimer.time_elapsed] with the [member Range.value].

extends Timer

class_name BetterTimer

## Connect any objects of class [Range] to automatically update their [member Range.max_value] and [member Range.value] in
## sync with the [BetterTimer].
@export var connected_progress_bars: Array[Range]

## The time that has currently elapsed. [code](this is the same as calling wait_time - time_left)[/code].
## This is a read-only variable.
var time_elapsed: float = 0.0:
	set(value): pass
	get: return wait_time-time_left
	
## Setting [member BetterTimer.update_wait_time] is similar to setting the [member BetterTimer.wait_time], 
## but works while a timer is actively running without interrupting the process.
## It will stop/restart the timer and update the [member BetterTimer.wait_time] after the [member BetterTimer.update_wait_time] has elapsed.[br]
var update_wait_time: float = 0.0:
	get:
		if update_wait_time == 0.0: return wait_time
		else: return update_wait_time

func _physics_process(_delta: float) -> void:
	if process_callback != TimerProcessCallback.TIMER_PROCESS_PHYSICS: return
	if paused: return
	_update_end_timer()
	_update_ranges()
	
func _process(_delta: float) -> void:
	if process_callback != TimerProcessCallback.TIMER_PROCESS_IDLE: return
	if paused: return
	_update_end_timer()
	_update_ranges()

func _update_end_timer():
	if update_wait_time == wait_time: return
	if time_elapsed >= update_wait_time:
		timeout.emit()
		wait_time = update_wait_time
		update_wait_time = 0.0
		if !one_shot: start()
		else: stop()
		
func _update_ranges():
	for bar in connected_progress_bars:
		if !is_instance_valid(bar): return
		if bar.max_value != update_wait_time: bar.max_value = update_wait_time
		if bar.value != time_elapsed: bar.value = time_elapsed
		
## Connectes an object of class [Range] to the [BetterTimer].
func add_progress_bar(progress_bar: Range):
	connected_progress_bars.append(progress_bar)
	
## Removes an object of class [Range] to the [BetterTimer].
func remove_progress_bar(progress_bar: Range):
	connected_progress_bars.erase(progress_bar)
