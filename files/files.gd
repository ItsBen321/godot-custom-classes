@abstract
##Custom file system. Create a [FileManager] Resource with [FilePreset]s.
##
##@tutorial(Short overview): https://youtu.be/rRb1tghKKHY

extends Resource

class_name Files

##Session status of a file.
enum SESSION {
	OPEN,
	CLOSED,
	LOCKED,
	ERROR
}

##Response with extra info about the File handling.
enum RESPONSE {
	OK,
	PRESET_NOT_FOUND,
	VAR_NOT_FOUND,
	ORIGIN_NOT_FOUND,
	PRESET_INVALID,
	SESSION_ALREADY_OPEN,
	SESSION_ALREADY_CLOSED,
	SESSION_ALREADY_LOCKED,
	SAVE_FAILED,
	LOAD_FAILED
}
