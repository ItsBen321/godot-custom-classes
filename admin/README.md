# Admin

Create a new script that extends *Admin*, then add it as an autoload. This will automatically
instantiate and set up your admin window when running in the editor.
Connect to the *admin_message* signal to wire any logs and text into the display window.
This class is meant to be changed for every project. Write custom functions
in your *Admin* autoload to create buttons.
There is no need to interact with the admin-window.tscn scene.
It is recommended to turn off Project Settings > Display > Window > Embed Subwindows.
