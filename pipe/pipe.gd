## A tiny function pipeline helper.
##
## Inspired by the piping operator in Elixir, this class can process a variable by going through multiple functions from any sources.
## It should help with readability, segmentation and reusability of your code.[br][br]
## Pipe can [method Pipe.build] (or when creating using [code]Pine.new(args)[/code]) a reusable list of Callables and [method Pipe.exec] it on any value,
## or you can use the static [method Pipe.run] for one-off pipelines.[br]
## [br]
## - Callables that take 0 arguments are treated as side-effects.[br]
## - Callables that take 1+ arguments receive the current value.[br]
## - If a callable returns null, the value is left unchanged.[br]
## [br]
## Example (mix of transforms, side-effects, and reusable pipelines):
## [codeblock]
## func add_one(x: int) -> int:
## 	return x + 1
##
## func clamp_0_10(x: int) -> int:
## 	return clamp(x, 0, 10)
##
## func log_time() -> void:
## 	print(Time.get_datetime_string_from_system())
##
## # One-off usage:
## var result: int = Pipe.run(5,
## 	add_one,
## 	log_time,
## 	func(x: int) -> int: return x * 3,
## 	Callable(self, "clamp_0_10")
## )
##
## # Reusable pipeline:
## var pipe := Pipe.new(
## 	add_one,
## 	clamp_0_10
## )
## var a: int = pipe.exec(2)  # -> 3
## var b: int = pipe.exec(99) # -> 10
## [/codeblock]

extends Object

class_name Pipe

var _pipeline: Array[Callable]

static func run(variant, ...callables) -> Variant: 
	for callable in callables: 
		if callable is not Callable:
			push_warning(str(callable), " is not a Callable.")
			return variant
	for callable: Callable in callables:
		if callable.get_argument_count() == 0:
			callable.call()
		else:
			var return_variant = callable.call(variant)
			if return_variant != null:
				variant = return_variant
	return variant
	
func _init(...callables) -> void:
	callv("build", callables) 
  
func build(...callables) -> void:
	if _pipeline: _pipeline.clear() 
	for callable in callables: 
		if callable is not Callable:
			push_warning(str(callable), " is not a Callable.")
			return
	for callable: Callable in callables:
		_pipeline.append(callable)
  	
func exec(variant) -> Variant: 
	return callv("run", [variant] + _pipeline) 
